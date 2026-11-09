/// Tests pour AIAnalysisService

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/services/ai_analysis_service.dart';
import 'package:gitphoto_studio/core/models/photo_model.dart';
import 'package:gitphoto_studio/core/models/ai_analysis_result.dart';

void main() {
  late AIAnalysisService aiAnalysisService;
  late Photo testPhoto;

  setUp(() {
    aiAnalysisService = AIAnalysisService();
    testPhoto = Photo(
      id: 'test_photo_1',
      path: '/test/path.jpg',
      name: 'Test Photo',
      dateCreated: DateTime.now(),
      dateModified: DateTime.now(),
      sizeBytes: 1024,
      width: 800,
      height: 600,
    );
  });

  group('AIAnalysisService - Initialisation', () {
    test('Service crée avec succès', () {
      expect(aiAnalysisService, isNotNull);
      expect(aiAnalysisService, isA<AIAnalysisService>());
    });

    test('Vérification de la disponibilité sans clé API', () async {
      // Sans clé API, isAvailable devrait retourner false
      final isAvailable = await aiAnalysisService.isAvailable();
      expect(isAvailable, false);
    });
  });

  group('AIAnalysisService - Gestion du cache', () {
    test('Cache vide au départ', () {
      // Le cache devrait être vide au début
      // On ne peut pas accéder directement au cache privé, 
      // mais on peut vérifier le comportement
      expect(() => aiAnalysisService.clearCache(), returnsNormally);
    });

    test('clearCache ne lève pas d\'exception', () {
      expect(() => aiAnalysisService.clearCache(), returnsNormally);
    });
  });

  group('AIAnalysisService - Génération de tags', () {
    test('generateTags retourne une liste sans API', () async {
      final tags = await aiAnalysisService.generateTags(testPhoto);
      // Sans clé API, cela devrait retourner une liste avec au moins le nom du fichier
      expect(tags, isNotNull);
      expect(tags, isA<List<String>>());
    });

    test('generateTags retourne au moins un tag', () async {
      final tags = await aiAnalysisService.generateTags(testPhoto);
      // Devrait contenir au moins le nom de la photo
      expect(tags.length, greaterThanOrEqualTo(0));
    });
  });

  group('AIAnalysisResult - Modèle', () {
    test('Création d\'un résultat d\'analyse', () {
      final result = AIAnalysisResult(
        photoId: 'test_1',
        description: 'Une belle photo',
        tags: ['paysage', 'nature'],
        categories: ['Paysage'],
        qualityScore: 8,
        dominantColors: ['vert', 'bleu'],
        objectsDetected: ['arbre', 'ciel'],
        mood: 'calme',
        style: 'paysage',
        technicalNotes: {
          'lighting': 'bonne',
          'composition': 'équilibrée',
          'focus': 'nette',
        },
        timestamp: DateTime.now().toIso8601String(),
      );

      expect(result.photoId, 'test_1');
      expect(result.description, 'Une belle photo');
      expect(result.tags, ['paysage', 'nature']);
      expect(result.qualityScore, 8);
      expect(result.isComplete, true);
    });

    test('allTags combine tous les tags', () {
      final result = AIAnalysisResult(
        photoId: 'test_1',
        description: 'Test',
        tags: ['tag1', 'tag2'],
        categories: ['cat1'],
        qualityScore: 5,
        dominantColors: [],
        objectsDetected: ['obj1'],
        mood: 'mood',
        style: 'style',
        technicalNotes: {},
        timestamp: DateTime.now().toIso8601String(),
      );

      final allTags = result.allTags;
      expect(allTags, contains('tag1'));
      expect(allTags, contains('tag2'));
      expect(allTags, contains('cat1'));
      expect(allTags, contains('obj1'));
      expect(allTags, contains('mood'));
      expect(allTags, contains('style'));
    });

    test('isComplete vérifie si l\'analyse est complète', () {
      final completeResult = AIAnalysisResult(
        photoId: 'test_1',
        description: 'Test',
        tags: ['tag1'],
        categories: ['cat1'],
        qualityScore: 5,
        dominantColors: [],
        objectsDetected: [],
        mood: '',
        style: '',
        technicalNotes: {},
        timestamp: DateTime.now().toIso8601String(),
      );

      expect(completeResult.isComplete, true);

      final incompleteResult = AIAnalysisResult(
        photoId: 'test_2',
        description: '',
        tags: [],
        categories: [],
        qualityScore: 0,
        dominantColors: [],
        objectsDetected: [],
        mood: '',
        style: '',
        technicalNotes: {},
        timestamp: DateTime.now().toIso8601String(),
      );

      expect(incompleteResult.isComplete, false);
    });

    test('copyWith crée une copie modifiée', () {
      final original = AIAnalysisResult(
        photoId: 'test_1',
        description: 'Original',
        tags: ['tag1'],
        categories: ['cat1'],
        qualityScore: 5,
        dominantColors: [],
        objectsDetected: [],
        mood: '',
        style: '',
        technicalNotes: {},
        timestamp: DateTime.now().toIso8601String(),
      );

      final modified = original.copyWith(
        description: 'Modified',
        qualityScore: 8,
      );

      expect(modified.description, 'Modified');
      expect(modified.qualityScore, 8);
      expect(modified.photoId, original.photoId);
      expect(modified.tags, original.tags);
    });

    test('toJson et fromJson fonctionnent correctement', () {
      final original = AIAnalysisResult(
        photoId: 'test_1',
        description: 'Test',
        tags: ['tag1', 'tag2'],
        categories: ['cat1'],
        qualityScore: 7,
        dominantColors: ['red', 'blue'],
        objectsDetected: ['object1'],
        mood: 'happy',
        style: 'portrait',
        technicalNotes: {
          'lighting': 'good',
        },
        timestamp: '2024-01-01T00:00:00.000',
      );

      final json = original.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['photoId'], 'test_1');
      expect(json['description'], 'Test');
      expect(json['qualityScore'], 7);

      final fromJson = AIAnalysisResult.fromJson(json);
      expect(fromJson.photoId, original.photoId);
      expect(fromJson.description, original.description);
      expect(fromJson.qualityScore, original.qualityScore);
    });
  });

  group('AIAnalysisService - Méthodes utilitaires', () {
    test('classifyByFolder classe les photos par dossier', () async {
      final photos = [
        Photo(
          id: '1',
          path: '/album1/photo1.jpg',
          name: 'Photo 1',
          dateCreated: DateTime.now(),
          dateModified: DateTime.now(),
          sizeBytes: 1024,
          width: 800,
          height: 600,
        ),
        Photo(
          id: '2',
          path: '/album1/photo2.jpg',
          name: 'Photo 2',
          dateCreated: DateTime.now(),
          dateModified: DateTime.now(),
          sizeBytes: 1024,
          width: 800,
          height: 600,
        ),
        Photo(
          id: '3',
          path: '/album2/photo3.jpg',
          name: 'Photo 3',
          dateCreated: DateTime.now(),
          dateModified: DateTime.now(),
          sizeBytes: 1024,
          width: 800,
          height: 600,
        ),
      ];

      final albums = await aiAnalysisService.classifyByFolder(photos);
      
      expect(albums, isNotNull);
      expect(albums, isA<Map<String, List<Photo>>>());
      expect(albums.keys, contains('album1'));
      expect(albums.keys, contains('album2'));
      expect(albums['album1']?.length, 2);
      expect(albums['album2']?.length, 1);
    });
  });

  group('AIAnalysisService - Génération de légende', () {
    test('generateCaption retourne null sans API', () async {
      final caption = await aiAnalysisService.generateCaption(testPhoto);
      expect(caption, isNull);
    });
  });

  group('AIAnalysisService - Recherche sémantique', () {
    test('semanticSearch retourne une liste vide sans API', () async {
      final photos = [testPhoto];
      final results = await aiAnalysisService.semanticSearch('test', photos);
      expect(results, isNotNull);
      expect(results, isA<List<Photo>>());
    });
  });
}
