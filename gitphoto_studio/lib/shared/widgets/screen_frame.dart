import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Gabarit commun des écrans : contenu défilant, largeur maximale lisible et
/// titre affiché uniquement sur grand écran (sur téléphone, la barre
/// d'application porte déjà le titre).
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= AppTheme.wideBreakpoint;
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: EdgeInsets.all(isWide ? 32 : 16),
            children: [
              if (isWide) ...[
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Titre de section accessible.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
