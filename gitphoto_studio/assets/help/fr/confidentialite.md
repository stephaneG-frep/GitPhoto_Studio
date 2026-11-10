# Confidentialité et sécurité

## Ce qui reste sur votre appareil

- Les copies de travail de vos médias et leurs miniatures, dans le dossier privé de l'application.
- La base locale : bibliothèque, albums, historique, préférences, et conversations avec l'agent **seulement si vous l'autorisez**.
- Vos fichiers d'origine ne sont jamais modifiés.

## Jetons et clés

- Le jeton GitHub et les clés d'IA sont gardés **uniquement** dans le trousseau sécurisé du système.
- Ils ne sont jamais écrits dans la base, dans les journaux, dans l'export des paramètres ni dans le rapport de diagnostic.
- Ils ne sont jamais transmis au modèle d'IA.

## Position GPS

Beaucoup de photos contiennent l'endroit où elles ont été prises. L'application :
- l'indique dans les informations du média (**Position GPS : Présente**) ;
- vous avertit avant une publication dans un dépôt public ;
- la retire toujours des versions optimisées.

## Agent IA

- Désactivé par défaut ; un accord explicite est demandé avant le premier envoi.
- Seules des informations textuelles sont transmises : votre message, des noms de fichiers, tailles, dates, albums, la **présence** d'une position GPS (jamais la position), les noms de vos dépôts et l'historique des publications.
- **Aucune image ni vidéo n'est envoyée.**
- Avec Ollama en local, rien ne quitte votre réseau.

## Ce qui n'est jamais fait sans vous

Aucune publication, aucune suppression distante, aucun remplacement de fichier n'a lieu sans votre confirmation. Un dépôt public n'est jamais créé sans une seconde confirmation.

## Effacer vos données

- Retirer des médias : Galerie › sélection › **Retirer de la bibliothèque**.
- Déconnecter GitHub : écran GitHub › **Se déconnecter** (puis révoquez le jeton sur GitHub).
- Clé IA : **Paramètres › Fournisseurs IA › Supprimer la clé** ; conversations : **Effacer les conversations enregistrées**.
- Tout effacer : désinstallez l'application.
