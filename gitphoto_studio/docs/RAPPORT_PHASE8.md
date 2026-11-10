# Rapport — Phase 8 (qualité)

Date : 2026-11-10

## Sécurité

- **Dépôt GitHub du projet** (publié par le propriétaire) audité : aucun
  jeton, aucune clé, aucun fichier de signature ; le vrai jeton GitHub et la
  vraie clé Mistral ont été recherchés (comparaison sans affichage) : absents
  du dépôt publié comme des fichiers locaux. Seules des valeurs fictives de
  test sont présentes.
- Un fichier de compilation était versionné par erreur :
  `android/build/reports/problems/problems-report.html` (rapport Gradle avec
  des chemins locaux, sans secret). `android/build/` est désormais ignoré ;
  le retrait du fichier déjà publié est laissé au propriétaire (commande
  dans le rapport final).
- **Sauvegarde Android désactivée** (`allowBackup=false`, règles
  d'extraction Android 12+) : ni la base locale ni le trousseau chiffré ne
  partent dans la sauvegarde cloud ou un transfert d'appareil. Vérifié dans
  l'APK produit.
- **Liens ouverts limités à `https`** (`isOpenableUrl`) : aucun schéma
  `file:`, `intent:`, `javascript:`…
- **HTTP non chiffré mesuré sur le téléphone** (sonde temporaire, supprimée) :
  le client réseau de Dart l'accepte sous Android. Sans risque pour les clés :
  seuls Ollama (sans clé, adresse saisie par l'utilisateur) peut utiliser
  HTTP ; GitHub et les fournisseurs à clé ont des adresses HTTPS fixes. L'aide
  sur Ollama (adresse `http://` du réseau local) est donc exacte.
- Client Git LFS : une réponse illisible n'est plus présentée comme une
  « panne réseau » (le code HTTP est conservé).

## Analyse statique

- Inférence stricte et 15 règles supplémentaires (futures non attendues,
  appels dynamiques, flux non fermés, erreurs ignorées…) : 6 constats
  corrigés, aucun restant. Formatage vérifié (`dart format`).

## Tests

- **354 tests réussis** (299 en phase 7). Couverture : **83,7 %** du code de
  l'application (fichiers de traduction générés exclus). Les parties qui
  dépendent du matériel (lecteur vidéo, trousseau réel, sélecteur de
  fichiers, conversion native) sont couvertes par les tests sur appareil.
- Ajouts : messages d'erreur (100 %, français et anglais), outils de l'agent
  (91 %), erreurs du client LFS (90 %), conversion vidéo de l'exécuteur,
  filtre des liens, migration, performance, accessibilité, rappel du plan.

## Accessibilité

- Contrôles officiels de Flutter (contraste, cibles tactiles de 48 dp,
  libellés) sur les 9 écrans en thème clair et sombre, et sur des écrans
  remplis (galerie, paramètres IA, rubrique d'aide, plan de l'agent) ;
  texte agrandi à 200 % sur chaque écran.
- Corrigés : bouton de tri de la galerie (44 → 48 px), bouton
  « afficher/masquer le jeton » sans libellé, ligne « Dépôt actif » qui
  débordait avec un texte agrandi.

## Performance (5 000 médias, 50 albums)

- Galerie : tri par date 116–190 ms, par nom 87 ms, filtres et recherche
  < 20 ms ; Accueil 49–62 ms ; parcours guidé 94–115 ms.
- Agent : recherche de 200 médias **318 → 104 ms** (albums lus une seule fois).
- **Défaut corrigé** : une recherche volumineuse dépassait la taille d'un
  résultat et était coupée au milieu du JSON (inexploitable par le modèle) ;
  elle est maintenant raccourcie par éléments entiers avec la consigne de
  poursuivre (`offset`).

## Parcours complets réels

Sur le dépôt de test autorisé `test-gitphoto` (dossier `gitphoto-tests/`) :

- Git LFS en **lecture seule** : objet de la phase 5 reconnu par GitHub,
  objet inexistant refusé ✔ (aucun nouvel objet LFS créé).
- Parcours classique avec les vrais services : import d'une photo avec
  GPS → optimisation réelle (copie plus légère, sans GPS) → analyse →
  publication par la file → contenu vérifié sur GitHub → historique →
  republication sans doublon ✔ (commits `34302c6`, `0d558c6`).
- **Parcours IA de bout en bout** (Mistral réel + GitHub réel) : sélection
  d'une photo, demande en français, plan proposé et validé, confirmation,
  publication vérifiée ✔ **3 fois sur 3** (`ed83030`, `eeb1fd1`, `62ed845`).
- **Défaut réel trouvé** : Mistral a d'abord écrit le plan en texte
  (« Confirmez-vous ? ») sans appeler `propose_plan` — aucun bouton
  n'aurait permis de le valider. Corrigé : consigne renforcée et rappel
  automatique unique quand le texte annonce un plan.
- Non-régression réelle : tests GitHub (phase 3) et Mistral (phase 6) ✔.

## Dépendances

- Mises à jour mineures compatibles appliquées (Riverpod 3.5.0, go_router
  18.1.4, sqlite3 3.9.1, …) ; suite complète, tests d'intégration Linux
  (base réelle, galerie), builds et test sur téléphone repassés.
- Non appliqué : `desktop_drop` 0.9 (version majeure, à évaluer).

## Plateformes

- Linux release ✔ ; APK ARM64 25,5 Mo ✔, installé par mise à jour sur le
  téléphone, lancé sans erreur, données conservées ; test de l'agent sur
  le téléphone ✔.
