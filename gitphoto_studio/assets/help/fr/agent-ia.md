# Utiliser l'agent IA

L'agent comprend des demandes en langage courant et prépare un **plan** que vous validez. Il est **désactivé par défaut** : toute l'application fonctionne sans lui.

## Activer l'agent

1. **Paramètres › Fournisseurs IA** › **Activer l'assistant IA**.
2. Choisissez un fournisseur (Mistral est recommandé), enregistrez votre clé, choisissez un modèle et touchez **Tester la connexion**. Voir [Fournisseurs IA](help:fournisseurs-ia).
3. Ouvrez l'[Agent IA](app:/agent) et acceptez l'envoi des métadonnées.

## Exemples de demandes

- « Publie les photos sélectionnées dans mon dépôt Portfolio. »
- « Classe mes images dans des albums par année et par mois. »
- « Réduis la taille des photos sans trop perdre en qualité. »
- « Prépare un album de voyage et génère un README. »
- « Explique pourquoi ma dernière publication a échoué. »
- « Trouve les doublons avant la publication. »
- « Quelles vidéos passeront par Git LFS ? »

« Ces photos » désigne la **sélection** de la galerie.

## Comment il travaille

1. Il **consulte** les informations utiles : sélection, bibliothèque, albums, doublons, état GitHub, historique, aperçu d'une publication. Ces consultations ne modifient rien ; elles sont indiquées sous sa réponse.
2. Pour agir, il **propose un plan** : une liste d'étapes numérotées, avec les avertissements calculés par l'application (position GPS, dépôt public…).
3. Vous touchez **Exécuter le plan** puis confirmez, ou **Refuser**.
4. L'application exécute les étapes une par une, vérifie chaque résultat et affiche le compte rendu. Vous pouvez **Arrêter** entre deux fichiers.

## Ce qu'il peut faire (et rien d'autre)

- ranger des médias dans un album, ou par année / mois ;
- créer des versions optimisées d'images ;
- créer des versions converties de vidéos ;
- publier sur GitHub en un commit, avec un README facultatif.

Il **ne peut pas** supprimer, remplacer un fichier existant, exécuter une commande ou accéder à vos autres fichiers. L'application vérifie chaque plan : un média ou un dépôt inventé, un dossier dangereux ou une branche invalide sont refusés.

## Bon à savoir

- Un plan non confirmé devient caduc dès que vous envoyez une nouvelle demande.
- L'agent ne voit **pas** le contenu de vos images, seulement leurs informations (nom, taille, dates…). Il ne peut donc pas choisir « les plus belles photos ».
- Les conversations ne sont enregistrées que si vous l'autorisez dans les paramètres.
