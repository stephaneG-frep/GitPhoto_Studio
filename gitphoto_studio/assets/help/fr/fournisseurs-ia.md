# Fournisseurs IA et clés

L'agent peut utiliser plusieurs fournisseurs. **Mistral** est le fournisseur recommandé : c'est celui qui a été testé avec le vrai service (indiqué « Testé avec le vrai service » dans les paramètres). Les autres sont prêts mais n'ont été testés qu'avec un serveur simulé.

## Configuration

**Paramètres › Fournisseurs IA** :
1. **Activer l'assistant IA**.
2. **Fournisseur** : choisissez dans la liste.
3. **Clé d'API** : collez-la puis **Enregistrer la clé**. Elle est gardée dans le trousseau sécurisé du système, jamais dans la base de l'application, et le champ est vidé aussitôt.
4. **Modèle** : touchez l'icône de liste pour charger les modèles disponibles ; choisissez un modèle qui sait utiliser des **outils** (mention « outils » chez Mistral).
5. **Tester la connexion**.

## Obtenir une clé

- **Mistral AI** : console.mistral.ai › **API Keys** › **Create new key**. Modèle conseillé : `mistral-small-latest`.
- **OpenAI** : platform.openai.com › **API keys**.
- **Anthropic Claude** : console.anthropic.com › **API Keys**.
- **Google Gemini** : aistudio.google.com › **Get API key**.

Le bouton **Obtenir une clé** ouvre la bonne page. Ces services sont généralement **payants à l'usage** : consultez leurs tarifs. Ne partagez jamais votre clé.

## Ollama (local, sans clé)

Ollama fait tourner un modèle sur votre ordinateur, sans envoyer de données sur Internet.

```
ollama pull llama3.1
ollama serve
```

- Sous Linux, l'adresse par défaut `http://localhost:11434/v1` convient.
- Sur le téléphone, `localhost` désigne le téléphone lui-même : indiquez l'adresse de l'ordinateur sur le réseau local (par exemple `http://192.168.1.20:11434/v1`) et lancez Ollama avec `OLLAMA_HOST=0.0.0.0`.
- Choisissez un modèle qui gère les outils ; sinon l'agent ne pourra que converser.

## Désactiver l'IA

Décochez **Activer l'assistant IA**. Pour effacer la clé : **Supprimer la clé**. Pour effacer l'historique : **Effacer les conversations enregistrées**.

Voir aussi : [Confidentialité](help:confidentialite).
