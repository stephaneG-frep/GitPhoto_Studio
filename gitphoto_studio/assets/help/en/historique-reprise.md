# History and resuming

The [History](app:/history) lists every publication: date, repository and branch, files, message, commit, status, any errors and a link to GitHub. Tap a row for the file-by-file details.

## Statuses

- **Queued**: confirmed, waiting for its turn (or for a GitHub connection).
- **Running**: sending, with progress.
- **Succeeded**: commit created and verified.
- **Failed**: an error stopped it; the message explains why.
- **Interrupted**: the app was closed while sending; the outcome is unknown.
- **Cancelled**: you stopped it.

## Resume

**Resume** first re-reads the repository on GitHub:
- a file already published is **never sent again**;
- a file already transferred but not yet committed is not transferred again;
- if a target file was changed by someone else in the meantime, nothing is published.

After a lost connection, the app retries twice by itself (after 5 s, then 30 s) before letting you resume.

## Cancel

**Cancel** stops a queued or running publication, between two files. What is already on GitHub is not removed, and nothing is ever half-published: the commit is only created at the end.

> The queue runs while the app is open. If you close it, publishing resumes at the next launch.
