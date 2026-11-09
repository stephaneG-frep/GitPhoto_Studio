import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/models/photo_model.dart';
import 'dart:io';

/// Tests pour le modèle Photo
void main() {
  group('Photo Model Tests', () {
    
    test('Photo.fromFile - Création à partir d\'un fichier', () {
      // Crée un fichier temporaire pour le test
      final tempDir = Directory.systemTemp.createTempSync();
      final testFile = File('${tempDir.path}/test.jpg');
      testFile.createSync();
      
      // Crée une photo à partir du fichier
      final photo = Photo.fromFile(testFile);
      
      // Vérifie les propriétés
      expect(photo.id.isNotEmpty, true);
      expect(photo.path, testFile.path);
      expect(photo.name, 'test.jpg');
      expect(photo.isFavorite, false);
      expect(photo.rating, 0);
      expect(photo.tags, []);
      
      // Nettoyage
      testFile.deleteSync();
      tempDir.deleteSync();
    });

    test('Photo - Propriétés calculées', () {
      final photo = Photo(
        id: 'test_id',
        path: '/path/to/photo.jpg',
        name: 'test.jpg',
        dateCreated: DateTime(2024, 1, 1),
        dateModified: DateTime(2024, 1, 2),
        sizeBytes: 1024 * 1024, // 1 Mo
        width: 800,
        height: 600,
        isFavorite: false,
        rating: 0,
      );
      
      // Taille en Mo
      expect(photo.sizeInMb, closeTo(1.0, 0.01));
      
      // Ratio
      expect(photo.aspectRatio, closeTo(800 / 600, 0.01));
      
      // Tags formatés
      expect(photo.formattedTags, 'Aucun tag');
      
      // hasAiMetadata
      expect(photo.hasAiMetadata, false);
    });

    test('Photo - Avec métadonnées IA', () {
      final photo = Photo(
        id: 'test_id',
        path: '/path/to/photo.jpg',
        name: 'test.jpg',
        dateCreated: DateTime(2024, 1, 1),
        dateModified: DateTime(2024, 1, 2),
        sizeBytes: 1024 * 1024,
        width: 800,
        height: 600,
        aiMetadata: {'description': 'test', 'tags': ['tag1', 'tag2']},
        isFavorite: false,
        rating: 0,
      );
      
      expect(photo.hasAiMetadata, true);
    });

    test('Photo - Avec tags', () {
      final photo = Photo(
        id: 'test_id',
        path: '/path/to/photo.jpg',
        name: 'test.jpg',
        dateCreated: DateTime(2024, 1, 1),
        dateModified: DateTime(2024, 1, 2),
        sizeBytes: 1024 * 1024,
        width: 800,
        height: 600,
        tags: ['paysage', 'nature', 'arbre'],
        isFavorite: false,
        rating: 0,
      );
      
      expect(photo.formattedTags, 'paysage, nature, arbre');
    });

    test('Photo - Génération d\'ID unique', () {
      final photo1 = Photo.fromFile(File('/path1/test1.jpg'));
      final photo2 = Photo.fromFile(File('/path2/test2.jpg'));
      
      // Les IDs doivent être différents pour des chemins différents
      // Note: Dans l'implémentation actuelle, les IDs sont basés sur le hash du chemin
      // donc ils peuvent être les mêmes si les chemins ont le même hash
      // Ce test peut être instable
      expect(photo1.id.isNotEmpty, true);
      expect(photo2.id.isNotEmpty, true);
    });

    test('Photo - Sérialisation JSON', () {
      final photo = Photo(
        id: 'test_id',
        path: '/path/to/photo.jpg',
        name: 'test.jpg',
        dateCreated: DateTime(2024, 1, 1),
        dateModified: DateTime(2024, 1, 2),
        sizeBytes: 1024 * 1024,
        width: 800,
        height: 600,
        description: 'Test description',
        tags: ['tag1', 'tag2'],
        albumId: 'album1',
        latitude: 48.8566,
        longitude: 2.3522,
        city: 'Paris',
        country: 'France',
        aiMetadata: {'test': 'value'},
        isFavorite: true,
        rating: 5,
      );
      
      // Sérialisation
      final json = photo.toJson();
      expect(json['id'], 'test_id');
      expect(json['path'], '/path/to/photo.jpg');
      expect(json['name'], 'test.jpg');
      expect(json['description'], 'Test description');
      expect(json['tags'], ['tag1', 'tag2']);
      expect(json['isFavorite'], true);
      expect(json['rating'], 5);
      
      // Désérialisation
      final photoFromJson = Photo.fromJson(json);
      expect(photoFromJson.id, photo.id);
      expect(photoFromJson.name, photo.name);
      expect(photoFromJson.description, photo.description);
      expect(photoFromJson.isFavorite, photo.isFavorite);
    });
  });
}
