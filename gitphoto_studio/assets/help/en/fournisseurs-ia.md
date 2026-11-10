# AI providers and keys

The agent can use several providers. **Mistral** is the recommended one: it is the provider tested against the real service ("Tested against the real service" in Settings). The others are ready but were only tested against a simulated server.

## Setup

**Settings › AI providers**:
1. **Turn on the AI assistant**.
2. **Provider**: choose from the list.
3. **API key**: paste it, then **Save key**. It is kept in the system's secure keychain, never in the app's database, and the field is cleared at once.
4. **Model**: tap the list icon to load the available models; choose one that can use **tools** ("tools" label at Mistral).
5. **Test connection**.

## Getting a key

- **Mistral AI**: console.mistral.ai › **API Keys** › **Create new key**. Suggested model: `mistral-small-latest`.
- **OpenAI**: platform.openai.com › **API keys**.
- **Anthropic Claude**: console.anthropic.com › **API Keys**.
- **Google Gemini**: aistudio.google.com › **Get API key**.

The **Get a key** button opens the right page. These services are usually **pay-per-use**: check their pricing. Never share your key.

## Ollama (local, no key)

Ollama runs a model on your computer, without sending data over the Internet.

```
ollama pull llama3.1
ollama serve
```

- On Linux, the default address `http://localhost:11434/v1` works.
- On the phone, `localhost` is the phone itself: enter the computer's address on the local network (for example `http://192.168.1.20:11434/v1`) and start Ollama with `OLLAMA_HOST=0.0.0.0`.
- Choose a model that supports tools; otherwise the agent can only chat.

## Turning AI off

Untick **Turn on the AI assistant**. To erase the key: **Delete key**. To erase history: **Erase saved conversations**.

See also: [Privacy](help:confidentialite).
