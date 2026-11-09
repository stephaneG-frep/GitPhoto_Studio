import 'dart:io';

/// Ouvre un fichier avec l'application associée par le système.
///
/// Linux : `xdg-open` avec le chemin passé comme argument unique (aucun
/// shell). Renvoie `false` si la plateforme n'est pas prise en charge ou si
/// le lancement échoue.
abstract interface class ExternalOpener {
  bool get isSupported;
  Future<bool> open(String path);
}

class SystemExternalOpener implements ExternalOpener {
  const SystemExternalOpener();

  @override
  bool get isSupported => Platform.isLinux;

  @override
  Future<bool> open(String path) async {
    if (!isSupported || !File(path).existsSync()) return false;
    try {
      await Process.start('xdg-open', [path], mode: ProcessStartMode.detached);
      return true;
    } on ProcessException {
      return false;
    }
  }
}
