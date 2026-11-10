# Frequently asked questions

## Are my original photos changed?

No. The app works on copies. Optimizing, converting, renaming or removing from the library never affects your original files.

## Do I need to know Git?

No. The app creates commits for you and verifies the result. The [Commits](help:commits) and [Branches](help:branches) sections explain the ideas if you are curious.

## Can I publish without Internet?

No, but you can prepare your media offline. A confirmed publication waits in the queue and leaves as soon as the connection is back (with the app open).

## Was a photo published twice?

That is prevented: an identical file already at that location is skipped, and the same publication cannot be queued twice. If a different file has the same name, yours is renamed.

## How do I delete a photo published on GitHub?

The app never deletes anything on GitHub. Do it on github.com (open the file › menu › **Delete file**). The old version will remain in the Git history.

## Why a private repository?

Only you and invited people can access it. A public repository is visible to everyone, including the photos' metadata.

## My token expired, what now?

Create a new one on GitHub, then sign in again on the GitHub screen. Queued publications will resume.

## Is AI required?

No. It is off by default and every feature works without it.

## How much does the AI agent cost?

The app is free; online AI providers usually charge per use, on your account with them. Ollama, running locally, is free.

## Why is video conversion not offered?

On Linux, install ffmpeg (`sudo apt install ffmpeg`), then refresh **Settings › Diagnostics**.

## What is the maximum size?

Up to 50 MiB through the GitHub API; from 50 MiB to 2 GiB through Git LFS (your account's quota); beyond that, rejected.

## Where can I find more help?

Search for a word in the guide's [contents](app:/help), or copy the diagnostic report (**Settings › Diagnostics**) to attach it to a help request.
