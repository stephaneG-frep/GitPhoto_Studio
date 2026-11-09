import 'package:flutter/material.dart';
import '../features/home/home_page.dart';
import '../features/gallery/gallery_page.dart';
import '../features/settings/settings_page.dart';
import '../features/settings/ai_settings_page.dart';
import '../features/ai/ai_assistant_page.dart';
import '../core/models/photo_model.dart';

/// Routes disponibles dans l'application
class AppRoutes {
  static const String home = '/';
  static const String gallery = '/gallery';
  static const String album = '/album';
  static const String photoDetail = '/photo/detail';
  static const String settings = '/settings';
  static const String aiSettings = '/settings/ai';
  static const String aiAssistant = '/ai/assistant';
  static const String aiAnalysis = '/ai/analysis';
}

/// Génère les routes de l'application
Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.home:
      return MaterialPageRoute(
        builder: (_) => const HomePage(),
      );

    case AppRoutes.gallery:
      final args = settings.arguments as Map<String, dynamic>?;
      final albumId = args?['albumId'] as String?;
      return MaterialPageRoute(
        builder: (_) => GalleryPage(albumId: albumId),
      );

    case AppRoutes.photoDetail:
      final photo = settings.arguments as Photo?;
      if (photo == null) {
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Photo introuvable')),
          ),
        );
      }
      return MaterialPageRoute(
        builder: (_) => PhotoDetailPage(photo: photo),
      );

    case AppRoutes.settings:
      return MaterialPageRoute(
        builder: (_) => const SettingsPage(),
      );

    case AppRoutes.aiSettings:
      return MaterialPageRoute(
        builder: (_) => const AiSettingsPage(),
      );

    case AppRoutes.aiAssistant:
      return MaterialPageRoute(
        builder: (_) => const AiAssistantPage(),
      );

    case AppRoutes.aiAnalysis:
      final photo = settings.arguments as Photo?;
      if (photo == null) {
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Photo introuvable')),
          ),
        );
      }
      return MaterialPageRoute(
        builder: (_) => AiAnalysisPage(photo: photo),
      );

    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('Route non trouvée: ${settings.name}'),
          ),
        ),
      );
  }
}

/// Page de détails d'une photo
class PhotoDetailPage extends StatelessWidget {
  final Photo photo;

  const PhotoDetailPage({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(photo.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Détails de: ${photo.name}'),
            const SizedBox(height: 20),
            Text('Date: ${photo.dateCreated.toString().split(' ').first}'),
            const SizedBox(height: 10),
            Text('Taille: ${photo.sizeInMb.toStringAsFixed(2)} Mo'),
            const SizedBox(height: 10),
            Text('Résolution: ${photo.width}x${photo.height}'),
          ],
        ),
      ),
    );
  }
}


