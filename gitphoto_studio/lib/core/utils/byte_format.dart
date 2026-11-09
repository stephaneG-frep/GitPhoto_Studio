import 'package:intl/intl.dart';

/// Formate une taille en octets avec des unités binaires (Kio, Mio, Gio).
String formatBytes(int bytes, {String locale = 'fr'}) {
  const units = ['o', 'Kio', 'Mio', 'Gio', 'Tio'];
  if (bytes < 1024) return '$bytes ${units.first}';
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final formatted = NumberFormat('0.#', locale).format(value);
  return '$formatted ${units[unit]}';
}
