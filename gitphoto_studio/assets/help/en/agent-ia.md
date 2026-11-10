# Using the AI agent

The agent understands everyday requests and prepares a **plan** that you approve. It is **off by default**: the whole app works without it.

## Turn the agent on

1. **Settings › AI providers** › **Turn on the AI assistant**.
2. Choose a provider (Mistral is recommended), save your key, choose a model and tap **Test connection**. See [AI providers](help:fournisseurs-ia).
3. Open the [AI agent](app:/agent) and accept sending metadata.

## Example requests

- "Publish the selected photos to my Portfolio repository."
- "Sort my images into albums by year and month."
- "Shrink the photos without losing much quality."
- "Prepare a travel album and write a README."
- "Explain why my last publication failed."
- "Find duplicates before publishing."
- "Which videos will go through Git LFS?"

"These photos" means the gallery **selection**.

## How it works

1. It **checks** useful information: selection, library, albums, duplicates, GitHub status, history, a publication preview. These checks change nothing; they are listed under its answer.
2. To act, it **proposes a plan**: numbered steps, with warnings computed by the app (GPS position, public repository…).
3. You tap **Run the plan** and confirm, or **Decline**.
4. The app runs the steps one by one, verifies each result and shows the report. You can **Stop** between two files.

## What it can do (and nothing else)

- move media into an album, or by year / month;
- create optimized versions of images;
- create converted versions of videos;
- publish to GitHub in one commit, with an optional README.

It **cannot** delete, replace an existing file, run a command or access your other files. The app checks every plan: an invented media item or repository, a dangerous folder or an invalid branch is rejected.

## Good to know

- An unconfirmed plan expires as soon as you send a new request.
- The agent does **not** see the content of your images, only their information (name, size, dates…). It cannot pick "the best photos".
- Conversations are saved only if you allow it in Settings.
