// OUTIL (non lancé avec la suite de tests) : génère l'icône originale de
// l'application à partir de la mascotte Pixel dessinée par l'application.
//   flutter test tool/icon/render_icon_test.dart
//   python3 tool/icon/resize_icons.py
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/theme/app_theme.dart';
import 'package:gitphoto_studio/l10n/generated/app_localizations.dart';
import 'package:gitphoto_studio/shared/widgets/pixel_mascot.dart';

const _size = 1024.0;

Widget _frame(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.dark(),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Align(
    alignment: Alignment.topLeft,
    child: SizedBox.square(dimension: _size, child: child),
  ),
);

/// Fond : carré arrondi nuit avec un halo cyan et violet discret.
Widget _background({required bool rounded}) => DecoratedBox(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(rounded ? _size * 0.22 : 0),
    gradient: const RadialGradient(
      center: Alignment(-0.35, -0.45),
      radius: 1.2,
      colors: [Color(0xFF2A2160), StudioPalette.night, Color(0xFF0A1020)],
      stops: [0, 0.6, 1],
    ),
  ),
);

Future<void> _save(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first
      ..physicalSize = const Size(_size, _size)
      ..devicePixelRatio = 1;
  });

  testWidgets('icône complète (carré arrondi)', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _frame(
        RepaintBoundary(
          key: key,
          child: Stack(
            children: [
              Positioned.fill(child: _background(rounded: true)),
              const Center(child: PixelMascot(size: _size * 0.74)),
            ],
          ),
        ),
      ),
    );
    await _save(tester, key, 'tool/icon/out/icon_full.png');
  });

  testWidgets('icône adaptative Android : premier plan transparent', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _frame(
        RepaintBoundary(
          key: key,
          // Zone sûre : environ 61 % du côté (le lanceur rogne le reste).
          child: const Center(child: PixelMascot(size: _size * 0.56)),
        ),
      ),
    );
    await _save(tester, key, 'tool/icon/out/icon_foreground.png');
  });
}
