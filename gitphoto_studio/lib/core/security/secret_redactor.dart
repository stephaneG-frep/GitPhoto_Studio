/// Masque les secrets (jetons GitHub, clés d'API, en-têtes d'autorisation)
/// avant toute écriture dans un journal ou un message d'erreur.
abstract final class SecretRedactor {
  static const mask = '«masqué»';

  static final List<RegExp> _patterns = [
    // Jetons GitHub classiques et fine-grained.
    RegExp(r'\bgh[pousr]_[A-Za-z0-9]{20,}\b'),
    RegExp(r'\bgithub_pat_[A-Za-z0-9_]{20,}\b'),
    // Clés de type « sk-… » (OpenAI, Anthropic « sk-ant-… », etc.).
    RegExp(r'\bsk-[A-Za-z0-9_\-]{16,}'),
    // Clés Google API.
    RegExp(r'\bAIza[0-9A-Za-z_\-]{30,}'),
  ];

  static final RegExp _authHeader = RegExp(
    r'((?:authorization|x-api-key|api-key)\s*[:=]\s*)(?:(bearer|token|basic)\s+)?[^\s,;"]+',
    caseSensitive: false,
  );

  static final RegExp _queryKey = RegExp(
    r'([?&](?:key|api_key|apikey|access_token|token)=)[^&\s#]+',
    caseSensitive: false,
  );

  static String redact(String input) {
    var output = input.replaceAllMapped(_authHeader, (m) {
      final scheme = m[2];
      return '${m[1]}${scheme == null ? '' : '$scheme '}$mask';
    });
    output = output.replaceAllMapped(_queryKey, (m) => '${m[1]}$mask');
    for (final pattern in _patterns) {
      output = output.replaceAll(pattern, mask);
    }
    return output;
  }
}
