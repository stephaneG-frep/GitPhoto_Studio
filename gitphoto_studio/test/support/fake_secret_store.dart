import 'package:gitphoto_studio/core/secrets/secret_store.dart';

/// Trousseau en mémoire — RÉSERVÉ AUX TESTS.
class FakeSecretStore implements SecretStore {
  final values = <String, String>{};
  bool available = true;

  @override
  Future<SecretStoreStatus> status() async =>
      available ? SecretStoreStatus.available : SecretStoreStatus.unavailable;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
