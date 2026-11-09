import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Lecteur vidéo intégré (plateformes prises en charge par `video_player`).
class VideoView extends StatefulWidget {
  const VideoView({super.key, required this.path});

  final String path;

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  late final VideoPlayerController _controller = VideoPlayerController.file(
    File(widget.path),
  );
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    _controller.initialize().then(
      (_) {
        if (mounted) setState(() {});
      },
      onError: (Object e) {
        if (mounted) setState(() => _error = e);
      },
    );
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onUpdate)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = _controller.value;
    if (_error != null || value.hasError) {
      return Center(
        child: Text(
          l10n.viewerVideoError('${_error ?? value.errorDescription}'),
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (!value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        VideoProgressIndicator(_controller, allowScrubbing: true),
        IconButton(
          iconSize: 48,
          color: Colors.white,
          tooltip: value.isPlaying ? l10n.viewerPause : l10n.viewerPlay,
          onPressed: () =>
              value.isPlaying ? _controller.pause() : _controller.play(),
          icon: Icon(value.isPlaying ? Icons.pause_circle : Icons.play_circle),
        ),
      ],
    );
  }
}
