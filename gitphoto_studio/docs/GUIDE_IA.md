# Guide des fournisseurs IA

> Document généré par `scripts/generate_guides.py` à partir du mode d'emploi intégré à l'application (Mode d'emploi). Ne pas modifier à la main : modifier `assets/help/fr/` puis relancer le script.

## Fournisseurs IA et clés

L'agent peut utiliser plusieurs fournisseurs. **Mistral** est le fournisseur recommandé : c'est celui qui a été testé avec le vrai service (indiqué « Testé avec le vrai service » dans les paramètres). Les autres sont prêts mais n'ont été testés qu'avec un serveur simulé.

### Configuration

**Paramètres › Fournisseurs IA** :
1. **Activer l'assistant IA**.
2. **Fournisseur** : choisissez dans la liste.
3. **Clé d'API** : collez-la puis **Enregistrer la clé**. Elle est gardée dans le trousseau sécurisé du système, jamais dans la base de l'application, et le champ est vidé aussitôt.
4. **Modèle** : touchez l'icône de liste pour charger les modèles disponibles ; choisissez un modèle qui sait utiliser des **outils** (mention « outils » chez Mistral).
5. **Tester la connexion**.

### Obtenir une clé

- **Mistral AI** : console.mistral.ai › **API Keys** › **Create new key**. Modèle conseillé : `mistral-small-latest`.
- **OpenAI** : platform.openai.com › **API keys**.
- **Anthropic Claude** : console.anthropic.com › **API Keys**.
- **Google Gemini** : aistudio.google.com › **Get API key**.

Le bouton **Obtenir une clé** ouvre la bonne page. Ces services sont généralement **payants à l'usage** : consultez leurs tarifs. Ne partagez jamais votre clé.

### Ollama (local, sans clé)

Ollama fait tourner un modèle sur votre ordinateur, sans envoyer de données sur Internet.

```
ollama pull llama3.1
ollama serve
```

- Sous Linux, l'adresse par défaut `http://localhost:11434/v1` convient.
- Sur le téléphone, `localhost` désigne le téléphone lui-même : indiquez l'adresse de l'ordinateur sur le réseau local (par exemple `http://192.168.1.20:11434/v1`) et lancez Ollama avec `OLLAMA_HOST=0.0.0.0`.
- Choisissez un modèle qui gère les outils ; sinon l'agent ne pourra que converser.

### Désactiver l'IA

Décochez **Activer l'assistant IA**. Pour effacer la clé : **Supprimer la clé**. Pour effacer l'historique : **Effacer les conversations enregistrées**.

Voir aussi : Confidentialité.

## Utiliser l'agent IA

L'agent comprend des demandes en langage courant et prépare un **plan** que vous validez. Il est **désactivé par défaut** : toute l'application fonctionne sans lui.

### Activer l'agent

1. **Paramètres › Fournisseurs IA** › **Activer l'assistant IA**.
2. Choisissez un fournisseur (Mistral est recommandé), enregistrez votre clé, choisissez un modèle et touchez **Tester la connexion**. Voir Fournisseurs IA.
3. Ouvrez l'Agent IA et acceptez l'envoi des métadonnées.

### Exemples de demandes

- « Publie les photos sélectionnées dans mon dépôt Portfolio. »
- « Classe mes images dans des albums par année et par mois. »
- « Réduis la taille des photos sans trop perdre en qualité. »
- « Prépare un album de voyage et génère un README. »
- « Explique pourquoi ma dernière publication a échoué. »
- « Trouve les doublons avant la publication. »
- « Quelles vidéos passeront par Git LFS ? »

« Ces photos » désigne la **sélection** de la galerie.

### Comment il travaille

1. Il **consulte** les informations utiles : sélection, bibliothèque, albums, doublons, état GitHub, historique, aperçu d'une publication. Ces consultations ne modifient rien ; elles sont indiquées sous sa réponse.
2. Pour agir, il **propose un plan** : une liste d'étapes numérotées, avec les avertissements calculés par l'application (position GPS, dépôt public…).
3. Vous touchez **Exécuter le plan** puis confirmez, ou **Refuser**.
4. L'application exécute les étapes une par une, vérifie chaque résultat et affiche le compte rendu. Vous pouvez **Arrêter** entre deux fichiers.

### Ce qu'il peut faire (et rien d'autre)

- ranger des médias dans un album, ou par année / mois ;
- créer des versions optimisées d'images ;
- créer des versions converties de vidéos ;
- publier sur GitHub en un commit, avec un README facultatif.

Il **ne peut pas** supprimer, remplacer un fichier existant, exécuter une commande ou accéder à vos autres fichiers. L'application vérifie chaque plan : un média ou un dépôt inventé, un dossier dangereux ou une branche invalide sont refusés.

### Bon à savoir

- Un plan non confirmé devient caduc dès que vous envoyez une nouvelle demande.
- L'agent ne voit **pas** le contenu de vos images, seulement leurs informations (nom, taille, dates…). Il ne peut donc pas choisir « les plus belles photos ».
- Les conversations ne sont enregistrées que si vous l'autorisez dans les paramètres.

## Confidentialité et sécurité

### Ce qui reste sur votre appareil

- Les copies de travail de vos médias et leurs miniatures, dans le dossier privé de l'application.
- La base locale : bibliothèque, albums, historique, préférences, et conversations avec l'agent **seulement si vous l'autorisez**.
- Vos fichiers d'origine ne sont jamais modifiés.

### Jetons et clés

- Le jeton GitHub et les clés d'IA sont gardés **uniquement** dans le trousseau sécurisé du système.
- Ils ne sont jamais écrits dans la base, dans les journaux, dans l'export des paramètres ni dans le rapport de diagnostic.
- Ils ne sont jamais transmis au modèle d'IA.

### Position GPS

Beaucoup de photos contiennent l'endroit où elles ont été prises. L'application :
- l'indique dans les informations du média (**Position GPS : Présente**) ;
- vous avertit avant une publication dans un dépôt public ;
- la retire toujours des versions optimisées.

### Agent IA

- Désactivé par défaut ; un accord explicite est demandé avant le premier envoi.
- Seules des informations textuelles sont transmises : votre message, des noms de fichiers, tailles, dates, albums, la **présence** d'une position GPS (jamais la position), les noms de vos dépôts et l'historique des publications.
- **Aucune image ni vidéo n'est envoyée.**
- Avec Ollama en local, rien ne quitte votre réseau.

### Ce qui n'est jamais fait sans vous

Aucune publication, aucune suppression distante, aucun remplacement de fichier n'a lieu sans votre confirmation. Un dépôt public n'est jamais créé sans une seconde confirmation.

### Effacer vos données

- Retirer des médias : Galerie › sélection › **Retirer de la bibliothèque**.
- Déconnecter GitHub : écran GitHub › **Se déconnecter** (puis révoquez le jeton sur GitHub).
- Clé IA : **Paramètres › Fournisseurs IA › Supprimer la clé** ; conversations : **Effacer les conversations enregistrées**.
- Tout effacer : désinstallez l'application.
