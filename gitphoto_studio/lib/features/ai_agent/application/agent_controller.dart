import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/security/secret_redactor.dart';
import '../../dashboard/application/dashboard_stats.dart';
import '../../publishing/application/publish_controller.dart';
import '../data/conversation_repository.dart';
import '../domain/agent_plan.dart';
import '../domain/ai_provider.dart';
import 'agent_engine.dart';
import 'agent_environment.dart';
import 'agent_tools.dart';
import 'ai_settings.dart';
import 'plan_executor.dart';
import 'plan_validator.dart';

sealed class ChatEntry {
  const ChatEntry(this.id);

  final int id;
}

class UserEntry extends ChatEntry {
  const UserEntry(super.id, this.text);

  final String text;
}

class AssistantEntry extends ChatEntry {
  const AssistantEntry(super.id, this.text, {this.toolsUsed = const []});

  final String text;
  final List<String> toolsUsed;
}

enum PlanStatus {
  /// En attente de la décision de l'utilisateur.
  proposed,
  running,
  finished,
  rejected,

  /// Remplacé par une demande plus récente : ne peut plus être confirmé.
  expired,
}

class PlanEntry extends ChatEntry {
  const PlanEntry(
    super.id,
    this.plan,
    this.status, {
    this.report,
    this.progress,
  });

  final AgentPlan plan;
  final PlanStatus status;
  final PlanReport? report;
  final PlanProgress? progress;

  PlanEntry copyWith({
    PlanStatus? status,
    PlanReport? report,
    PlanProgress? Function()? progress,
  }) => PlanEntry(
    id,
    plan,
    status ?? this.status,
    report: report ?? this.report,
    progress: progress == null ? this.progress : progress(),
  );
}

/// Plan d'une conversation restaurée : affiché, jamais réexécutable.
class ArchivedPlanEntry extends ChatEntry {
  const ArchivedPlanEntry(super.id, this.summary);

  final String summary;
}

class ErrorEntry extends ChatEntry {
  const ErrorEntry(super.id, this.error);

  final Object error;
}

class PlanProgress {
  const PlanProgress(this.step, this.done, this.total, this.current);

  final int step;
  final int done;
  final int total;
  final String? current;
}

class AgentState {
  const AgentState({
    this.entries = const [],
    this.thinking = false,
    this.lastTool,
  });

  final List<ChatEntry> entries;

  /// Le modèle prépare une réponse.
  final bool thinking;

  /// Dernier outil de consultation appelé (affiché pendant la réflexion).
  final String? lastTool;

  bool get executing =>
      entries.any((e) => e is PlanEntry && e.status == PlanStatus.running);

  bool get busy => thinking || executing;

  AgentState copyWith({
    List<ChatEntry>? entries,
    bool? thinking,
    String? Function()? lastTool,
  }) => AgentState(
    entries: entries ?? this.entries,
    thinking: thinking ?? this.thinking,
    lastTool: lastTool == null ? this.lastTool : lastTool(),
  );
}

final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationRepository(ref.watch(appDatabaseProvider)),
);

class AgentController extends Notifier<AgentState> {
  final List<AiMessage> _history = [];
  int _nextId = 0;
  bool _cancel = false;
  int? _conversationId;

  /// Fait connu de l'application (plan exécuté ou refusé) transmis au
  /// modèle avec le prochain message.
  String? _pendingNote;

  @override
  AgentState build() {
    _history.clear();
    _pendingNote = null;
    _conversationId = null;
    return AgentState(entries: _restore());
  }

  /// Recharge la dernière conversation enregistrée (si autorisé).
  List<ChatEntry> _restore() {
    final prefs = ref.read(preferencesProvider);
    if (prefs.read(AiPreferenceKeys.saveConversations) != 'true') {
      return const [];
    }
    final latest = ref.read(conversationRepositoryProvider).latest();
    if (latest == null) return const [];
    _conversationId = latest.id;
    final entries = <ChatEntry>[];
    for (final l in latest.lines) {
      switch (l.role) {
        case 'user':
          entries.add(UserEntry(_nextId++, l.content));
          _history.add(AiMessage.user(l.content));
        case 'assistant':
          entries.add(AssistantEntry(_nextId++, l.content));
          _history.add(AiMessage.assistant(l.content));
        case 'plan':
          entries.add(ArchivedPlanEntry(_nextId++, l.content));
          _history.add(AiMessage.assistant('[Plan] ${l.content}'));
      }
    }
    return entries;
  }

  void _save(String role, String content) {
    final s = ref.read(aiSettingsProvider).value;
    if (s == null || !s.saveConversations) return;
    final repo = ref.read(conversationRepositoryProvider);
    _conversationId ??= repo.create(s.provider.name);
    repo.append(
      _conversationId!,
      StoredChatLine(role, SecretRedactor.redact(content)),
    );
  }

  void _add(ChatEntry e) =>
      state = state.copyWith(entries: [...state.entries, e]);

  void _replace(int id, ChatEntry Function(ChatEntry) update) {
    state = state.copyWith(
      entries: [for (final e in state.entries) e.id == id ? update(e) : e],
    );
  }

