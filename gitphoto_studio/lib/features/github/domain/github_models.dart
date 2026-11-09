class GithubUser {
  const GithubUser({
    required this.login,
    required this.htmlUrl,
    this.id,
    this.name,
    this.avatarUrl,
    this.scopes,
    this.tokenExpiration,
  });

  final String login;
  final String htmlUrl;
  final int? id;
  final String? name;
  final String? avatarUrl;

  /// Portées d'un jeton classique (`X-OAuth-Scopes`) ; `null` pour un jeton
  /// fine-grained, dont les permissions ne sont pas exposées ainsi.
  final List<String>? scopes;

  /// Date d'expiration annoncée par GitHub, si le jeton en a une.
  final String? tokenExpiration;

  /// Adresse « noreply » de GitHub, pour signer les commits sans exposer
  /// d'adresse personnelle.
  String get noreplyEmail => id == null
      ? '$login@users.noreply.github.com'
      : '$id+$login@users.noreply.github.com';

  factory GithubUser.fromJson(
    Map<String, Object?> json, {
    List<String>? scopes,
    String? tokenExpiration,
  }) => GithubUser(
    login: json['login']! as String,
    htmlUrl: json['html_url']! as String,
    id: (json['id'] as num?)?.toInt(),
    name: json['name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    scopes: scopes,
    tokenExpiration: tokenExpiration,
  );
}

class GithubRepo {
  const GithubRepo({
    required this.owner,
    required this.name,
    required this.isPrivate,
    required this.htmlUrl,
    required this.canPush,
    this.defaultBranch,
    this.description,
  });

  final String owner;
  final String name;
  final bool isPrivate;
  final String htmlUrl;
  final bool canPush;
  final String? defaultBranch;
  final String? description;

  String get fullName => '$owner/$name';

  factory GithubRepo.fromJson(Map<String, Object?> json) {
    final perms = json['permissions'] as Map<String, Object?>?;
    return GithubRepo(
      owner: (json['owner']! as Map<String, Object?>)['login']! as String,
      name: json['name']! as String,
      isPrivate: json['private'] == true,
      htmlUrl: json['html_url']! as String,
      canPush: perms == null ? true : perms['push'] == true,
      defaultBranch: json['default_branch'] as String?,
      description: json['description'] as String?,
    );
  }
}

enum ContentType { file, dir, other }

class GithubContentEntry {
  const GithubContentEntry({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    this.sha,
    this.htmlUrl,
  });

  final String name;
  final String path;
  final ContentType type;
  final int size;
  final String? sha;
  final String? htmlUrl;

  factory GithubContentEntry.fromJson(Map<String, Object?> json) =>
      GithubContentEntry(
        name: json['name']! as String,
        path: json['path']! as String,
        type: switch (json['type']) {
          'file' => ContentType.file,
          'dir' => ContentType.dir,
          _ => ContentType.other,
        },
        size: (json['size'] as num?)?.toInt() ?? 0,
        sha: json['sha'] as String?,
        htmlUrl: json['html_url'] as String?,
      );
}

class GithubCommitSummary {
  const GithubCommitSummary({
    required this.sha,
    required this.message,
    required this.htmlUrl,
    this.author,
    this.date,
  });

  final String sha;
  final String message;
  final String htmlUrl;
  final String? author;
  final DateTime? date;

  String get shortSha => sha.length > 7 ? sha.substring(0, 7) : sha;

  String get title => message.split('\n').first;

  factory GithubCommitSummary.fromJson(Map<String, Object?> json) {
    final commit = json['commit']! as Map<String, Object?>;
    final author = commit['author'] as Map<String, Object?>?;
    return GithubCommitSummary(
      sha: json['sha']! as String,
      message: commit['message']! as String,
      htmlUrl: json['html_url']! as String,
      author: author?['name'] as String?,
      date: DateTime.tryParse(author?['date'] as String? ?? '')?.toLocal(),
    );
  }
}

/// Arborescence distante : chemin → empreinte de blob Git.
class RemoteTree {
  const RemoteTree(this.files, {this.truncated = false});

  /// Dépôt sans aucun commit.
  static const empty = RemoteTree({});

  final Map<String, String> files;

  /// GitHub tronque les très grandes arborescences ; les vérifications
  /// individuelles restent alors nécessaires.
  final bool truncated;
}
