# Signing in to GitHub

To publish, the app needs an **access token**: a kind of limited password that you create on GitHub and can revoke at any time.

> The token is checked with GitHub, then kept **only** in the system's secure keychain (Keystore on Android, GNOME Keyring or KWallet on Linux). It is never written to the app's database or logs.

## Create a fine-grained token (recommended)

1. On GitHub, open your profile picture › **Settings** › **Developer settings** › **Personal access tokens** › **Fine-grained tokens**, then **Generate new token**. The **Create a token on GitHub** button on the GitHub screen goes straight there.
2. Give it a name (for example "GitPhoto") and an expiration date.
3. **Repository access**: choose **Only select repositories** and tick only your photo repositories.
4. **Permissions** › **Repository permissions** › **Contents**: **Read and write**. **Metadata** (read) is added automatically.
5. Optional: to create repositories from the app, add **Administration**: **Read and write**.
6. Click **Generate token** and copy it (it will not be shown again).

## Sign in

1. Open the [GitHub](app:/github) screen.
2. Paste the token into **GitHub token** and tap **Verify and connect**.
3. The screen shows "Signed in as …", your repositories and, when GitHub provides them, the token's scopes and expiration date.

Never share your token, not even with an assistant or an AI.

## Browser sign-in

If you have an OAuth app or GitHub App with **Device Flow** enabled, enter its **Client ID** then **Sign in with the browser**: a code appears, to type on the GitHub page that opens. No secret is needed.

## Sign out

**Sign out** erases the token from this device. To invalidate it for good, also delete it on GitHub (**Manage my tokens on GitHub**).

## Common problems

- **"GitHub rejects the token"**: badly copied, expired or revoked. Create a new one.
- **"Insufficient permission"**: the repository is not ticked in the token, or **Contents** is not read and write.
- **"The system's secure keyring is unavailable"** (Linux): start and unlock GNOME Keyring or KWallet, then restart the app.

See also: [Understanding errors](help:erreurs).