  /// Nouvelle conversation : l'historique transmis au modèle repart de zéro.
  void newConversation() {
    if (state.busy) return;
    _history.clear();
    _pendingNote = null;
    _conversationId = null;
    state = const AgentState();
  }

  void cancel() => _cancel = true;

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.busy) return;
    _cancel = false;
    // Une nouvelle demande rend caducs les plans non confirmés.
    state = state.copyWith(
      entries: [
        for (final e in state.entries)
          e is PlanEntry && e.status == PlanStatus.proposed
              ? e.copyWith(status: PlanStatus.expired)
              : e,
      ],
    );
    _add(UserEntry(_nextId++, trimmed));
    _save('user', trimmed);
    state = state.copyWith(thinking: true, lastTool: () => null);

    final note = _pendingNote;
    final userMsg = AiMessage.user(
      note == null ? trimmed : '[Note de l’application : $note]\n\n$trimmed',
    );
    try {
      final settings = await ref.read(aiSettingsProvider.future);
      if (!settings.isConfigured) {
        throw const AiException(AiErrorKind.notConfigured, 'IA non configurée');
      }
      final provider = await ref
          .read(aiSettingsProvider.notifier)
          .buildProvider();
      final env = ref.read(agentEnvironmentProvider);
      final engine = AgentEngine(
        provider: provider,
        model: settings.model!,
        toolbox: AgentToolbox(env),
        validator: PlanValidator(env),
        useTools: provider.capabilities.structuredToolCalls,
      );
      final reply = await engine.respond(
        [..._history, userMsg],
        onTool: (name) {
          if (ref.mounted) state = state.copyWith(lastTool: () => name);
        },
        isCancelled: () => _cancel,
      );
      if (!ref.mounted) return;
      _pendingNote = null;
      _history
        ..add(userMsg)
        ..addAll(reply.transcript);
      if (reply.plan case final plan?) {
        if (reply.text.isNotEmpty && reply.text != plan.summary) {
          _add(
            AssistantEntry(_nextId++, reply.text, toolsUsed: reply.toolsUsed),
          );
          _save('assistant', reply.text);
        }
        _add(PlanEntry(_nextId++, plan, PlanStatus.proposed));
        _save('plan', plan.summary);
      } else {
        final shown = reply.text.isEmpty ? '…' : reply.text;
        _add(AssistantEntry(_nextId++, shown, toolsUsed: reply.toolsUsed));
        _save('assistant', shown);
      }
    } on AgentCancelled {
      // Rien à ajouter : la demande est abandonnée.
    } on Object catch (e) {
      ref
          .read(loggerProvider)
          .warning('Agent IA : ${SecretRedactor.redact('$e')}');
      if (ref.mounted) _add(ErrorEntry(_nextId++, e));
    } finally {
      if (ref.mounted) {
        state = state.copyWith(thinking: false, lastTool: () => null);
      }
    }
  }

  PlanEntry? _plan(int id) =>
      switch (state.entries.where((e) => e.id == id).firstOrNull) {
        final PlanEntry p => p,
        _ => null,
      };

  void reject(int entryId) {
    final p = _plan(entryId);
    if (p == null || p.status != PlanStatus.proposed) return;
    _replace(entryId, (_) => p.copyWith(status: PlanStatus.rejected));
    _pendingNote = 'l’utilisateur a refusé le plan « ${p.plan.summary} »';
  }

  /// Exécute un plan confirmé par l'utilisateur. Seul le plan le plus
  /// récent, encore en attente, peut l'être.
  Future<PlanReport?> confirm(int entryId) async {
    final p = _plan(entryId);
    if (p == null || p.status != PlanStatus.proposed || state.busy) {
      return null;
    }
    _cancel = false;
    _replace(entryId, (_) => p.copyWith(status: PlanStatus.running));
    PlanReport report;
    try {
      report = await PlanExecutor(ref.read(agentEnvironmentProvider)).run(
        p.plan,
        onProgress: (step, done, total, current) {
          if (!ref.mounted) return;
          _replace(
            entryId,
            (e) => (e as PlanEntry).copyWith(
              progress: () => PlanProgress(step, done, total, current),
            ),
          );
        },
        isCancelled: () => _cancel,
      );
    } on Object catch (e) {
      report = PlanReport([
        StepReport(index: 0, status: StepStatus.failed, error: e),
      ]);
    }
    if (!ref.mounted) return report;
    _replace(
      entryId,
      (e) => (e as PlanEntry).copyWith(
        status: PlanStatus.finished,
        report: report,
        progress: () => null,
      ),
    );
    ref.invalidate(dashboardStatsProvider);
    ref.read(operationsRevisionProvider.notifier).bump();
    _pendingNote =
        'le plan « ${p.plan.summary} » a été exécuté. Résultat :\n'
        '${report.describeForModel()}';
    _save('plan', '${p.plan.summary} — ${report.succeeded ? 'OK' : 'échec'}');
    return report;
  }
}

final agentControllerProvider = NotifierProvider<AgentController, AgentState>(
  AgentController.new,
);
