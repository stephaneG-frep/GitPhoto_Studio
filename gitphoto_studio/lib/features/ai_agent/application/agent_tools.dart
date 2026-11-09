import 'dart:convert';

import '../../../core/security/secret_redactor.dart';
import '../../gallery/domain/media_item.dart';
import '../../github/data/github_exception.dart';
import '../../github/domain/github_models.dart';
import '../domain/ai_provider.dart';
import 'agent_environment.dart';
import 'tool_args.dart';

/// Noms des outils proposés au modèle.
abstract final class AgentToolNames {
  static const getSelection = 'get_selection';
  static const searchMedia = 'search_media';
  static const listAlbums = 'list_albums';
  static const findSimilar = 'find_similar_media';
  static const githubStatus = 'github_status';
  static const recentOperations = 'recent_operations';
  static const previewPublication = 'preview_publication';
  static const proposePlan = 'propose_plan';

  /// Outils de consultation : exécutés sans confirmation, sans effet.
  static const readOnly = {
    getSelection,
    searchMedia,
    listAlbums,
    findSimilar,
    githubStatus,
    recentOperations,
    previewPublication,
  };
}

const _ids = {
  'type': 'array',
  'items': {'type': 'integer'},
  'description': 'Identifiants de médias de la bibliothèque.',
};

/// Schémas JSON des outils. Les arguments reçus sont de toute façon
/// revalidés par l'application : le schéma n'est qu'une aide pour le modèle.
const List<AiToolSpec> agentToolSpecs = [
  AiToolSpec(
    name: AgentToolNames.getSelection,
    description:
        'Médias actuellement sélectionnés dans la galerie par '
        "l'utilisateur (« ces photos »).",
    parameters: {'type': 'object', 'properties': <String, Object?>{}},
  ),
  AiToolSpec(
    name: AgentToolNames.searchMedia,
    description:
        'Cherche des médias de la bibliothèque locale (métadonnées '
        'seulement : nom, type, taille, dates, album, dimensions, GPS).',
    parameters: {
      'type': 'object',
      'properties': {
        'type': {
          'type': 'string',
          'enum': ['all', 'image', 'video'],
        },
        'album': {
          'type': 'string',
          'description': "Nom d'album ; chaîne vide = médias sans album.",
        },
        'text': {
          'type': 'string',
          'description': 'Fragment du nom de fichier.',
        },
        'ids': _ids,
        'taken_from': {
          'type': 'string',
          'description': 'Date minimale AAAA-MM-JJ (prise de vue ou import).',
        },
        'taken_to': {
          'type': 'string',
          'description': 'Date maximale AAAA-MM-JJ incluse.',
        },
        'limit': {'type': 'integer', 'minimum': 1, 'maximum': 200},
        'offset': {'type': 'integer', 'minimum': 0},
      },
    },
  ),
  AiToolSpec(
    name: AgentToolNames.listAlbums,
    description: 'Albums de la bibliothèque et nombre de médias.',
    parameters: {'type': 'object', 'properties': <String, Object?>{}},
  ),
  AiToolSpec(
    name: AgentToolNames.findSimilar,
    description:
        'Groupes de photos visuellement très proches (doublons probables) '
        'dans la bibliothèque. Les fichiers strictement identiques ne '
        "peuvent pas exister : l'import les refuse.",
    parameters: {
      'type': 'object',
      'properties': {'ids': _ids},
    },
  ),
  AiToolSpec(
    name: AgentToolNames.githubStatus,
    description:
        'Connexion GitHub, dépôt actif et dépôts accessibles (nom, '
        'visibilité, droit d’écriture, branche par défaut).',
    parameters: {'type': 'object', 'properties': <String, Object?>{}},
  ),
  AiToolSpec(
    name: AgentToolNames.recentOperations,
    description:
        'Historique des publications : statut, commit, erreur et état de '
        'chaque fichier. Sert à expliquer un échec.',
    parameters: {
      'type': 'object',
      'properties': {
        'limit': {'type': 'integer', 'minimum': 1, 'maximum': 20},
        'failed_only': {'type': 'boolean'},
      },
    },
  ),
  AiToolSpec(
    name: AgentToolNames.previewPublication,
    description:
        'Simule une publication sans rien envoyer : chemin final de chaque '
        'fichier, fichiers déjà présents à l’identique, renommages, '
        'transport (API ou Git LFS au-delà de 50 Mo), blocages.',
    parameters: {
      'type': 'object',
      'properties': {
        'media_ids': _ids,
        'repository': {'type': 'string', 'description': 'propriétaire/nom'},
        'branch': {'type': 'string'},
        'folder': {'type': 'string', 'description': 'Dossier du dépôt.'},
      },
      'required': ['media_ids', 'repository'],
    },
  ),
  AiToolSpec(
    name: AgentToolNames.proposePlan,
    description:
        "Présente à l'utilisateur un plan d'actions à confirmer. C'est le "
        'SEUL moyen de modifier quoi que ce soit : rien n’est exécuté sans '
        'sa validation. Types d’étapes : move_to_album (media_ids|'
        'from_steps, album), organize_by_date (media_ids|from_steps, '
        'granularity year|month), optimize_images (media_ids d’images, '
        'preset web|light|thumbnail ; crée des copies sans métadonnées), '
        'convert_videos (media_ids de vidéos, preset p720|p1080|light ; crée '
        'des copies), publish (media_ids et/ou from_steps, repository, '
        'branch, folder, message, readme facultatif en Markdown). '
        'from_steps : numéros (à partir de 1) d’étapes optimize_images ou '
        'convert_videos précédentes dont on reprend les copies produites.',
    parameters: {
      'type': 'object',
      'properties': {
        'summary': {
          'type': 'string',
          'description': 'Résumé du plan en une ou deux phrases.',
        },
        'steps': {
          'type': 'array',
          'minItems': 1,
          'maxItems': 10,
          'items': {
            'type': 'object',
            'properties': {
              'type': {
                'type': 'string',
                'enum': [
                  'move_to_album',
                  'organize_by_date',
                  'optimize_images',
                  'convert_videos',
                  'publish',
                ],
              },
              'media_ids': _ids,
              'from_steps': {
                'type': 'array',
                'items': {'type': 'integer'},
              },
              'album': {'type': 'string'},
              'granularity': {
                'type': 'string',
                'enum': ['year', 'month'],
              },
              'preset': {'type': 'string'},
              'repository': {'type': 'string'},
              'branch': {'type': 'string'},
              'folder': {'type': 'string'},
              'message': {'type': 'string'},
              'readme': {'type': 'string'},
              'note': {'type': 'string'},
            },
            'required': ['type'],
          },
        },
      },
      'required': ['summary', 'steps'],
    },
  ),
];

