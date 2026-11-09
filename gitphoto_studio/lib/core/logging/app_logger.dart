import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../security/secret_redactor.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  const LogEntry(this.time, this.level, this.message);

  final DateTime time;
  final LogLevel level;
  final String message;
}

/// Journal technique en mémoire. Chaque message est filtré par
/// [SecretRedactor] avant d'être conservé ou affiché.
class AppLogger {
  AppLogger({this.capacity = 500});

  final int capacity;
  final ListQueue<LogEntry> _entries = ListQueue();

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void log(LogLevel level, String message) {
    final entry = LogEntry(
      DateTime.now(),
      level,
      SecretRedactor.redact(message),
    );
    _entries.addLast(entry);
    while (_entries.length > capacity) {
      _entries.removeFirst();
    }
    if (kDebugMode) debugPrint('[${level.name}] ${entry.message}');
  }

  void info(String message) => log(LogLevel.info, message);
  void warning(String message) => log(LogLevel.warning, message);
  void error(String message) => log(LogLevel.error, message);
}
