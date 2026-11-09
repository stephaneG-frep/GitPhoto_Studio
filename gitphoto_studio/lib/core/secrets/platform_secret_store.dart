import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secret_store.dart';

/// Stockage sécurisé de la plateforme :
/// - Android : chiffrement adossé au Keystore matériel ;
/// - Linux : trousseau Secret Service (GNOME Keyring, KWallet…) via libsecret.
class PlatformSecretStore implements SecretStore {
  const PlatformSecretStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _probeKey = 'gitphoto.probe';

  /// Vérifie réellement l'accès au trousseau par une écriture/lecture/
  /// suppression d'une valeur sans importance.
  @override
  Future<SecretStoreStatus> status() async {
    try {
      await _storage.write(key: _probeKey, value: 'ok');
      final ok = await _storage.read(key: _probeKey) == 'ok';
      await _storage.delete(key: _probeKey);
      return ok ? SecretStoreStatus.available : SecretStoreStatus.unavailable;
    } on PlatformException {
      return SecretStoreStatus.unavailable;
    }
  }

  @override
  Future<String?> read(String key) => _guard(() => _storage.read(key: key));

  @override
  Future<void> write(String key, String value) =>
      _guard(() => _storage.write(key: key, value: value));

  @override
  Future<void> delete(String key) => _guard(() => _storage.delete(key: key));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (e) {
      throw SecretStoreException(e.message ?? e.code);
    }
  }
}

class SecretStoreException implements Exception {
  const SecretStoreException(this.message);

  final String message;

  @override
  String toString() => 'Stockage sécurisé indisponible : $message';
}