/// Exécute les outils de consultation. Toute erreur est renvoyée au modèle
/// sous forme d'objet `{"error": …}`, jamais levée.
class AgentToolbox {
  AgentToolbox(this.env);

  final AgentEnvironment env;

  static const maxResultChars = 12000;

  Future<String> run(String name, Map<String, Object?> args) async {
    Object? result;
    try {
      result = switch (name) {
        AgentToolNames.getSelection => _selection(),
        AgentToolNames.searchMedia => _search(args),
        AgentToolNames.listAlbums => _albums(),
        AgentToolNames.findSimilar => await _similar(args),
        AgentToolNames.githubStatus => await _github(),
        AgentToolNames.recentOperations => _operations(args),
        AgentToolNames.previewPublication => await _preview(args),
        _ => {'error': 'Outil inconnu : $name'},
      };
    } on ToolArgException catch (e) {
      result = {'error': e.message};
    } on GithubException catch (e) {
      result = {'error': 'GitHub (${e.kind.name}) : ${e.message}'};
    } on Object catch (e) {
      result = {'error': '$e'};
    }
    return encodeResult(result);
  }

  /// JSON compact, expurgé et tronqué.
  static String encodeResult(Object? result) {
    var s = SecretRedactor.redact(jsonEncode(result));
    if (s.length > maxResultChars) {
      s = jsonEncode({
        'truncated': true,
        'note': 'Résultat trop long : affinez la recherche (limit, filtres).',
        'partial': s.substring(0, maxResultChars - 200),
      });
    }
    return s;
  }

  static String _date(DateTime? d) =>
      d == null ? '' : d.toIso8601String().substring(0, 10);

  Map<String, Object?> mediaRow(MediaItem m) {
    final albums = {for (final a in env.albums()) a.id: a.name};
    return {
      'id': m.id,
      'name': m.fileName,
      'type': m.kind.name,
      'size': m.sizeBytes,
      if (m.takenAt != null) 'taken': _date(m.takenAt),
      'imported': _date(m.importedAt),
      if (m.albumId != null) 'album': albums[m.albumId],
      if (m.width != null) 'w': m.width,
      if (m.height != null) 'h': m.height,
      if (m.durationMs != null) 'duration_s': (m.durationMs! / 1000).round(),
      if (m.hasGps) 'gps': true,
      if (m.derivedFrom != null) 'version_of': m.derivedFrom,
    };
  }

  Object _selection() {
    final ids = env.selection();
    final items = [
      for (final id in ids)
        if (env.media(id) case final m?) mediaRow(m),
    ];
    return {'count': items.length, 'items': items};
  }

