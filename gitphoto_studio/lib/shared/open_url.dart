import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Seules les adresses web sécurisées sont ouvertes (aucun autre schéma :
/// fichier, intention Android, commande…).
bool isOpenableUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

/// Ouvre une adresse web dans le navigateur du système.
Future<void> openUrl(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok =
      isOpenableUrl(url) &&
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ).catchError((Object _) => false);
  if (!ok) {
    messenger?.showSnackBar(SnackBar(content: SelectableText(url)));
  }
}
