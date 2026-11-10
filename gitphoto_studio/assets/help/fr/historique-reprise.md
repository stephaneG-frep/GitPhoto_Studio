# Historique et reprise

L'[Historique](app:/history) liste chaque publication : date, dépôt et branche, fichiers, message, commit, statut, erreurs éventuelles et lien vers GitHub. Touchez une ligne pour voir le détail fichier par fichier.

## Statuts

- **En file d'attente** : confirmée, elle attend son tour (ou une connexion à GitHub).
- **En cours** : envoi en cours, avec la progression.
- **Réussie** : commit créé et vérifié.
- **Échouée** : une erreur l'a arrêtée ; le message explique pourquoi.
- **Interrompue** : l'application a été fermée pendant l'envoi ; le résultat est inconnu.
- **Annulée** : vous l'avez arrêtée.

## Reprendre

**Reprendre** relit d'abord le dépôt sur GitHub :
- un fichier déjà publié n'est **jamais renvoyé** ;
- un fichier déjà transmis mais pas encore validé n'est pas retransmis ;
- si un fichier visé a été modifié par quelqu'un d'autre entre-temps, rien n'est publié.

Après une perte de connexion, l'application réessaie seule deux fois (après 5 s puis 30 s) avant de vous laisser reprendre.

## Annuler

**Annuler** arrête une publication en attente ou en cours, entre deux fichiers. Ce qui est déjà sur GitHub n'est pas retiré, et rien n'est jamais publié à moitié : le commit n'est créé qu'à la fin.

> La file fonctionne tant que l'application est ouverte. Si vous la fermez, la publication reprendra au prochain lancement.