  Object _search(Map<String, Object?> args) {
    final type = optEnum(args, 'type', const ['all', 'image', 'video']);
    final album = optString(args, 'album', max: 100);
    final text = optString(args, 'text', max: 100)?.toLowerCase();
    final ids = optIds(args, 'ids')?.toSet();
    final from = optDate(args, 'taken_from');
    final to = optDate(args, 'taken_to');
    final limit = optInt(args, 'limit', min: 1, max: 200) ?? 50;
    final offset = optInt(args, 'offset', min: 0, max: 1000000) ?? 0;
    final albumIds = {for (final a in env.albums()) a.name.toLowerCase(): a.id};
    final albumId = album == null || album.isEmpty
        ? null
        : albumIds[album.toLowerCase()];
    if (album != null && album.isNotEmpty && albumId == null) {
      return {
        'total': 0,
        'items': const <Object>[],
        'note': 'Album « $album » inconnu',
      };
    }
    final matches = env.listMedia().where((m) {
      if (type == 'image' && m.isVideo) return false;
      if (type == 'video' && !m.isVideo) return false;
      if (album != null) {
        if (album.isEmpty && m.albumId != null) return false;
        if (album.isNotEmpty && m.albumId != albumId) return false;
      }
      if (text != null && !m.fileName.toLowerCase().contains(text)) {
        return false;
      }
      if (ids != null && !ids.contains(m.id)) return false;
      final d = m.takenAt ?? m.importedAt;
      if (from != null && d.isBefore(from)) return false;
      if (to != null && !d.isBefore(to.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
    return {
      'total': matches.length,
      'offset': offset,
      'items': [for (final m in matches.skip(offset).take(limit)) mediaRow(m)],
    };
  }

  Object _albums() => {
    'albums': [
      for (final a in env.albums()) {'name': a.name, 'count': a.count},
    ],
  };

  Future<Object> _similar(Map<String, Object?> args) async {
    final ids = optIds(args, 'ids')?.toSet();
    final groups = await env.similarGroups();
    return {
      'groups': [
        for (final g in groups)
          if (ids == null || g.any((m) => ids.contains(m.id)))
            [for (final m in g) mediaRow(m)],
      ],
    };
  }

  Future<Object> _github() async {
    final login = env.githubLogin();
    if (login == null) {
      return {
        'connected': false,
        'note': "L'utilisateur doit se connecter dans l'écran GitHub.",
      };
    }
    final repos = await env.repositories();
    final active = env.activeRepository();
    return {
      'connected': true,
      'login': login,
      if (active != null) 'active_repository': '${active.owner}/${active.name}',
      'repositories': [
        for (final r in repos.take(100))
          {
            'full_name': r.fullName,
            'private': r.isPrivate,
            'can_push': r.canPush,
            if (r.defaultBranch != null) 'default_branch': r.defaultBranch,
          },
      ],
    };
  }

  Object _operations(Map<String, Object?> args) {
    final limit = optInt(args, 'limit', min: 1, max: 20) ?? 10;
    final failedOnly = optBool(args, 'failed_only') ?? false;
    final ops = env
        .operations(limit: failedOnly ? 200 : limit)
        .where((o) => !failedOnly || o.status.name != 'success')
        .take(limit);
    return {
      'operations': [
        for (final o in ops)
          {
            'id': o.id,
            'date': o.createdAt.toIso8601String(),
            if (o.repository != null) 'repository': o.repository,
            if (o.branch != null) 'branch': o.branch,
            'status': o.status.name,
            if (o.commitMessage != null) 'message': o.commitMessage,
            if (o.commitSha != null) 'commit': o.commitSha,
            if (o.error != null) 'error': o.error,
            'attempts': o.attempts,
            'files': [
              for (final e in o.entries.take(20))
                {
                  'path': e.remotePath,
                  'status': e.status.name,
                  'transport': e.strategy,
                  if (e.sizeBytes != null) 'size': e.sizeBytes,
                  if (e.lastError != null) 'error': e.lastError,
                },
            ],
          },
      ],
    };
  }

  /// Résout un dépôt nommé par le modèle parmi ceux réellement accessibles.
  static GithubRepo? findRepo(List<GithubRepo> repos, String fullName) {
    final wanted = fullName.trim().toLowerCase();
    for (final r in repos) {
      if (r.fullName.toLowerCase() == wanted) return r;
    }
    return null;
  }

  Future<Object> _preview(Map<String, Object?> args) async {
    final ids = reqIds(args, 'media_ids', max: 500);
    final repoName = reqString(args, 'repository', max: 200);
    final repos = await env.repositories();
    final repo = findRepo(repos, repoName);
    if (repo == null) {
      return {'error': 'Dépôt « $repoName » inaccessible ou inconnu'};
    }
    final branch = optBranch(args, 'branch') ?? repo.defaultBranch ?? 'main';
    final folder = optFolder(args, 'folder') ?? '';
    final media = <MediaItem>[];
    for (final id in ids) {
      final m = env.media(id);
      if (m == null) return {'error': 'Média $id introuvable'};
      media.add(m);
    }
    final plan = await env.analyzePublication(
      repo: repo,
      branch: branch,
      folder: folder,
      media: media,
    );
    return {
      'repository': repo.fullName,
      'private': repo.isPrivate,
      'branch': branch,
      'files': [
        for (final f in plan.files)
          {
            'media_id': f.candidate.mediaId,
            'path': f.remotePath,
            'action': f.action.name,
            'transport': f.strategy.name,
            'size': f.candidate.sizeBytes,
            if (f.blockReason != null) 'blocked': f.blockReason!.name,
            if (f.warnings.isNotEmpty)
              'warnings': [for (final w in f.warnings) w.name],
            if (f.candidate.hasGps) 'gps': true,
          },
      ],
      'upload_bytes': plan.uploadBytes,
      if (plan.repositoryIsEmpty) 'empty_repository': true,
      if (plan.remoteTreeTruncated) 'remote_tree_truncated': true,
    };
  }
}
