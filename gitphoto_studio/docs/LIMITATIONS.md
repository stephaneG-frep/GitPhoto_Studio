# Limitations connues

## Après la phase 8

- Le modèle d'IA peut encore, rarement, répondre en texte au lieu de
  proposer un plan : l'application le lui rappelle une fois, puis affiche
  sa réponse telle quelle (aucune action n'est alors possible sans plan).
- Le fichier `android/build/reports/problems/problems-report.html` reste
  dans le dépôt GitHub du projet tant que le propriétaire ne l'a pas
  retiré (ignoré pour l'avenir).
- `desktop_drop` 0.9 (version majeure) non adoptée.

## Après la phase 7

- Mode d'emploi en français et en anglais seulement, sans captures d'écran.
- Journal technique limité à la session en cours.
- `.deb`, signature de livraison et ZIP : phase 9.

## Après la phase 6

- Dialogue réel vérifié avec Mistral (`mistral-small-latest`) sous Linux ;
  la qualité des réponses dépend du modèle et peut varier d'une fois à
  l'autre.
- OpenAI, Anthropic, Gemini et Ollama : adaptateurs testés uniquement
  contre un serveur simulé (signalé dans les paramètres).
- Le modèle ne voit que des métadonnées : il ne peut pas juger le contenu
  d'une image (« la plus belle photo », « photos floues »…). La vision n'est
  pas utilisée, pour qu'aucun média ne quitte l'appareil.
- Actions possibles : albums, rangement par date, optimisation, conversion,
  publication. Pas de suppression, pas de remplacement de fichier distant,
  pas de renommage, pas de création de dépôt par l'agent (ces opérations
  restent dans les écrans classiques).
- Les réponses du modèle ne sont pas affichées au fil de l'eau (réponse
  complète à la fin).
- Qualité des plans dépendante du modèle choisi ; un modèle sans appels
  d'outils ne peut que converser.
- Ollama sur Android : « localhost » désigne le téléphone ; indiquer
  l'adresse de l'ordinateur du réseau local.

## Après la phase 5

- Reprise **fichier par fichier** : un fichier interrompu est renvoyé en
  entier (le transfert HTTP « basic » ne reprend pas au milieu).
- La file s'exécute tant que l'application est ouverte (pas de service
  d'arrière-plan Android).
- Git natif : Linux uniquement, sans LFS (les gros fichiers passent par LFS
  en HTTP) et pas pour un dépôt vide.
- Git LFS : quota de stockage du compte GitHub ; objets non supprimables
  sans supprimer le dépôt ; 2 Gio max par fichier (compte gratuit).
- Fichiers ordinaires envoyés en mémoire par l'API (≤ 50 Mio grâce au
  passage automatique à LFS au-delà).

## Après la phase 4

- **Vidéo sous Linux** : conversion, miniatures et durées par ffmpeg (à
  installer : `sudo apt install ffmpeg`, vérifié avec 4.4.2). La lecture
  vidéo intégrée reste indisponible sous Linux (pas de moteur officiel) :
  ouverture par le lecteur du système.
- **Débit vidéo** : les encodeurs matériels Android peuvent ignorer une
  consigne de débit basse (plancher propre à l'appareil). Une version non
  allégée est refusée plutôt que conservée.
- Optimisation d'image : sorties JPEG et PNG (pas de WebP/AVIF en écriture).
- Un média appartient à un seul album.
- Doublons probables : comparaison par paires, adaptée à quelques milliers de
  médias ; images très retouchées non détectées.

## Après la phase 3

- Publication réelle vérifiée sous Linux sur le dépôt de test ; pas encore
  depuis l'application Android avec un vrai compte (accès réseau vérifié).
- Device Flow : nécessite un Client ID d'application OAuth/GitHub App à
  créer par le propriétaire ; non testé de bout en bout.
- Paquet `.deb` (phase 9) : dépendance d'exécution `libsecret-1-0` et un
  service de secrets actif.

## Après la phase 2

- **HEIC sous Linux** : importé et conservé, mais sans miniature ni aperçu
  (non décodable par le moteur sur cette plateforme).
- **Espace disque** : l'import copie chaque média dans la bibliothèque du
  studio (garantie sur les originaux). Les vidéos volumineuses occupent donc
  deux fois leur taille tant qu'elles restent dans le studio.
- EXIF lu uniquement pour le JPEG.
- Permissions Android ajoutées par `video_player` : `ACCESS_NETWORK_STATE`
  et `WAKE_LOCK` (permissions normales, sans demande ni accès aux données).
- `desktop_drop` 0.8.4 déclenche un avertissement de compatibilité Gradle
  (Kotlin Gradle Plugin) : une future version de Flutter pourrait refuser de
  compiler ; la version 0.9 n'est pas encore compatible avec les autres
  dépendances.

## Après la phase 1

- Éditeur, GitHub, publication, agent IA, historique et mode d'emploi
  sont des écrans d'information : ils annoncent la phase prévue et ne
  proposent aucune action.
- Seuils de taille du sélecteur de transport (50 / 100 Mio) : valeurs
  documentées par GitHub pour les fichiers ordinaires, à revérifier en
  phases 3 et 5.
- Git LFS n'est pas installé sur la machine de développement.
- Icône d'application : icône Flutter par défaut (phase 9).
