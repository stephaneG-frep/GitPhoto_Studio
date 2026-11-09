/// Contrat du stockage sécurisé des identifiants (jeton GitHub, clés IA).
///
/// L'implémentation (Keystore Android, Secret Service/libsecret sous Linux)
/// sera fournie en phase 3. SQLite ne doit jamais contenir ces valeurs.
abstract interface class SecretStore {
  Future<SecretStoreStatus> status();
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

enum SecretStoreStatus {
  available,

  /// Ex. : aucun trousseau Secret Service actif sous Linux.
  unavailable,
}

abstract final class SecretKeys {
  static const githubToken = 'github.token';
  static String aiProviderKey(String providerId) => 'ai.$providerId.key';
}
