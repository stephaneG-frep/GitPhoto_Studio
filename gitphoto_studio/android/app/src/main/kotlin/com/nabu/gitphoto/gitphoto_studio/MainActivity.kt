package com.nabu.gitphoto.gitphoto_studio

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.Presentation
import androidx.media3.transformer.Composition
import androidx.media3.transformer.DefaultEncoderFactory
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.Transformer
import androidx.media3.transformer.VideoEncoderSettings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors
import kotlin.math.max

/**
 * Canal « gitphoto/video » :
 * - probe : métadonnées et miniature (MediaMetadataRetriever) ;
 * - transcode / transcodeProgress / transcodeCancel : conversion MP4
 *   H.264/AAC par Media3 Transformer (encodeurs matériels de l'appareil).
 * La vidéo source n'est jamais modifiée : le résultat va dans un nouveau
 * fichier.
 */
class MainActivity : FlutterActivity() {
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var transformer: Transformer? = null
    private var pendingTranscode: MethodChannel.Result? = null
    private var transcodeOutput: File? = null
    private var cancelRequested = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "gitphoto/video")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "probe" -> handleProbe(call, result)
                    "transcode" -> handleTranscode(call, result)
                    "transcodeProgress" -> result.success(currentProgress())
                    "transcodeCancel" -> {
                        cancelRequested = true
                        transformer?.cancel()
                        finishTranscode { it.error("cancelled", "Conversion annulée", null) }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // --- Métadonnées et miniature --------------------------------------------

    private fun handleProbe(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path == null) {
            result.error("bad_args", "Chemin manquant", null)
            return
        }
        val thumbnailPath = call.argument<String>("thumbnailPath")
        val maxSize = call.argument<Int>("maxSize") ?: 320
        executor.execute {
            val outcome = runCatching { probe(path, thumbnailPath, maxSize) }
            mainHandler.post {
                outcome.fold(
                    { result.success(it) },
                    { result.error("probe_failed", it.message, null) },
                )
            }
        }
    }

    private fun probe(path: String, thumbnailPath: String?, maxSize: Int): Map<String, Any?> {
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            val duration = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull()
            var width = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull()
            var height = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull()
            val rotation = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull()
            if (rotation == 90 || rotation == 270) {
                val w = width
                width = height
                height = w
            }

            var thumbnailWritten = false
            if (thumbnailPath != null) {
                val timeUs = if (duration != null && duration < 2000) 0L else 1_000_000L
                val frame = retriever.getFrameAtTime(
                    timeUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC,
                )
                if (frame != null) {
                    val scale = maxSize.toFloat() / max(frame.width, frame.height)
                    val bitmap = if (scale < 1f) {
                        Bitmap.createScaledBitmap(
                            frame,
                            max(1, (frame.width * scale).toInt()),
                            max(1, (frame.height * scale).toInt()),
                            true,
                        )
                    } else {
                        frame
                    }
                    FileOutputStream(File(thumbnailPath)).use {
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 85, it)
                    }
                    thumbnailWritten = true
                }
            }
            return mapOf(
                "durationMs" to duration,
                "width" to width,
                "height" to height,
                "thumbnail" to thumbnailWritten,
            )
        } finally {
            retriever.release()
        }
    }

    // --- Conversion ----------------------------------------------------------

    @OptIn(UnstableApi::class)
    private fun handleTranscode(call: MethodCall, result: MethodChannel.Result) {
        if (pendingTranscode != null) {
            result.error("busy", "Une conversion est déjà en cours", null)
            return
        }
        val input = call.argument<String>("input")
        val output = call.argument<String>("output")
        if (input == null || output == null) {
            result.error("bad_args", "Chemins manquants", null)
            return
        }
        val height = call.argument<Int>("height") ?: 720
        val videoBitrate = call.argument<Int>("videoBitrate") ?: 2_500_000
        val removeAudio = call.argument<Boolean>("removeAudio") ?: false

        val outFile = File(output)
        outFile.delete()
        pendingTranscode = result
        transcodeOutput = outFile
        cancelRequested = false

        try {
            val encoderFactory = DefaultEncoderFactory.Builder(this)
                .setRequestedVideoEncoderSettings(
                    // Consigne de débit : les encodeurs matériels peuvent
                    // imposer un plancher ; le côté Dart vérifie le résultat.
                    VideoEncoderSettings.Builder().setBitrate(videoBitrate).build(),
                )
                .build()
            val t = Transformer.Builder(this)
                .setVideoMimeType(MimeTypes.VIDEO_H264)
                .setAudioMimeType(MimeTypes.AUDIO_AAC)
                .setEncoderFactory(encoderFactory)
                .addListener(object : Transformer.Listener {
                    override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                        finishTranscode { it.success(null) }
                    }

                    override fun onError(
                        composition: Composition,
                        exportResult: ExportResult,
                        exportException: ExportException,
                    ) {
                        outFile.delete()
                        finishTranscode {
                            it.error(
                                if (cancelRequested) "cancelled" else "transcode_failed",
                                exportException.message,
                                null,
                            )
                        }
                    }
                })
                .build()
            // Réduction uniquement si la vidéo dépasse la cible (jamais
            // d'agrandissement). Le petit côté sert de référence, ce qui traite
            // de la même façon vidéos paysage et portrait.
            val shortSide = shortSideOf(input)
            val videoEffects = if (shortSide == null || shortSide > height) {
                listOf(Presentation.createForShortSide(height))
            } else {
                listOf()
            }
            val item = EditedMediaItem.Builder(MediaItem.fromUri(Uri.fromFile(File(input))))
                .setRemoveAudio(removeAudio)
                .setEffects(Effects(listOf(), videoEffects))
                .build()
            transformer = t
            t.start(item, output)
        } catch (e: Exception) {
            outFile.delete()
            finishTranscode { it.error("transcode_failed", e.message, null) }
        }
    }

    private fun shortSideOf(path: String): Int? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(path)
            val w = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull()
            val h = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull()
            if (w == null || h == null) null else minOf(w, h)
        } catch (e: Exception) {
            null
        } finally {
            retriever.release()
        }
    }

    @OptIn(UnstableApi::class)
    private fun currentProgress(): Int {
        val t = transformer ?: return -1
        val holder = ProgressHolder()
        return if (t.getProgress(holder) == Transformer.PROGRESS_STATE_AVAILABLE) {
            holder.progress
        } else {
            -1
        }
    }

    private fun finishTranscode(reply: (MethodChannel.Result) -> Unit) {
        val result = pendingTranscode ?: return
        pendingTranscode = null
        transformer = null
        if (cancelRequested) transcodeOutput?.delete()
        transcodeOutput = null
        reply(result)
    }
}
