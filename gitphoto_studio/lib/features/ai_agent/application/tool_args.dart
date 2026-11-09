import '../../../core/security/path_validator.dart';

/// Argument d'outil refusé : le message est renvoyé au modèle pour qu'il
/// corrige son appel.
class ToolArgException implements Exception {
  const ToolArgException(this.message);

  final String message;

  @override
  String toString() => message;
}

// Lecture stricte des arguments produits par le modèle : types vérifiés,
// bornes appliquées, aucune conversion implicite hasardeuse.

Object? _value(Map<String, Object?> args, String key) {
  final v = args[key];
  return v;
}

String? optString(Map<String, Object?> args, String key, {int max = 1000}) {
  final v = _value(args, key);
  if (v == null) return null;
  if (v is! String) throw ToolArgException('« $key » doit être un texte');
  final t = v.trim();
  if (t.length > max) {
    throw ToolArgException('« $key » dépasse $max caractères');
  }
  if (RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]').hasMatch(t)) {
    throw ToolArgException('« $key » contient des caractères de contrôle');
  }
  return t;
}

String reqString(Map<String, Object?> args, String key, {int max = 1000}) {
  final v = optString(args, key, max: max);
  if (v == null || v.isEmpty) throw ToolArgException('« $key » est requis');
  return v;
}

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is double && v == v.roundToDouble()) return v.toInt();
  // Certains modèles écrivent les nombres entre guillemets.
  if (v is String && RegExp(r'^\d{1,12}$').hasMatch(v.trim())) {
    return int.parse(v.trim());
  }
  return null;
}

int? optInt(
  Map<String, Object?> args,
  String key, {
  required int min,
  required int max,
}) {
  final v = _value(args, key);
  if (v == null) return null;
  final i = _asInt(v);
  if (i == null) throw ToolArgException('« $key » doit être un entier');
  if (i < min || i > max) {
    throw ToolArgException('« $key » doit être compris entre $min et $max');
  }
  return i;
}

bool? optBool(Map<String, Object?> args, String key) {
  final v = _value(args, key);
  if (v == null) return null;
  if (v is bool) return v;
  throw ToolArgException('« $key » doit être true ou false');
}

String? optEnum(Map<String, Object?> args, String key, List<String> allowed) {
  final v = optString(args, key, max: 50);
  if (v == null || v.isEmpty) return null;
  if (!allowed.contains(v)) {
    throw ToolArgException('« $key » doit valoir : ${allowed.join(', ')}');
  }
  return v;
}

List<int>? optIds(Map<String, Object?> args, String key, {int max = 500}) {
  final v = _value(args, key);
  if (v == null) return null;
  if (v is! List) throw ToolArgException('« $key » doit être une liste');
  final out = <int>[];
  final seen = <int>{};
  for (final e in v) {
    final i = _asInt(e);
    if (i == null || i < 1) {
      throw ToolArgException('« $key » : identifiant invalide « $e »');
    }
    if (seen.add(i)) out.add(i);
  }
  if (out.length > max) {
    throw ToolArgException('« $key » : $max éléments au maximum');
  }
  return out;
}

List<int> reqIds(Map<String, Object?> args, String key, {int max = 500}) {
  final ids = optIds(args, key, max: max);
  if (ids == null || ids.isEmpty) {
    throw ToolArgException('« $key » est requis (liste non vide)');
  }
  return ids;
}

DateTime? optDate(Map<String, Object?> args, String key) {
  final v = optString(args, key, max: 10);
  if (v == null || v.isEmpty) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v);
  final d = m == null
      ? null
      : DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  if (d == null || d.month != int.parse(m![2]!) || d.day != int.parse(m[3]!)) {
    throw ToolArgException('« $key » : date AAAA-MM-JJ attendue');
  }
  return d;
}

/// Nom de branche Git sûr (règles de `git check-ref-format`, simplifiées).
bool isValidBranchName(String b) {
  if (b.isEmpty || b.length > 200) return false;
  if (!RegExp(r'^[A-Za-z0-9._/-]+$').hasMatch(b)) return false;
  if (b.startsWith('/') || b.endsWith('/') || b.startsWith('-')) return false;
  if (b.contains('..') || b.contains('//') || b.endsWith('.lock')) {
    return false;
  }
  if (b.endsWith('.') || b.split('/').any((s) => s.startsWith('.'))) {
    return false;
  }
  return b != 'HEAD';
}

String? optBranch(Map<String, Object?> args, String key) {
  final v = optString(args, key, max: 200);
  if (v == null || v.isEmpty) return null;
  if (!isValidBranchName(v)) {
    throw ToolArgException('« $key » : nom de branche invalide « $v »');
  }
  return v;
}

/// Dossier du dépôt : chemin relatif validé (aucune traversée, aucun
/// caractère interdit). Chaîne vide = racine.
String? optFolder(Map<String, Object?> args, String key) {
  var v = optString(args, key, max: 500);
  if (v == null) return null;
  // Tolère les barres de début et de fin (« /photos/ »).
  while (v!.startsWith('/')) {
    v = v.substring(1);
  }
  while (v!.endsWith('/')) {
    v = v.substring(0, v.length - 1);
  }
  if (v.isEmpty || v == '.') return '';
  final r = PathValidator.validateRepoPath(v);
  if (!r.isValid || v.split('/').any((s) => s == '.' || s == '..')) {
    throw ToolArgException(
      '« $key » : dossier refusé « $v » (${r.issues.map((i) => i.name).join(', ')})',
    );
  }
  return r.normalized;
}
