# Publishing a photo

The [Publish](app:/publish) wizard shows you **exactly** what will be sent before touching GitHub.

## The steps

1. **Media**: tick the photos or videos to publish.
2. **Destination**: repository, branch and folder (for example `photos/2024`). A missing folder is created automatically; leave empty for the root.
3. **Analysis**: the app compares your files with the repository:
   - **New**: the file will be added;
   - **Identical on GitHub — skipped**: already published, nothing is sent again;
   - **Name taken — published under another name**: a different file has this name; yours is renamed so nothing is overwritten. Tick **Replace instead of renaming** only if you really want to replace the old one.
4. **Message**: the sentence describing the publication in GitHub's history (the *commit message*).
5. **Review**: the final list; then **Publish to GitHub** and a confirmation.
6. **Result**: the commit created, verified on GitHub, with a link to open it.

## Good to know

- All files go in **a single commit**. For an empty repository, a first commit initializes it with one file, then a second one groups the others.
- Publishing goes through a **queue**: you can leave the screen; it continues and stays visible in the [History](app:/history).
- If someone changes the repository during publishing, nothing is overwritten: the app either rebuilds the commit (different files) or stops without publishing anything.
- A photo with a **GPS position** published to a public repository is flagged. Consider [optimizing](help:optimiser-organiser) your images first.
- Files larger than 50 MiB go through [Git LFS](help:git-lfs).

## After a network cut

When the connection drops, the app retries twice by itself. Otherwise resume from the [History](help:historique-reprise): only the missing files are sent.
