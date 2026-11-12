# Rapport de validation — GitPhoto Studio IA 1.0.0

Date : 2026-11-11. Référence : `SPEC.md`, sections 11 (livrables) et 13
(critères d'acceptation). Détail des tests : [RAPPORT_TESTS.md](RAPPORT_TESTS.md).

## Critères d'acceptation

| Critère | Statut | Preuve |
|---|---|---|
| Démarre sans erreur sur les plateformes testées | ✔ | Linux (version compilée et paquet), Android (APK 1.0.0 sur MTN NX1M) |
| Sélection et prévisualisation des médias | ✔ | tests de galerie, test d'intégration Linux |
| Connexion à GitHub | ✔ | test réel (jeton fine-grained), trousseau du système |
| Choix d'un dépôt et d'une branche | ✔ | tests d'écran, parcours réel |
| Publication d'un fichier et vérification du commit distant | ✔ | parcours réels (commits vérifiés sur GitHub) |
| Consultation de l'historique | ✔ | tests d'écran, parcours réel |
| L'agent IA prépare un plan et demande validation | ✔ | test réel Mistral, parcours IA réel 3/3 |
| Identifiants protégés | ✔ | trousseau uniquement, absents de la base, des journaux, des exports et des archives (vérifié) |
| Erreurs compréhensibles | ✔ | chaque type d'erreur testé, en français et en anglais |
| Mode d'emploi utilisable | ✔ | 16 rubriques hors ligne, parcours guidé, recherche, aide contextuelle |
| Fonctionnalités annoncées testées | ✔ | tests automatisés et réels ; limites listées dans LIMITATIONS.md |
| APK, DEB et ZIP générés et vérifiés | ✔ | voir ci-dessous |

## Livrables

### Android
| Élément | Statut |
|---|---|
| APK ARM64 release (`gitphoto-studio-1.0.0-arm64.apk`, 25,4 Mo, ARM64 seul) | ✔ |
| Nom « GitPhoto Studio IA », version 1.0.0 (code 2) | ✔ |
| Icône originale (mascotte Pixel, icône adaptative) | ✔ |
| Permissions minimales (Internet ; 2 permissions techniques du lecteur vidéo) | ✔ |
| Signature documentée : clé de développement, **choix du propriétaire** (application personnelle) | ✔ |
| Procédure d'installation | ✔ GUIDE_INSTALLATION.md |

### Linux
| Élément | Statut |
|---|---|
| Version release | ✔ |
| Paquet `gitphoto-studio_1.0.0_amd64.deb` (fichiers root, droits normalisés) | ✔ |
| Fichier `.desktop` (validé par `desktop-file-validate`) | ✔ |
| Icône (thème hicolor, 48 à 512 px) | ✔ |
| Dépendances déclarées (relevées sur les bibliothèques réellement liées) | ✔ |
| Installation et désinstallation testées | ✔ 2026-11-12 par le propriétaire (`apt install` puis `apt remove`) ; journaux dpkg/apt vérifiés : installé sans erreur, puis retiré sans reste (`/opt`, commande, menu, icônes) |

### Code et documentation
| Élément | Statut |
|---|---|
| Projet Flutter complet | ✔ |
| Archive ZIP du code source (sans compilation, ancien code ni livrables) | ✔ |
| README, guide d'installation, mode d'emploi, guide GitHub, guide des fournisseurs IA | ✔ |
| Rapport de tests, journal des limitations | ✔ |
| Licence (« Tous droits réservés », choix du propriétaire) | ✔ LICENSE |
| Aucun secret, fichier de signature privé ni identifiant personnel dans les archives | ✔ vérifié (jeton et clé réels comparés sans affichage) |

## Réserves

- Signature de développement : convient à un usage personnel, pas à une
  diffusion publique (procédure de clé de livraison documentée).
- Fournisseurs IA autres que Mistral non testés contre leurs vrais services.
- Voir [LIMITATIONS.md](LIMITATIONS.md).
