import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/home/home_page.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'core/providers/app_providers.dart';
import 'core/models/hive_adapters.dart';

/// Point d'entrée principal de l'application
void main() async {
  // Initialise Hive
  await Hive.initFlutter();
  
  // Enregistre les adapters Hive
  await HiveAdapters.initialize();
  
  // Exécute l'application
  runApp(const ProviderScope(child: GitPhotoStudioApp()));
}

/// Application GitPhoto Studio IA
class GitPhotoStudioApp extends ConsumerWidget {
  const GitPhotoStudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);
    
    return MaterialApp(
      title: 'GitPhoto Studio IA',
      debugShowCheckedModeBanner: false,
      
      // Thème
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Routes
      onGenerateRoute: generateRoute,
      initialRoute: AppRoutes.home,
      
      // Home page
      home: const HomePage(),
    );
  }
}
