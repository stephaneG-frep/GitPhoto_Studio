import 'package:hive/hive.dart';
import 'hive_photo.dart';
import 'hive_album.dart';

/// Classe pour enregistrer les adapters Hive
/// Doit être appelée avant d'utiliser Hive
class HiveAdapters {
  /// Initialise tous les adapters Hive
  static Future<void> initialize() async {
    // Enregistre l'adapter pour HivePhoto
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HivePhotoAdapter());
    }
    
    // Enregistre l'adapter pour HiveAlbum
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HiveAlbumAdapter());
    }
  }
}

/// Adapter pour HivePhoto
class HivePhotoAdapter extends TypeAdapter<HivePhoto> {
  @override
  final int typeId = 0;

  @override
  HivePhoto read(BinaryReader reader) {
    return HivePhoto(
      id: reader.readString(),
      path: reader.readString(),
      name: reader.readString(),
      dateCreatedMs: reader.readInt(),
      dateModifiedMs: reader.readInt(),
      sizeBytes: reader.readInt(),
      width: reader.readInt(),
      height: reader.readInt(),
      description: reader.readString(),
      tags: reader.readStringList(),
      albumId: reader.readString(),
      latitude: reader.readDouble(),
      longitude: reader.readDouble(),
      city: reader.readString(),
      country: reader.readString(),
      isFavorite: reader.readBool(),
      rating: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, HivePhoto obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.path);
    writer.writeString(obj.name);
    writer.writeInt(obj.dateCreatedMs);
    writer.writeInt(obj.dateModifiedMs);
    writer.writeInt(obj.sizeBytes);
    writer.writeInt(obj.width);
    writer.writeInt(obj.height);
    writer.writeString(obj.description ?? '');
    writer.writeStringList(obj.tags ?? []);
    writer.writeString(obj.albumId ?? '');
    writer.writeDouble(obj.latitude ?? 0.0);
    writer.writeDouble(obj.longitude ?? 0.0);
    writer.writeString(obj.city ?? '');
    writer.writeString(obj.country ?? '');
    writer.writeBool(obj.isFavorite);
    writer.writeInt(obj.rating);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => 
    identical(this, other) || 
    (other is HivePhotoAdapter && other.typeId == typeId);
}

/// Adapter pour HiveAlbum
class HiveAlbumAdapter extends TypeAdapter<HiveAlbum> {
  @override
  final int typeId = 1;

  @override
  HiveAlbum read(BinaryReader reader) {
    return HiveAlbum(
      id: reader.readString(),
      name: reader.readString(),
      createdAtMs: reader.readInt(),
      updatedAtMs: reader.readInt(),
      description: reader.readString(),
      coverPhotoId: reader.readString(),
      photoCount: reader.readInt(),
      color: reader.readString(),
      isSmartAlbum: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveAlbum obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeInt(obj.createdAtMs);
    writer.writeInt(obj.updatedAtMs);
    writer.writeString(obj.description ?? '');
    writer.writeString(obj.coverPhotoId ?? '');
    writer.writeInt(obj.photoCount ?? 0);
    writer.writeString(obj.color ?? '');
    writer.writeBool(obj.isSmartAlbum);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => 
    identical(this, other) || 
    (other is HiveAlbumAdapter && other.typeId == typeId);
}
