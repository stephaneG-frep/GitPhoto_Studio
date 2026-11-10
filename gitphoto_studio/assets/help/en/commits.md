# Commits

A **commit** is a snapshot of your repository at a given moment: it records which files were added or changed, by whom, when, with a message describing the change.

## Why it matters

- Nothing is lost: every previous version stays available in GitHub's history.
- You know what changed and when.
- Each commit has a unique identifier (40 characters, often shortened to 7, for example `e6358d7`).

## In GitPhoto Studio

- One publication = **one commit**, even with a hundred files. Exception: an empty repository first receives an initialization commit.
- You write the **commit message** at the **Message** step; a default message is suggested.
- After sending, the app **verifies** on GitHub that each file is present with the expected content.
- The commit's identifier and link appear in the result and in the [History](app:/history).

## Replacing a file

If you choose to replace an existing file, the old version is not destroyed: it stays in the Git history, available on GitHub.

See also: [Branches](help:branches).
