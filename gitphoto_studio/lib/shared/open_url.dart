import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre une adresse web dans le navigateur du système.
Future<void> openUrl(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  ).catchError((Object _) => false);
  if (!ok) {
    messenger?.showSnackBar(SnackBar(content: SelectableText(url)));
  }
}
