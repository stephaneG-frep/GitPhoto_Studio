import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/optimization.dart';

class TranscodeCancelled implements Exception {
  const TranscodeCancelled();
}

class TranscodeException implements Exception {
  const TranscodeException(this.message);

  final String message;

  @override
  String toString() => 'Conversion vidéo impossible : $message';
}

/// Conversion d'une vidéo en MP4 H.264/AAC allégé, vers un NOUVEAU fichier.
abstract interface class VideoTranscoder {
  bool get isSupported;

  /// Nom du moteur affiché à l'utilisateur.
  String get engineName;

  Future<void> transcode({
    required String input,
    required String output,
    required VideoPreset preset,
    bool removeAudio = false,
    int? videoBitrate,
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  });
}

/// Android : Media3 Transformer (encodeurs matériels), via MainActivity.kt.
class AndroidVideoTranscoder implements VideoTranscoder {
  const AndroidVideoTranscoder();

  static const _channel = MethodChannel('gitphoto/video');

  @override
  bool get isSupported => true;

  @override
  String get engineName => 'Media3 Transformer';

  @override
  Future<void> transcode({
    required String input,
    required String output,
    required VideoPreset preset,
    bool removeAudio = false,
    int? videoBitrate,
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final done = _channel.invokeMethod<void>('transcode', {
      'input': input,
      'output': output,
      'height': preset.height,
      'videoBitrate': videoBitrate ?? preset.videoBitrate,
      'audioBitrate': VideoPreset.audioBitrate,
      'removeAudio': removeAudio,
    });
    var finished = false;
    var cancelled = false;
    final poll = Timer.periodic(const Duration(milliseconds: 400), (_) async {
      if (finished) return;
      if (!cancelled && (isCancelled?.call() ?? false)) {
        cancelled = true;
        await _channel.invokeMethod<void>('transcodeCancel');
        return;
      }
      final p = await _channel.invokeMethod<int>('transcodeProgress');
      if (p != null && p >= 0) onProgress?.call(p / 100);
    });
    try {
      await done;
      onProgress?.call(1);
    } on PlatformException catch (e) {
      if (e.code == 'cancelled') throw const TranscodeCancelled();
      throw TranscodeException(e.message ?? e.code);
    } finally {
      finished = true;
      poll.cancel();
    }
  }
}

/// Linux : ffmpeg du système, lancé avec des arguments fixes (aucun shell).
class FfmpegVideoTranscoder implements VideoTranscoder {
  const FfmpegVideoTranscoder({required this.available});

  final bool available;

  @override
  bool get isSupported => available;

  @override
  String get engineName => 'ffmpeg';

  static List<String> buildArguments({
    required String input,
    required String output,
    required VideoPreset preset,
    required bool removeAudio,
    int? videoBitrate,
  }) {
    final bitrate = videoBitrate ?? preset.videoBitrate;
    return [
      '-hide_banner',
      '-nostdin',
      '-y',
      '-i',
      input,
      // Ne jamais agrandir une vidéo plus petite que la cible.
      '-vf',
      "scale=-2:'min(${preset.height},ih)'",
      '-c:v',
      'libx264',
      '-preset',
      'medium',
      '-b:v',
      '${bitrate ~/ 1000}k',
      '-maxrate',
      '${bitrate * 3 ~/ 2000}k',
      '-bufsize',
      '${bitrate * 2 ~/ 1000}k',
      '-pix_fmt',
      'yuv420p',
      if (removeAudio)
        '-an'
      else ...[
        '-c:a',
        'aac',
        '-b:a',
        '${VideoPreset.audioBitrate ~/ 1000}k',
      ],
      '-movflags',
      '+faststart',
      '-progress',
      'pipe:1',
      '-nostats',
      output,
    ];
  }

