import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/publishing/application/publish_queue.dart';
import '../l10n/generated/app_localizations.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class GitPhotoStudioApp extends ConsumerStatefulWidget {
  const GitPhotoStudioApp({super.key, this.initialLocation = '/'});

  final String initialLocation;

  @override
  ConsumerState<GitPhotoStudioApp> createState() => _GitPhotoStudioAppState();
}

class _GitPhotoStudioAppState extends ConsumerState<GitPhotoStudioApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Garde la file d'attente active : elle reprend les publications
    // confirmées dès qu'une session GitHub est disponible.
    ref.listen(publishQueueProvider, (_, _) {});
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
