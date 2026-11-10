# Rapport — Phase 7 (documentation)

Date : 2026-11-09

## Fonctionnalités livrées

- **Mode d'emploi intégré, hors ligne** : 16 rubriques en français et en
  anglais (`assets/help/<langue>/*.md`), livrées avec l'application :
  premiers pas, connexion GitHub, création d'un dépôt, publication d'une
  photo, d'une vidéo, optimisation et albums, commits, branches, Git LFS,
  historique et reprise, agent IA, fournisseurs IA, erreurs, confidentialité,
  FAQ, glossaire. Rendu par un moteur Markdown minimal propre à
  l'application (titres, listes et sous-listes, encadrés, code, gras, liens),
  sans nouvelle dépendance. Liens vers d'autres rubriques, vers les écrans
  de l'application et vers le web.
- **Parcours guidé pour débutants** en tête du sommaire : 5 étapes
  obligatoires et 2 facultatives, **cochées d'après l'état réel** (média
  importé, session GitHub, dépôt actif, version optimisée, publication
  réussie, IA configurée), avec « Y aller » et « Lire l'aide ».
- **Recherche** dans tout le mode d'emploi (sans accents ni casse, tous les
  mots, titre prioritaire, extrait affiché).
- **Aide contextuelle** : bouton « ? » sur chaque écran (barre du haut sur
  téléphone, au-dessus du contenu sur grand écran) ouvrant la rubrique
  correspondante.
- **Diagnostic** (Paramètres) :
  - **rapport de diagnostic** copiable : version, plateforme, schéma, outils,
    compteurs, états GitHub et IA — sans jeton, clé, nom de compte, de dépôt
    ni de fichier ;
  - **journal technique** de la session consultable et copiable (secrets
    déjà masqués) ;
  - **export des paramètres non sensibles** (JSON) : copie, et
    enregistrement dans un fichier sur ordinateur ; liste blanche de
    préfixes, l'identifiant client OAuth est exclu.
- **Guides en fichiers** (`docs/`) : `MODE_EMPLOI.md`, `GUIDE_GITHUB.md`,
  `GUIDE_IA.md` **générés** depuis les rubriques intégrées par
  `scripts/generate_guides.py` (une seule source ; un test échoue s'ils
  divergent), et `GUIDE_INSTALLATION.md` rédigé à la main.
- Textes périmés corrigés dans l'assistant de publication (« un commit par
  fichier » pour un dépôt vide, « optimisation disponible en phase 4 »).
- Le dernier écran « en préparation » a disparu : les neuf écrans sont
  réels.

## Tests

- `flutter analyze` : aucun problème.
- `flutter test` : **299 tests réussis** (281 en phase 6), dont :
  - moteur Markdown (blocs, liens, sous-listes numérotées) ;
  - contenu livré : chaque rubrique existe dans les deux langues, commence
    par un titre, tous ses liens mènent à une rubrique ou un écran
    existant, aucune forme de jeton réaliste ; même structure en français
    et en anglais ; chaque écran a sa rubrique contextuelle ;
  - recherche ; export sans clé ni identifiant client ; rapport sans nom de
    compte, de dépôt ni de fichier ;
  - écrans : parcours guidé qui se coche après un import réel, recherche,
    ouverture d'une rubrique et lien interne, recherche sans résultat,
    bouton « ? » (téléphone et grand écran), rubrique inconnue, anglais,
    rapport et export copiés sans secret, journal ;
  - guides de `docs/` à jour.
- Libellés cités en gras dans l'aide vérifiés contre les textes réels de
  l'application (français et anglais) ; 9 libellés anglais corrigés.
- **Téléphone** (APK release installé par mise à jour, données conservées) :
  sommaire, parcours guidé reflétant l'état réel (4 sur 5), rubrique
  « Créer ou choisir un dépôt » affichée correctement.
- Build Linux release ✔ ; APK ARM64 25,5 Mo ✔.

## Défauts trouvés et corrigés

- Une sous-liste dans une liste numérotée cassait la numérotation (vu sur le
  téléphone) : sous-listes prises en charge, numéros conservés.
- Le cache des fichiers embarqués bloquait le chargement de l'aide d'un test
  à l'autre : cache désactivé (les rubriques sont déjà gardées en mémoire).
- Un remplacement automatique avait faussé un libellé anglais (« Signed in
  as ») : corrigé.

## Limites

- Mode d'emploi en français et en anglais uniquement.
- Pas de captures d'écran dans l'aide (texte seul).
- Le journal technique ne couvre que la session en cours (effacé à la
  fermeture).
- Guide d'installation : paquet `.deb`, signature de livraison et archive
  ZIP restent à produire et documenter en phase 9.
