import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/models/photo_model.dart';
import 'package:gitphoto_studio/core/services/ai_service.dart';

void main() {
  group('AI Service Tests', () {
    late AiService aiService;

    setUp(() {
      aiService = AiService();
    });

    test('Initialization without API key', () async {
      await aiService.initialize();
      
      expect(aiService.isInitialized, false);
      expect(aiService.isConnected, false);
    });

    test('Initialization with API key', () async {
      const testApiKey = 'test_api_key_12345';
      await aiService.initialize(apiKey: testApiKey);
      
      expect(aiService.isInitialized, true);
    });

    test('Model getter and setter', () {
      final initialModel = aiService.currentModel;
      expect(initialModel, isNotEmpty);
      
      const newModel = 'mistral-small-latest';
      aiService.setModel(newModel);
      expect(aiService.currentModel, newModel);
      
      // Réinitialiser
      aiService.setModel(initialModel);
    });

    test('Singleton pattern', () {
      final service1 = AiService();
      final service2 = AiService();
      
      expect(service1, service2);
      expect(identical(service1, service2), true);
    });

    test('Generate description prompt for photo - no API key', () async {
      final photo = Photo(
        id: 'test_001',
        path: '/test/path.jpg',
        name: 'test_photo.jpg',
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
        sizeBytes: 1024,
        width: 100,
        height: 100,
      );

      await aiService.initialize(); // Sans clé API
      
      // Doit lancer une exception
      expect(
        () => aiService.generatePhotoDescription(photo: photo),
        throwsException,
      );
    });

    test('Generate tags prompt for photo - no API key', () async {
      final photo = Photo(
        id: 'test_002',
        path: '/test/path2.jpg',
        name: 'landscape.jpg',
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
        sizeBytes: 2048,
        width: 1920,
        height: 1080,
        tags: ['nature'],
      );

      await aiService.initialize();
      
      expect(
        () => aiService.generatePhotoTags(photo: photo, maxTags: 5),
        throwsException,
      );
    });

    test('Analyze photo objects - no API key', () async {
      final photo = Photo(
        id: 'test_003',
        path: '/test/path3.jpg',
        name: 'portrait.jpg',
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
        sizeBytes: 2048,
        width: 800,
        height: 600,
      );

      await aiService.initialize();
      
      expect(
        () => aiService.analyzePhotoObjects(photo: photo),
        throwsException,
      );
    });

    test('Ask about photo - no API key', () async {
      final photo = Photo(
        id: 'test_004',
        path: '/test/path4.jpg',
        name: 'sunset.jpg',
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
        sizeBytes: 2048,
        width: 1920,
        height: 1080,
      );

      await aiService.initialize();
      
      expect(
        () => aiService.askAboutPhoto(photo: photo, question: 'What is in this photo?'),
        throwsException,
      );
    });

    test('Base URL and model configuration', () async {
      const customBaseUrl = 'https://custom.api.mistral.ai/v1';
      const customModel = 'custom-model';
      
      await aiService.initialize(
        apiKey: 'test_key',
        baseUrl: customBaseUrl,
        model: customModel,
      );
      
      // Note: baseUrl est privé, on vérifie juste que ça ne crash pas
      expect(aiService.currentModel, customModel);
    });

    test('Check connectivity without API key', () async {
      await aiService.initialize();
      
      final isConnected = await aiService.checkConnectivity();
      expect(isConnected, false);
    });
  });
}
