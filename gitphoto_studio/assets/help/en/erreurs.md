# Understanding errors

Each error is explained in plain words in the app. Here are the most common ones and what to do.

## GitHub

- **GitHub rejects the token**: invalid, expired or revoked token. Create a new one and sign in again ([Sign-in](help:connexion-github)).
- **Insufficient permission**: the repository is not included in your token, or **Contents** write (or **Administration** to create a repository) is missing. Edit the token on GitHub.
- **Not found**: the repository, branch or folder does not exist, or the token has no access to it.
- **GitHub request limit reached**: wait until the time shown, then resume.
- **The branch changed on GitHub during publishing** or **'…' changed on GitHub since the analysis**: someone changed the repository at the same time. Nothing was published; run the analysis again.
- **'…' is already waiting to be published**: the same publication is already queued; check the History.
- **Cannot reach GitHub**: check the Internet connection. The app retries twice by itself.
- **GitHub is having trouble (server error)**: try again later.

## Publishing

- **File name incompatible with a repository**: rename the media item in the Editor.
- **Over 100 MiB while Git LFS is disabled in settings**: turn Git LFS back on in Settings or lighten the file.
- **Over 2 GiB**: convert the video to a lighter version.
- **Published, but remote verification could not confirm every file**: the commit exists; open it on GitHub to check.
- **Interrupted**: the app was closed while sending. **Resume** skips what is already published.

## Video

- **Video conversion unavailable: ffmpeg is not installed** (Linux): `sudo apt install ffmpeg`, then **Settings › Diagnostics › Refresh**.
- **The conversion does not reduce the size**: the video is already compressed; try **Remove audio** or a lower preset.

## AI agent

- **API key rejected**: check or replace the key in Settings.
- **Too many requests or quota exhausted**: wait, or check your credit with the provider.
- **This model cannot use tools**: choose another model (for example `mistral-small-latest`).
- **Cannot reach the provider**: check the Internet connection, or the server address for Ollama.

## Keychain

- **The system's secure keyring is unavailable** (Linux): start and unlock GNOME Keyring or KWallet. Without it, no token or key can be stored.

## Asking for help

**Settings › Diagnostics › Copy the report** produces a technical summary with no token, key, account name or file name, to attach to your request. The **Technical log** details the session's events.
