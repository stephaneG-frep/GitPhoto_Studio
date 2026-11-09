import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/models/album_model.dart';

/// Tests pour le modèle Album
void main() {
  group('Album Model Tests', () {
    
    test('Album.newAlbum - Création d\'un nouvel album', () {
      final album = Album.newAlbum(
        name: 'Vacances 2024',
        description: 'Photos des vacances d\'été',
        color: '#FF0000',
      );
      
      expect(album.id.isNotEmpty, true);
      expect(album.name, 'Vacances 2024');
      expect(album.description, 'Photos des vacances d\'été');
      expect(album.color, '#FF0000');
      expect(album.isSmartAlbum, false);
      expect(album.photoCount, 0);
    });

    test('Album.allMediaAlbum - Album "Tous les médias"', () {
      final album = Album.allMediaAlbum;
      
      expect(album.id, 'all_media');
      expect(album.name, 'Tous les médias');
      expect(album.isSmartAlbum, true);
      expect(album.isSystemAlbum, true);
    });

    test('Album.favoritesAlbum - Album "Favoris"', () {
      final album = Album.favoritesAlbum;
      
      expect(album.id, 'favorites');
      expect(album.name, 'Favoris');
      expect(album.isSmartAlbum, true);
      expect(album.isSystemAlbum, true);
    });

    test('Album - Génération de couleur aléatoire', () {
      final colors = Album.getRandomColor();
      expect(colors.startsWith('#'), true);
      expect(colors.length, 7);
    });

    test('Album - isSystemAlbum pour albums normaux', () {
      final album = Album.newAlbum(name: 'Test');
      expect(album.isSystemAlbum, false);
    });

    test('Album - Sérialisation JSON', () {
      final album = Album.newAlbum(
        name: 'Test Album',
        description: 'Test Description',
      );
      
      // Sérialisation
      final json = album.toJson();
      expect(json['id'], album.id);
      expect(json['name'], 'Test Album');
      expect(json['description'], 'Test Description');
      expect(json['isSmartAlbum'], false);
      
      // Désérialisation
      final albumFromJson = Album.fromJson(json);
      expect(albumFromJson.id, album.id);
      expect(albumFromJson.name, album.name);
      expect(albumFromJson.description, album.description);
      expect(albumFromJson.isSmartAlbum, false);
    });

    test('Album - Albums avec critères intelligents', () {
      final album = Album(
        id: 'smart_album',
        name: 'Album Intelligent',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSmartAlbum: true,
        smartAlbumCriteria: {'type': 'date', 'value': 'last_week'},
      );
      
      expect(album.isSmartAlbum, true);
      expect(album.smartAlbumCriteria, {'type': 'date', 'value': 'last_week'});
    });

    test('Album - copyWith', () {
      final album = Album.newAlbum(name: 'Original');
      final updatedAlbum = album.copyWith(name: 'Updated');
      
      expect(updatedAlbum.name, 'Updated');
      expect(updatedAlbum.id, album.id);
      expect(updatedAlbum.createdAt, album.createdAt);
    });
  });
}
