import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

/// Pixel, robot assistant du studio, dessiné en vectoriel (aucune image
/// externe, rendu net à toutes les tailles).
class PixelMascot extends StatelessWidget {
  const PixelMascot({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).pixelSemantics,
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _PixelPainter(brightness: Theme.of(context).brightness),
        ),
      ),
    );
  }
}

class _PixelPainter extends CustomPainter {
  _PixelPainter({required this.brightness});

  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final isDark = brightness == Brightness.dark;

    // Antenne et sa diode cyan.
    final antenna = Paint()
      ..color = StudioPalette.violet
      ..strokeWidth = s * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(s * 0.5, s * 0.08),
      Offset(s * 0.5, s * 0.2),
      antenna,
    );
    canvas.drawCircle(
      Offset(s * 0.5, s * 0.08),
      s * 0.06,
      Paint()..color = StudioPalette.cyan,
    );

    // Tête.
    final head = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.12, s * 0.2, s * 0.76, s * 0.6),
      Radius.circular(s * 0.2),
    );
    canvas.drawRRect(
      head,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [StudioPalette.violet, Color(0xFF4B33B8)],
        ).createShader(head.outerRect),
    );

    // Visière.
    final visor = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.2, s * 0.3, s * 0.6, s * 0.34),
      Radius.circular(s * 0.14),
    );
    canvas.drawRRect(
      visor,
      Paint()..color = isDark ? StudioPalette.night : const Color(0xFF1B2440),
    );

    // Yeux « pixels » carrés.
    final eye = Paint()..color = StudioPalette.cyan;
    final eyeSize = s * 0.1;
    for (final x in [0.32, 0.58]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s * x, s * 0.38, eyeSize, eyeSize),
          Radius.circular(s * 0.02),
        ),
        eye,
      );
    }

    // Sourire.
    final smile = Paint()
      ..color = StudioPalette.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(s * 0.4, s * 0.46, s * 0.2, s * 0.1),
      0.2,
      2.74,
      false,
      smile,
    );

    // Oreilles / capteurs.
    final ear = Paint()..color = StudioPalette.cyan.withValues(alpha: 0.9);
    for (final x in [0.06, 0.88]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s * x, s * 0.4, s * 0.06, s * 0.18),
          Radius.circular(s * 0.03),
        ),
        ear,
      );
    }

    // Socle.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.3, s * 0.82, s * 0.4, s * 0.12),
        Radius.circular(s * 0.06),
      ),
      Paint()..color = StudioPalette.success,
    );
  }

  @override
  bool shouldRepaint(_PixelPainter oldDelegate) =>
      oldDelegate.brightness != brightness;
}

/// Bulle de Pixel, discrète, utilisée sur le tableau de bord et ailleurs.
class PixelTip extends StatelessWidget {
  const PixelTip({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PixelMascot(size: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).pixelName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: StudioColors.of(context).accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
