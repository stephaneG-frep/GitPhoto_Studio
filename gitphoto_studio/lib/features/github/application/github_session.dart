import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/secrets/platform_secret_store.dart';
import '../../../core/secrets/secret_store.dart';
import '../data/github_api.dart';
import '../data/lfs_client.dart';
import '../data/github_exception.dart';
import '../domain/github_models.dart';

final secretStoreProvider = Provider<SecretStore>(
  (ref) => const PlatformSecretStore(),
);

/// Fabrique du client GitHub (remplacée dans les tests).
final githubApiFactoryProvider = Provider<GithubApi Function(String token)>(
  (ref) =>
      (token) => GithubApi(token: token),
);

/// Fabrique du client Git LFS (remplacée dans les tests).
final lfsClientFactoryProvider = Provider<LfsClient Function(String token)>(
  (ref) =>
      (token) => LfsClient(token: token),
);

sealed class GithubSession {
  const GithubSession();
}

class GithubDisconnected extends GithubSession {
  const GithubDisconnected({this.storeUnavailable = false});

  /// Le trousseau du système n'est pas accessible : aucune connexion ne peut
  /// être mémorisée de façon sûre.
  final bool storeUnavailable;
}

class GithubConnected extends GithubSession {
  const GithubConnected(this.user, this.api, this.token);

  final GithubUser user;
  final GithubApi api;

  /// Gardé en mémoire uniquement (Git LFS, Git natif). Jamais journalisé.
  final String token;
}

/// Jeton enregistré mais non vérifiable pour l'instant (hors ligne, jeton
/// révoqué…). L'utilisateur est informé de la cause.
class GithubSessionError extends GithubSession {
  const GithubSessionError(this.error);

  final GithubException error;
}

class GithubSessionController extends AsyncNotifier<GithubSession> {
  SecretStore get _store => ref.read(secretStoreProvider);

  @override
  Future<GithubSession> build() async {
    final status = await _store.status();
    if (status == SecretStoreStatus.unavailable) {
      return const GithubDisconnected(storeUnavailable: true);
    }
    final token = await _store.read(SecretKeys.githubToken);
    if (token == null || token.isEmpty) return const GithubDisconnected();
    return _verify(token);
  }

  Future<GithubSession> _verify(String token) async {
    final api = ref.read(githubApiFactoryProvider)(token);
    try {
      return GithubConnected(await api.getUser(), api, token);
    } on GithubException catch (e) {
      ref.read(loggerProvider).warning('Vérification du jeton GitHub : $e');
      return GithubSessionError(e);
    }
  }

  /// Vérifie le jeton auprès de GitHub puis l'enregistre dans le trousseau.
  /// Un jeton refusé n'est jamais enregistré.
  Future<GithubUser> connect(String token) async {
    final trimmed = token.trim();
    final api = ref.read(githubApiFactoryProvider)(trimmed);
    final user = await api.getUser();
    await _store.write(SecretKeys.githubToken, trimmed);
    state = AsyncData(GithubConnected(user, api, trimmed));
    ref.read(loggerProvider).info('Connecté à GitHub : ${user.login}');
    return user;
  }

  /// Efface le jeton du trousseau local. La révocation côté GitHub reste à
  /// faire par l'utilisateur dans les paramètres de son compte.
  Future<void> disconnect() async {
    await _store.delete(SecretKeys.githubToken);
    state = const AsyncData(GithubDisconnected());
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final githubSessionProvider =
    AsyncNotifierProvider<GithubSessionController, GithubSession>(
      GithubSessionController.new,
      retry: (retryCount, error) => null,
    );

/// Client GitHub de la session active, ou `null` si non connecté.
final githubApiProvider = Provider<GithubApi?>((ref) {
  final session = ref.watch(githubSessionProvider).value;
  return session is GithubConnected ? session.api : null;
});

/// Incrémenté pour recharger les listes après une modification distante.
class GithubRefresh extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final githubRefreshProvider = NotifierProvider<GithubRefresh, int>(
  GithubRefresh.new,
);

final githubReposProvider = FutureProvider<List<GithubRepo>>((ref) async {
  ref.watch(githubRefreshProvider);
  final api = ref.watch(githubApiProvider);
  if (api == null) return const [];
  return api.listRepos();
}, retry: (retryCount, error) => null);

typedef RepoRef = ({String owner, String name});

final githubBranchesProvider = FutureProvider.family<List<String>, RepoRef>((
  ref,
  repo,
) async {
  ref.watch(githubRefreshProvider);
  final api = ref.watch(githubApiProvider);
  if (api == null) return const [];
  return api.listBranches(repo.owner, repo.name);
}, retry: (retryCount, error) => null);

typedef ContentsRef = ({String owner, String name, String branch, String path});

final githubContentsProvider =
    FutureProvider.family<List<GithubContentEntry>, ContentsRef>((
      ref,
      c,
    ) async {
      ref.watch(githubRefreshProvider);
      final api = ref.watch(githubApiProvider);
      if (api == null) return const [];
      return api.getContents(c.owner, c.name, path: c.path, ref: c.branch);
    }, retry: (retryCount, error) => null);

typedef BranchRef = ({String owner, String name, String? branch});

final githubCommitsProvider =
    FutureProvider.family<List<GithubCommitSummary>, BranchRef>((ref, b) async {
      ref.watch(githubRefreshProvider);
      final api = ref.watch(githubApiProvider);
      if (api == null) return const [];
      return api.listCommits(b.owner, b.name, branch: b.branch);
    }, retry: (retryCount, error) => null);
