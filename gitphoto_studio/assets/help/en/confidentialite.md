# Privacy and security

## What stays on your device

- Working copies of your media and their thumbnails, in the app's private folder.
- The local database: library, albums, history, preferences, and conversations with the agent **only if you allow it**.
- Your original files are never changed.

## Tokens and keys

- The GitHub token and AI keys are kept **only** in the system's secure keychain.
- They are never written to the database, the logs, the settings export or the diagnostic report.
- They are never sent to the AI model.

## GPS position

Many photos contain the place where they were taken. The app:
- shows it in the media information (**GPS location: Present**);
- warns you before publishing to a public repository;
- always removes it from optimized versions.

## AI agent

- Off by default; explicit consent is required before the first request.
- Only text information is sent: your message, file names, sizes, dates, albums, whether a GPS position **exists** (never the position), your repository names and the publishing history.
- **No image or video is sent.**
- With Ollama running locally, nothing leaves your network.

## Never done without you

No publication, remote deletion or file replacement happens without your confirmation. A public repository is never created without a second confirmation.

## Erasing your data

- Remove media: Gallery › selection › **Remove from library**.
- Disconnect GitHub: GitHub screen › **Sign out** (then revoke the token on GitHub).
- AI key: **Settings › AI providers › Delete key**; conversations: **Erase saved conversations**.
- Erase everything: uninstall the app.
