import 'package:flutter/material.dart';

/// Palette de l'identité « L'atelier des médias connectés ».
abstract final class StudioPalette {
  static const night = Color(0xFF10182B);
  static const violet = Color(0xFF7954F6);
  static const cyan = Color(0xFF19D9E6);
  static const orange = Color(0xFFFF984B);
  static const success = Color(0xFF35D9A1);
}

/// Couleurs de marque complémentaires, accessibles via
/// `Theme.of(context).extension<StudioColors>()`.
@immutable
class StudioColors extends ThemeExtension<StudioColors> {
  const StudioColors({
    required this.accent,
    required this.creative,
    required this.success,
    required this.heroGradient,
  });

  final Color accent;
  final Color creative;
  final Color success;
  final Gradient heroGradient;

  static StudioColors of(BuildContext context) =>
      Theme.of(context).extension<StudioColors>()!;

  @override
  StudioColors copyWith({
    Color? accent,
    Color? creative,
    Color? success,
    Gradient? heroGradient,
  }) {
    return StudioColors(
      accent: accent ?? this.accent,
      creative: creative ?? this.creative,
      success: success ?? this.success,
      heroGradient: heroGradient ?? this.heroGradient,
    );
  }

  @override
  StudioColors lerp(StudioColors? other, double t) {
    if (other == null) return this;
    return StudioColors(
      accent: Color.lerp(accent, other.accent, t)!,
      creative: Color.lerp(creative, other.creative, t)!,
      success: Color.lerp(success, other.success, t)!,
      heroGradient: Gradient.lerp(heroGradient, other.heroGradient, t)!,
    );
  }
}

abstract final class AppTheme {
  /// Largeur à partir de laquelle la navigation latérale permanente est
  /// affichée (tablette paysage et ordinateur).
  static const wideBreakpoint = 840.0;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    var scheme = ColorScheme.fromSeed(
      seedColor: StudioPalette.violet,
      brightness: brightness,
    );
    if (isDark) {
      scheme = scheme.copyWith(surface: StudioPalette.night);
    }

    final studio = StudioColors(
      // En mode clair, des teintes plus soutenues garantissent le contraste
      // du texte sur fond clair.
      accent: isDark ? StudioPalette.cyan : const Color(0xFF00838F),
      creative: isDark ? StudioPalette.orange : const Color(0xFFB85000),
      success: isDark ? StudioPalette.success : const Color(0xFF00805A),
      heroGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                StudioPalette.violet.withValues(alpha: 0.55),
                StudioPalette.night,
                StudioPalette.cyan.withValues(alpha: 0.25),
              ]
            : [
                StudioPalette.violet.withValues(alpha: 0.18),
                scheme.surface,
                StudioPalette.cyan.withValues(alpha: 0.14),
              ],
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [studio],
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
