# Les commits

Un **commit** est une photographie de votre dépôt à un instant donné : il enregistre quels fichiers ont été ajoutés ou modifiés, par qui, quand, avec un message qui décrit le changement.

## Pourquoi c'est utile

- Rien ne se perd : chaque version précédente reste consultable dans l'historique de GitHub.
- Vous savez ce qui a changé et quand.
- Chaque commit a un identifiant unique (une suite de 40 caractères, souvent abrégée en 7, par exemple `e6358d7`).

## Dans GitPhoto Studio

- Une publication = **un commit**, même avec cent fichiers. Exception : un dépôt vide reçoit d'abord un commit d'initialisation.
- Vous écrivez le **message de commit** à l'étape **Message** ; un message par défaut est proposé (« Ajout de 3 médias via GitPhoto Studio »).
- Après l'envoi, l'application **vérifie** sur GitHub que chaque fichier est bien présent avec le contenu attendu.
- L'identifiant et le lien du commit figurent dans le résultat et dans l'[Historique](app:/history).

## Remplacer un fichier

Si vous choisissez de remplacer un fichier existant, l'ancienne version n'est pas détruite : elle reste dans l'historique Git, accessible sur GitHub.

Voir aussi : [Les branches](help:branches).
