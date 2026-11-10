# Publier une photo

L'assistant de [Publication](app:/publish) vous montre **exactement** ce qui sera envoyé avant de toucher à GitHub.

## Les étapes

1. **Médias** : cochez les photos ou vidéos à publier.
2. **Destination** : dépôt, branche et dossier (par exemple `photos/2024`). Un dossier inexistant est créé automatiquement ; laissez vide pour la racine.
3. **Analyse** : l'application compare vos fichiers avec le dépôt :
   - **Nouveau** : le fichier sera ajouté ;
   - **Identique sur GitHub — ignoré** : il est déjà publié, rien n'est renvoyé ;
   - **Nom déjà pris — publié sous un autre nom** : un fichier différent porte ce nom ; le vôtre est renommé pour ne rien écraser. Cochez **Remplacer plutôt que renommer** seulement si vous voulez vraiment remplacer l'ancien.
4. **Message** : la phrase qui décrit la publication dans l'historique de GitHub (le *message de commit*).
5. **Vérification** : la liste finale ; puis **Publier sur GitHub** et une confirmation.
6. **Résultat** : le commit créé, vérifié sur GitHub, avec un lien pour l'ouvrir.

## Ce qu'il faut savoir

- Tous les fichiers partent en **un seul commit**. Pour un dépôt vide, un premier commit l'initialise avec un fichier, puis un second regroupe les autres.
- La publication passe par une **file d'attente** : vous pouvez quitter l'écran, elle continue et reste visible dans l'[Historique](app:/history).
- Si quelqu'un modifie le dépôt pendant la publication, rien n'est écrasé : soit l'application reconstruit le commit (fichiers différents), soit elle s'arrête sans rien publier.
- Une photo contenant une **position GPS** publiée dans un dépôt public est signalée. Pensez à [optimiser](help:optimiser-organiser) vos images avant.
- Les fichiers de plus de 50 Mio passent par [Git LFS](help:git-lfs).

## Après une coupure

En cas de perte de connexion, l'application réessaie seule deux fois. Sinon, reprenez la publication depuis l'[Historique](help:historique-reprise) : seuls les fichiers manquants seront envoyés.
