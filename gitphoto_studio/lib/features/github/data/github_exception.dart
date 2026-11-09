enum GithubErrorKind {
  /// Jeton absent, invalide, expiré ou révoqué (HTTP 401).
  unauthorized,

  /// Permissions insuffisantes (HTTP 403 hors limite de débit).
  forbidden,

  /// Ressource absente — ou invisible faute d'accès (HTTP 404).
  notFound,

  /// Limite de débit atteinte.
  rateLimited,

  /// La branche a évolué entre l'analyse et la publication.
  conflict,

  /// Dépôt sans aucun commit.
  emptyRepository,

  /// Données refusées par GitHub (HTTP 422), ex. nom de dépôt déjà pris.
  validation,

  /// Pas de connexion, délai dépassé.
  network,

  /// Erreur côté GitHub (HTTP 5xx).
  server,

  unknown,
}

class GithubException implements Exception {
  const GithubException(
    this.kind,
    this.message, {
    this.statusCode,
    this.resetAt,
  });

  final GithubErrorKind kind;

  /// Message technique renvoyé par GitHub (jamais de secret).
  final String message;
  final int? statusCode;

  /// Fin de la période de limitation, si connue.
  final DateTime? resetAt;

  @override
  String toString() =>
      'GithubException(${kind.name}${statusCode == null ? '' : ', $statusCode'}): $message';
}
