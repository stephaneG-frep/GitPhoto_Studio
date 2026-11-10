# Git LFS (large files)

GitHub rejects files larger than **100 MiB** in a normal repository and warns about those above 50 MiB. **Git LFS** (Large File Storage) stores these large files separately: the repository only contains a small "pointer" file.

## How the app uses it

- Above **50 MiB**, a file is sent through Git LFS automatically (**Git LFS** badge in the analysis).
- Maximum: **2 GiB** per file (limit of a free GitHub account). Beyond that, the file is blocked before anything is sent.
- The file is streamed, without being loaded entirely into memory.
- The app also adds the matching rule to the repository's `.gitattributes` file, in the same commit.
- It works **on Android as well as Linux**, with nothing to install: the app talks directly to GitHub's LFS service.

## Quota

LFS files use your GitHub account's **LFS storage quota**, which is limited (see **Settings › Billing** on GitHub). An LFS object can only be deleted by deleting the whole repository.

## Turning Git LFS off

**Settings › Publishing › Git LFS for files larger than 50 MiB**. Files larger than 100 MiB will then be blocked.

> Tip: convert your videos to a lighter version first (see [Preparing a video](help:publier-video)); they will often drop below 50 MiB.
