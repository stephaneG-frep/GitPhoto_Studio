# Preparing and publishing a video

Phone videos are often heavy. The app can create a **lighter MP4 version** before publishing.

## Convert a video

1. Open the [Editor](app:/editor) and choose the video.
2. Under **Video preparation**, choose a preset:
   - **Light (480p)**: the smallest, ideal for a preview;
   - **720p**: a good compromise;
   - **1080p**: best quality.
3. Tick **Remove audio** if the soundtrack is not needed: the file gets even lighter.
4. The **estimated size** is shown; tap **Convert to MP4**.

The original video is kept. The new version is kept **only if it is smaller**; otherwise the app tells you (the video is probably already well compressed).

## Conversion engine

- **Android**: Media3, built into the system, nothing to install.
- **Linux**: ffmpeg. If missing: `sudo apt install ffmpeg`, then **Settings › Diagnostics › Refresh**.

## Publish

Publish the converted version like a photo, with the [Publish](help:publier-photo) wizard. Above 50 MiB the file goes through [Git LFS](help:git-lfs) automatically (2 GiB at most).

> On Linux, playing the video inside the app needs a system player; otherwise it opens in your usual player.