  @override
  Future<void> transcode({
    required String input,
    required String output,
    required VideoPreset preset,
    bool removeAudio = false,
    int? videoBitrate,
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    if (!available) throw const TranscodeException('ffmpeg absent');
    final durationMs = (await ffprobeVideo(input))?.durationMs;
    final process = await Process.start(
      'ffmpeg',
      buildArguments(
        input: input,
        output: output,
        preset: preset,
        removeAudio: removeAudio,
        videoBitrate: videoBitrate,
      ),
    );
    final errors = StringBuffer();
    final stderrDone = process.stderr.transform(utf8.decoder).forEach((s) {
      errors.write(s);
      if (errors.length > 8000) {
        final text = errors.toString();
        errors
          ..clear()
          ..write(text.substring(text.length - 4000));
      }
    });
    var cancelled = false;
    final watcher = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!cancelled && (isCancelled?.call() ?? false)) {
        cancelled = true;
        process.kill();
      }
    });
    await process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
          if (line.startsWith('out_time_us=') && durationMs != null) {
            final us = int.tryParse(line.substring(12));
            if (us != null && durationMs > 0) {
              onProgress?.call((us / 1000 / durationMs).clamp(0, 1));
            }
          }
        });
    final code = await process.exitCode;
    await stderrDone;
    watcher.cancel();
    if (cancelled) {
      _deleteIfExists(output);
      throw const TranscodeCancelled();
    }
    if (code != 0) {
      _deleteIfExists(output);
      final lines = errors.toString().trim().split('\n');
      throw TranscodeException(lines.isEmpty ? 'code $code' : lines.last);
    }
    onProgress?.call(1);
  }

  static void _deleteIfExists(String path) {
    final f = File(path);
    if (f.existsSync()) f.deleteSync();
  }
}

class UnavailableVideoTranscoder implements VideoTranscoder {
  const UnavailableVideoTranscoder();

  @override
  bool get isSupported => false;

  @override
  String get engineName => '';

  @override
  Future<void> transcode({
    required String input,
    required String output,
    required VideoPreset preset,
    bool removeAudio = false,
    int? videoBitrate,
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) => throw const TranscodeException('aucun moteur vidéo disponible');
}

class FfprobeInfo {
  const FfprobeInfo({this.durationMs, this.width, this.height});

  final int? durationMs;
  final int? width;
  final int? height;
}

/// Métadonnées d'une vidéo via ffprobe (Linux), `null` si indisponible.
Future<FfprobeInfo?> ffprobeVideo(String path) async {
  try {
    final r = await Process.run('ffprobe', [
      '-v',
      'error',
      '-print_format',
      'json',
      '-show_format',
      '-show_streams',
      path,
    ]).timeout(const Duration(seconds: 20));
    if (r.exitCode != 0) return null;
    final json = jsonDecode(r.stdout as String) as Map<String, Object?>;
    final streams = (json['streams'] as List? ?? const [])
        .cast<Map<String, Object?>>();
    final video = streams.where((s) => s['codec_type'] == 'video').firstOrNull;
    final seconds = double.tryParse(
      '${(json['format'] as Map?)?['duration'] ?? ''}',
    );
    int? width = (video?['width'] as num?)?.toInt();
    int? height = (video?['height'] as num?)?.toInt();
    final rotation = _rotation(video);
    if (rotation % 180 != 0) (width, height) = (height, width);
    return FfprobeInfo(
      durationMs: seconds == null ? null : (seconds * 1000).round(),
      width: width,
      height: height,
    );
  } on Object {
    return null;
  }
}

int _rotation(Map<dynamic, dynamic>? stream) {
  if (stream == null) return 0;
  final tags = stream['tags'];
  if (tags is Map && tags['rotate'] != null) {
    return int.tryParse('${tags['rotate']}')?.abs() ?? 0;
  }
  final sideData = stream['side_data_list'];
  if (sideData is List) {
    for (final d in sideData) {
      if (d is Map && d['rotation'] is num) {
        return (d['rotation'] as num).toInt().abs();
      }
    }
  }
  return 0;
}
