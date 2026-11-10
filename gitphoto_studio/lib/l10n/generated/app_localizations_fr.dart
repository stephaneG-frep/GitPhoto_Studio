// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'GitPhoto Studio IA';

  @override
  String get appTagline => 'L\'atelier des médias connectés';

  @override
  String get navDashboard => 'Accueil';

  @override
  String get navGallery => 'Galerie';

  @override
  String get navEditor => 'Éditeur';

  @override
  String get navGithub => 'GitHub';

  @override
  String get navPublish => 'Publication';

  @override
  String get navAgent => 'Agent IA';

  @override
  String get navHistory => 'Historique';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get navHelp => 'Mode d\'emploi';

  @override
  String get navMore => 'Plus';

  @override
  String get navMenu => 'Menu de navigation';

  @override
  String get commonLoading => 'Chargement…';

  @override
  String commonError(String message) {
    return 'Une erreur est survenue : $message';
  }

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get plannedTitle => 'En préparation';

  @override
  String plannedPhase(int phase, String phaseName) {
    return 'Prévu en phase $phase — $phaseName';
  }

  @override
  String get plannedHonesty =>
      'Aucune action n\'est proposée ici pour l\'instant : les commandes apparaîtront lorsque la fonctionnalité sera réellement implémentée et testée.';

  @override
  String get phaseAdvancedPublishing => 'Publications avancées';

  @override
  String get phaseAiAgent => 'Agent IA';

  @override
  String get phaseDocumentation => 'Documentation';

  @override
  String get agentIntro =>
      'Décrivez ce que vous voulez faire ; l\'agent propose un plan et attend votre validation avant d\'agir.';

  @override
  String get agentFeatures =>
      'Fournisseur prioritaire : Mistral (autres fournisseurs configurables)\nOutils typés et validés, aucun accès shell libre\nPlan d\'action présenté avant exécution\nConfirmation obligatoire\nAucun média envoyé à une IA sans votre accord';

  @override
  String get helpIntro =>
      'Mode d\'emploi complet, consultable hors ligne. Suivez le parcours guidé ou cherchez une question.';

  @override
  String get helpFeatures =>
      'Premiers pas et parcours guidé\nConnexion GitHub et création d\'un dépôt\nPublication d\'une photo ou d\'une vidéo\nCommits, branches et Git LFS\nUtilisation de l\'agent IA\nErreurs fréquentes, FAQ et glossaire';

  @override
  String get dashActiveRepo => 'Dépôt actif';

  @override
  String get dashNoRepo => 'Aucun dépôt connecté';

  @override
  String get dashLocalMedia => 'Médias locaux';

  @override
  String get dashPending => 'En attente';

  @override
  String get dashLocalStorage => 'Espace local';

  @override
  String get dashTransfers => 'Transferts';

  @override
  String get dashNoTransfers => 'Aucun transfert en cours';

  @override
  String get dashRecentCommits => 'Derniers commits';

  @override
  String get dashShortcuts => 'Raccourcis';

  @override
  String get pixelName => 'Pixel';

  @override
  String get pixelSemantics => 'Pixel, le robot assistant du studio';

  @override
  String get pixelWelcome =>
      'Bonjour ! Je suis Pixel. Importez vos médias dans la galerie, connectez GitHub, puis publiez-les en quelques étapes.';

  @override
  String get pixelSettingsHint =>
      'Les jetons et clés ne sont jamais enregistrés dans la base locale.';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsAiProviders => 'Fournisseurs IA';

  @override
  String get settingsAiProvidersNote =>
      'L\'application fonctionne entièrement sans IA.';

  @override
  String get aiProviderPriority => 'Prioritaire';

  @override
  String get aiProviderLocal => 'Local';

  @override
  String get aiNotConfigured => 'Non configuré';

  @override
  String get settingsDiagnostics => 'Diagnostic';

  @override
  String get diagPlatform => 'Plateforme';

  @override
  String get diagDatabase => 'Base de données';

  @override
  String diagSchemaVersion(int version) {
    return 'Schéma v$version';
  }

  @override
  String get diagGit => 'Git';

  @override
  String get diagGitLfs => 'Git LFS';

  @override
  String get diagNotFound => 'Non détecté';

  @override
  String get diagNotApplicable => 'Non applicable sur cette plateforme';

  @override
  String get settingsAbout => 'À propos';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonClose => 'Fermer';

  @override
  String get galleryImport => 'Importer';

  @override
  String get gallerySearchHint => 'Rechercher par nom';

  @override
  String get galleryFilterAll => 'Tous';

  @override
  String get galleryFilterImages => 'Photos';

  @override
  String get galleryFilterVideos => 'Vidéos';

  @override
  String get gallerySort => 'Trier';

  @override
  String get gallerySortDate => 'Date';

  @override
  String get gallerySortName => 'Nom';

  @override
  String get gallerySortType => 'Type';

  @override
  String get gallerySortSize => 'Taille';

  @override
  String get gallerySortAscending => 'Ordre croissant';

  @override
  String get gallerySortDescending => 'Ordre décroissant';

  @override
  String get galleryViewGrid => 'Affichage en grille';

  @override
  String get galleryViewList => 'Affichage en liste';

  @override
  String get galleryEmptyTitle => 'Votre bibliothèque est vide';

  @override
  String get galleryEmptyBody =>
      'Importez des photos et des vidéos : le studio en conserve une copie de travail, vos fichiers originaux restent intacts.';

  @override
  String get galleryEmptyDropHint =>
      'Vous pouvez aussi glisser-déposer des fichiers ou des dossiers dans cette fenêtre.';

  @override
  String get galleryNoResults => 'Aucun média ne correspond à ces critères.';

  @override
  String galleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count médias',
      one: '1 média',
      zero: 'Aucun média',
    );
    return '$_temp0';
  }

  @override
  String gallerySelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnés',
      one: '1 sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get gallerySelectAll => 'Tout sélectionner';

  @override
  String get galleryClearSelection => 'Annuler la sélection';

  @override
  String get galleryRemove => 'Retirer de la bibliothèque';

  @override
  String galleryRemoveTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Retirer ces $count médias ?',
      one: 'Retirer ce média ?',
    );
    return '$_temp0';
  }

  @override
  String get galleryRemoveBody =>
      'Les copies de travail et les miniatures du studio seront effacées. Vos fichiers originaux ne sont pas touchés.';

  @override
  String get galleryRemoveConfirm => 'Retirer';

  @override
  String galleryRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count médias retirés',
      one: '1 média retiré',
    );
    return '$_temp0';
  }

  @override
  String get galleryDropHere => 'Déposez vos fichiers pour les importer';

  @override
  String get galleryVideoBadge => 'Vidéo';

  @override
  String importProgress(int done, int total) {
    return 'Import en cours : $done sur $total';
  }

  @override
  String get importStop => 'Arrêter';

  @override
  String importSummary(
    int imported,
    int duplicates,
    int unsupported,
    int failed,
  ) {
    return 'Import terminé : $imported importé(s), $duplicates déjà présent(s), $unsupported non pris en charge, $failed en échec.';
  }

  @override
  String importCancelled(int imported) {
    return 'Import arrêté : $imported importé(s) avant l\'arrêt.';
  }

  @override
  String importPickerError(String message) {
    return 'Le sélecteur de fichiers n\'a pas pu s\'ouvrir : $message';
  }

  @override
  String get importDetails => 'Détails';

  @override
  String get importReportTitle => 'Rapport d\'import';

  @override
  String get importOutcomeImported => 'Importé';

  @override
  String get importOutcomeDuplicate => 'Déjà présent dans la bibliothèque';

  @override
  String get importOutcomeUnsupported => 'Format non pris en charge';

  @override
  String get importOutcomeFailed => 'Échec';

  @override
  String get viewerInfo => 'Informations';

  @override
  String get viewerOpenExternal => 'Ouvrir avec l\'application du système';

  @override
  String get viewerOpenExternalFailed =>
      'Impossible d\'ouvrir le fichier avec le système.';

  @override
  String get viewerPreviewUnavailable =>
      'Aperçu indisponible pour ce format sur cette plateforme.';

  @override
  String get viewerVideoUnavailable =>
      'La lecture vidéo intégrée n\'est pas disponible sous Linux dans cette version (aucun moteur vidéo installé). Vous pouvez ouvrir la vidéo avec le lecteur du système.';

  @override
  String viewerVideoError(String message) {
    return 'Impossible de lire cette vidéo : $message';
  }

  @override
  String get viewerPlay => 'Lecture';

  @override
  String get viewerPause => 'Pause';

  @override
  String get viewerNotFound => 'Ce média n\'existe plus dans la bibliothèque.';

  @override
  String get viewerFileMissing =>
      'La copie de travail de ce média est introuvable.';

  @override
  String get metaFileName => 'Nom';

  @override
  String get metaType => 'Type';

  @override
  String get metaSize => 'Taille';

  @override
  String get metaDimensions => 'Dimensions';

  @override
  String get metaDuration => 'Durée';

  @override
  String get metaTakenAt => 'Date';

  @override
  String get metaImportedAt => 'Importé le';

  @override
  String get metaCamera => 'Appareil';

  @override
  String get metaGps => 'Position GPS';

  @override
  String get metaGpsPresent =>
      'Présente : elle sera visible par tous si l\'image est publiée telle quelle.';

  @override
  String get metaGpsAbsent => 'Absente';

  @override
  String get metaSha256 => 'Empreinte SHA-256';

  @override
  String get metaSource => 'Provenance';

  @override
  String get metaUnknown => 'Inconnue';

  @override
  String get metaVideoUnavailable =>
      'Métadonnées vidéo indisponibles sur cette plateforme.';

  @override
  String get commonOpenInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get commonCopy => 'Copier';

  @override
  String get commonCopied => 'Copié';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonRefresh => 'Actualiser';

  @override
  String commonUnknownError(String message) {
    return 'Erreur inattendue : $message';
  }

  @override
  String get ghConnectTitle => 'Connexion à GitHub';

  @override
  String get ghConnectIntro =>
      'Le jeton est vérifié auprès de GitHub puis conservé uniquement dans le trousseau sécurisé du système, jamais dans la base locale ni dans les journaux.';

  @override
  String get ghStoreUnavailable =>
      'Le trousseau sécurisé du système est inaccessible. Sous Linux, vérifiez qu\'un service de secrets (GNOME Keyring, KWallet…) est actif et déverrouillé. Sans lui, aucun identifiant ne peut être enregistré.';

  @override
  String get ghPatTitle => 'Jeton d\'accès personnel (recommandé)';

  @override
  String get ghPatHelp =>
      'Créez un jeton « fine-grained » limité aux seuls dépôts voulus, avec la permission Contents en lecture et écriture (Metadata en lecture est ajouté automatiquement). Pour créer des dépôts depuis l\'application, ajoutez Administration en écriture.';

  @override
  String get ghPatCreate => 'Créer un jeton sur GitHub';

  @override
  String get ghPatField => 'Jeton GitHub';

  @override
  String get ghPatConnect => 'Vérifier et se connecter';

  @override
  String get ghDeviceTitle => 'Connexion par le navigateur';

  @override
  String get ghDeviceHelp =>
      'Nécessite l\'identifiant client (Client ID) d\'une application OAuth ou GitHub App dont le « Device Flow » est activé. Aucun secret n\'est requis.';

  @override
  String get ghDeviceClientId => 'Client ID';

  @override
  String get ghDeviceStart => 'Se connecter avec le navigateur';

  @override
  String get ghDeviceCodeIntro =>
      'Saisissez ce code sur la page GitHub qui vient de s\'ouvrir :';

  @override
  String get ghDeviceWaiting => 'En attente de votre autorisation…';

  @override
  String get ghDeviceDenied => 'Autorisation refusée ou annulée.';

  @override
  String get ghDeviceExpired => 'Le code a expiré. Recommencez.';

  @override
  String ghDeviceMisconfigured(String detail) {
    return 'Configuration refusée par GitHub : $detail';
  }

  @override
  String ghConnectedAs(String login) {
    return 'Connecté en tant que $login';
  }

  @override
  String get ghTokenFineGrained =>
      'Jeton fine-grained ou GitHub App : permissions définies sur GitHub';

  @override
  String ghTokenScopes(String scopes) {
    return 'Portées du jeton : $scopes';
  }

  @override
  String ghTokenExpires(String date) {
    return 'Expire le $date';
  }

  @override
  String get ghDisconnect => 'Se déconnecter';

  @override
  String get ghDisconnectTitle => 'Se déconnecter de GitHub ?';

  @override
  String get ghDisconnectBody =>
      'Le jeton sera effacé du trousseau de cet appareil. Pour le révoquer définitivement, supprimez-le aussi dans les paramètres de votre compte GitHub.';

  @override
  String get ghRevokePage => 'Gérer mes jetons sur GitHub';

  @override
  String get ghSessionError => 'Le jeton enregistré n\'a pas pu être vérifié.';

  @override
  String get ghRepos => 'Dépôts';

  @override
  String get ghReposSearch => 'Filtrer les dépôts';

  @override
  String get ghReposEmpty => 'Aucun dépôt accessible avec ce jeton.';

  @override
  String get ghPrivate => 'Privé';

  @override
  String get ghPublic => 'Public';

  @override
  String get ghReadOnly => 'Lecture seule';

  @override
  String get ghActive => 'Actif';

  @override
  String get ghNewRepo => 'Nouveau dépôt';

  @override
  String get ghNewRepoName => 'Nom du dépôt';

  @override
  String get ghNewRepoNameInvalid =>
      'Lettres, chiffres, « - », « _ » et « . » uniquement (100 caractères maximum).';

  @override
  String get ghNewRepoDescription => 'Description (facultative)';

  @override
  String get ghNewRepoPrivate =>
      'Privé : visible par vous et les personnes invitées';

  @override
  String get ghNewRepoPublic =>
      'Public : visible par tout le monde sur Internet';

  @override
  String get ghNewRepoCreate => 'Créer';

  @override
  String get ghNewRepoPublicConfirmTitle => 'Créer un dépôt public ?';

  @override
  String ghNewRepoPublicConfirmBody(String name) {
    return 'Tout ce que vous publierez dans « $name » sera visible par n\'importe qui, y compris les métadonnées des photos (position GPS…).';
  }

  @override
  String get ghNewRepoPublicConfirm => 'Oui, créer un dépôt public';

  @override
  String ghNewRepoCreated(String name) {
    return 'Dépôt $name créé.';
  }

  @override
  String get ghBranch => 'Branche';

  @override
  String get ghRoot => 'Racine';

  @override
  String get ghFolderEmpty => 'Dossier vide.';

  @override
  String get ghRepoEmpty => 'Ce dépôt ne contient encore aucun fichier.';

  @override
  String get ghCommits => 'Derniers commits';

  @override
  String get ghSetActive => 'Définir comme dépôt actif';

  @override
  String ghActiveSet(String name) {
    return '$name est maintenant le dépôt actif.';
  }

  @override
  String get ghPublishHere => 'Publier ici';

  @override
  String get errUnauthorized =>
      'GitHub refuse le jeton : il est invalide, expiré ou révoqué. Reconnectez-vous avec un nouveau jeton.';

  @override
  String errForbidden(String detail) {
    return 'Permission insuffisante. Pour un jeton fine-grained, vérifiez que ce dépôt est inclus et que la permission nécessaire (Contents en écriture, ou Administration pour créer un dépôt) est accordée. Détail : $detail';
  }

  @override
  String get errNotFound =>
      'Introuvable. Le dépôt, la branche ou le dossier n\'existe pas, ou votre jeton n\'y a pas accès.';

  @override
  String errRateLimited(String time) {
    return 'Limite de requêtes GitHub atteinte. Réessayez après $time.';
  }

  @override
  String get errRateLimitedNoTime =>
      'Limite de requêtes GitHub atteinte. Réessayez dans quelques minutes.';

  @override
  String get errConflict =>
      'La branche a été modifiée sur GitHub pendant la publication. Rien n\'a été publié : relancez l\'analyse pour tenir compte des nouveautés.';

  @override
  String get errEmptyRepository => 'Ce dépôt est vide.';

  @override
  String errValidation(String detail) {
    return 'GitHub a refusé la demande : $detail';
  }

  @override
  String errNetwork(String detail) {
    return 'Connexion à GitHub impossible. Vérifiez votre accès à Internet. ($detail)';
  }

  @override
  String get errServer =>
      'GitHub rencontre un problème (erreur serveur). Réessayez plus tard.';

  @override
  String get pubNotConnected => 'Connectez-vous à GitHub pour publier.';

  @override
  String get pubGoToGithub => 'Aller à l\'écran GitHub';

  @override
  String get pubNoMedia =>
      'Votre bibliothèque est vide : importez d\'abord des médias dans la galerie.';

  @override
  String get pubStepMedia => 'Médias';

  @override
  String get pubStepDestination => 'Destination';

  @override
  String get pubStepAnalysis => 'Analyse';

  @override
  String get pubStepMessage => 'Message';

  @override
  String get pubStepReview => 'Vérification';

  @override
  String get pubStepResult => 'Résultat';

  @override
  String pubSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count médias sélectionnés',
      one: '1 média sélectionné',
      zero: 'Aucun média sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get pubRepository => 'Dépôt';

  @override
  String get pubChooseRepository => 'Choisir un dépôt';

  @override
  String get pubFolder => 'Dossier dans le dépôt';

  @override
  String get pubFolderHelp =>
      'Ex. : photos/2024. Un dossier inexistant sera créé par l\'ajout des fichiers. Laisser vide pour la racine.';

  @override
  String get pubFolderInvalid =>
      'Chemin invalide (pas de « .. », de « .git » ni de caractères spéciaux).';

  @override
  String get pubEmptyRepoNote =>
      'Dépôt vide : un premier commit l\'initialise avec un fichier, puis un second regroupe tous les autres, sur la branche par défaut.';

  @override
  String get pubAnalyze => 'Analyser';

  @override
  String pubAnalyzing(int done, int total) {
    return 'Analyse : $done sur $total';
  }

  @override
  String get pubActionAdd => 'Nouveau';

  @override
  String get pubActionSkip => 'Identique sur GitHub — ignoré';

  @override
  String get pubActionRenamed => 'Nom déjà pris — publié sous un autre nom';

  @override
  String get pubActionOverwrite => 'Remplacera le fichier existant';

  @override
  String get pubBlockedLfs =>
      'Plus de 100 Mio alors que Git LFS est désactivé dans les paramètres';

  @override
  String get pubBlockedPath => 'Nom de fichier incompatible avec un dépôt';

  @override
  String get pubWarnLarge =>
      'Volumineux (plus de 50 Mio) : GitHub le signalera';

  @override
  String get pubWarnGpsPublic =>
      'Contient une position GPS et le dépôt est public';

  @override
  String get pubOverwriteToggle => 'Remplacer plutôt que renommer';

  @override
  String get pubTruncatedTree =>
      'Le dépôt est très volumineux : l\'analyse des conflits est partielle. GitHub n\'écrasera toutefois rien sans que ce soit prévu.';

  @override
  String get pubOptimizationNote =>
      'Astuce : optimisez d\'abord vos images (Galerie › Optimiser) pour publier des copies plus légères et sans position GPS.';

  @override
  String pubSummaryCounts(int upload, String size, int skipped, int blocked) {
    return '$upload à envoyer ($size), $skipped ignoré(s), $blocked bloqué(s)';
  }

  @override
  String get pubNothingToUpload =>
      'Rien à publier : tous les fichiers sont déjà présents ou bloqués.';

  @override
  String get pubMessageLabel => 'Message de commit';

  @override
  String pubMessageDefault(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ajout de $count médias via GitPhoto Studio',
      one: 'Ajout d\'un média via GitPhoto Studio',
    );
    return '$_temp0';
  }

  @override
  String get pubMessageEmpty => 'Le message ne peut pas être vide.';

  @override
  String get pubReviewIntro => 'Voici exactement ce qui sera envoyé :';

  @override
  String pubReviewTarget(String repo, String branch) {
    return '$repo · branche $branch';
  }

  @override
  String get pubReviewSingleCommit =>
      'Tous les fichiers seront ajoutés en un seul commit.';

  @override
  String pubReviewOverwriteWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers existants seront remplacés.',
      one: '1 fichier existant sera remplacé.',
    );
    return '$_temp0 L\'ancienne version reste consultable dans l\'historique Git.';
  }

  @override
  String get pubConfirm => 'Publier sur GitHub';

  @override
  String get pubConfirmTitle => 'Confirmer la publication ?';

  @override
  String pubConfirmBody(int count, String repo, String visibility) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers seront publiés',
      one: '1 fichier sera publié',
    );
    return '$_temp0 dans $repo ($visibility).';
  }

  @override
  String pubStepUploading(int done, int total) {
    return 'Envoi des fichiers : $done sur $total';
  }

  @override
  String get pubStepCommitting => 'Création du commit…';

  @override
  String get pubStepUpdating => 'Mise à jour de la branche…';

  @override
  String get pubStepVerifying => 'Vérification sur GitHub…';

  @override
  String get pubSuccess => 'Publication réussie';

  @override
  String get pubVerified =>
      'Vérifié : les fichiers sont présents sur GitHub avec le contenu attendu.';

  @override
  String get pubNotVerified =>
      'Publié, mais la vérification distante n\'a pas pu confirmer tous les fichiers. Consultez le commit sur GitHub.';

  @override
  String pubCommit(String sha) {
    return 'Commit $sha';
  }

  @override
  String get pubFailed => 'La publication a échoué';

  @override
  String get pubNew => 'Nouvelle publication';

  @override
  String get histEmpty => 'Aucune opération pour l\'instant.';

  @override
  String get histStatusRunning => 'En cours';

  @override
  String get histStatusSuccess => 'Réussie';

  @override
  String get histStatusFailed => 'Échouée';

  @override
  String get histStatusInterrupted => 'Interrompue';

  @override
  String get histInterruptedHelp =>
      'L\'application a été fermée pendant l\'opération : son résultat est inconnu. Vérifiez le dépôt sur GitHub ; une nouvelle analyse ignorera les fichiers déjà publiés.';

  @override
  String histFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers',
      one: '1 fichier',
    );
    return '$_temp0';
  }

  @override
  String get histRetryNote =>
      'Une publication échouée ou interrompue peut être reprise : seuls les fichiers absents de GitHub sont envoyés, sans doublon. Après une perte de connexion, l\'application réessaie d\'elle-même deux fois.';

  @override
  String get histError => 'Erreur';

  @override
  String get dashNoCommitsConnect =>
      'Connectez-vous à GitHub et choisissez un dépôt actif pour voir ses derniers commits.';

  @override
  String get settingsGithub => 'Compte GitHub';

  @override
  String get settingsGithubNotConnected => 'Non connecté';

  @override
  String get pixelPublishTip =>
      'Astuce : vérifiez la colonne GPS avant de publier dans un dépôt public.';

  @override
  String get editorChooseMedia => 'Choisir un média à retoucher';

  @override
  String get editorNoMedia => 'Importez d\'abord des médias dans la galerie.';

  @override
  String get editorOriginalsSafe =>
      'Chaque traitement crée une nouvelle version : l\'original n\'est jamais modifié.';

  @override
  String get editorFileName => 'Nom du fichier';

  @override
  String get editorRename => 'Renommer';

  @override
  String get editorRenamed => 'Média renommé.';

  @override
  String get editorRenameInvalid => 'Nom de fichier invalide.';

  @override
  String get editorAlbum => 'Album';

  @override
  String get editorNoAlbum => 'Aucun album';

  @override
  String editorVersionOf(String name) {
    return 'Version de « $name »';
  }

  @override
  String get editorImageSection => 'Optimisation de l\'image';

  @override
  String get presetWeb => 'Web (1920 px)';

  @override
  String get presetLight => 'Léger (1280 px)';

  @override
  String get presetThumbnail => 'Miniature (400 px)';

  @override
  String get presetCustom => 'Personnalisé';

  @override
  String editorMaxDimension(int px) {
    return 'Plus grand côté : $px px';
  }

  @override
  String get editorKeepDimensions => 'Garder les dimensions d\'origine';

  @override
  String get editorFormat => 'Format';

  @override
  String editorQuality(int quality) {
    return 'Qualité : $quality %';
  }

  @override
  String get editorMetadata => 'Métadonnées';

  @override
  String get metaStripAll => 'Tout retirer (recommandé pour publier)';

  @override
  String get metaKeepBasic => 'Garder date et appareil (jamais le GPS)';

  @override
  String get editorPreview => 'Aperçu';

  @override
  String get editorPreviewing => 'Calcul de l\'aperçu…';

  @override
  String get editorOriginal => 'Original';

  @override
  String get editorResult => 'Résultat';

  @override
  String editorSizeChange(String original, String result, String change) {
    return '$original → $result ($change)';
  }

  @override
  String get editorSaveVersion => 'Enregistrer comme nouvelle version';

  @override
  String editorVersionSaved(String name) {
    return 'Nouvelle version créée : $name';
  }

  @override
  String get editorVersionDuplicate =>
      'Une version identique existe déjà dans la bibliothèque.';

  @override
  String get editorVideoSection => 'Préparation de la vidéo';

  @override
  String get videoPresetLight => 'Légère (480p)';

  @override
  String get videoPreset720 => '720p';

  @override
  String get videoPreset1080 => '1080p';

  @override
  String get videoRemoveAudio => 'Retirer le son';

  @override
  String videoEstimate(String size, String original) {
    return 'Taille estimée : $size (original : $original)';
  }

  @override
  String get videoEstimateUnknown =>
      'Taille estimée inconnue : durée de la vidéo non disponible.';

  @override
  String videoEngine(String engine) {
    return 'Moteur : $engine';
  }

  @override
  String get videoConvert => 'Convertir en MP4';

  @override
  String videoConverting(int percent) {
    return 'Conversion en cours… $percent %';
  }

  @override
  String get videoUnavailableLinux =>
      'Conversion vidéo indisponible : ffmpeg n\'est pas installé. Installez-le avec « sudo apt install ffmpeg », puis relancez la détection dans Paramètres › Diagnostic.';

  @override
  String get videoUnavailable =>
      'Conversion vidéo indisponible sur cette plateforme.';

  @override
  String get jobStop => 'Arrêter';

  @override
  String jobBatchProgress(int done, int total) {
    return 'Optimisation : $done sur $total';
  }

  @override
  String jobDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versions créées',
      one: '1 version créée',
      zero: 'Aucune version créée',
    );
    return '$_temp0';
  }

  @override
  String get jobCancelled => 'Traitement arrêté.';

  @override
  String jobFailed(String message) {
    return 'Échec : $message';
  }

  @override
  String get dupTitle => 'Doublons probables';

  @override
  String get dupHelp =>
      'Images visuellement très proches (redimensionnées, recompressées…). Les copies exactes sont déjà refusées à l\'import.';

  @override
  String get dupNone => 'Aucun doublon probable.';

  @override
  String dupGroup(int count) {
    return '$count images semblables';
  }

  @override
  String get dupRemove => 'Retirer';

  @override
  String get dupAnalyzing => 'Analyse des images…';

  @override
  String dupRemoveTitle(String name) {
    return 'Retirer « $name » ?';
  }

  @override
  String get albumsTitle => 'Albums';

  @override
  String get albumsNone => 'Aucun album pour l\'instant.';

  @override
  String get albumNew => 'Nouvel album';

  @override
  String get albumName => 'Nom de l\'album';

  @override
  String get albumCreate => 'Créer';

  @override
  String get albumRename => 'Renommer';

  @override
  String get albumDelete => 'Supprimer l\'album';

  @override
  String albumDeleteBody(String name) {
    return 'Les médias de « $name » restent dans la bibliothèque, simplement hors album.';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count médias',
      one: '1 média',
      zero: 'vide',
    );
    return '$_temp0';
  }

  @override
  String get albumAutoOrganize => 'Classer par année et mois';

  @override
  String albumAutoOrganizeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count médias hors album seront rangés dans des albums « AAAA-MM » selon leur date.',
      one:
          '1 média hors album sera rangé dans un album « AAAA-MM » selon sa date.',
      zero: 'Aucun média hors album à classer.',
    );
    return '$_temp0';
  }

  @override
  String albumAutoOrganized(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count médias classés',
      one: '1 média classé',
    );
    return '$_temp0';
  }

  @override
  String get galleryOptimize => 'Optimiser';

  @override
  String galleryOptimizeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Optimiser les $count images sélectionnées',
      one: 'Optimiser l\'image sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String get galleryOptimizeVideosIgnored =>
      'Les vidéos sélectionnées sont ignorées : préparez-les une par une dans l\'éditeur.';

  @override
  String get galleryAddToAlbum => 'Ranger dans un album';

  @override
  String get galleryAllAlbums => 'Tous les albums';

  @override
  String galleryMovedToAlbum(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count médias rangés',
      one: '1 média rangé',
    );
    return '$_temp0 dans « $name »';
  }

  @override
  String get viewerEdit => 'Retoucher';

  @override
  String get metaVersionOf => 'Version de';

  @override
  String get diagFfmpeg => 'ffmpeg (vidéo)';

  @override
  String videoNotSmaller(String source, String output) {
    return 'La conversion ne réduit pas la taille ($source → $output) : la version n\'a pas été conservée. La vidéo est sans doute déjà bien compressée ; essayez « Retirer le son » ou un préréglage plus bas.';
  }

  @override
  String get histStatusQueued => 'En file d\'attente';

  @override
  String get histStatusCancelled => 'Annulée';

  @override
  String get histResume => 'Reprendre';

  @override
  String get histCancel => 'Annuler';

  @override
  String get histCancelTitle => 'Annuler cette publication ?';

  @override
  String get histCancelBody =>
      'Les fichiers pas encore publiés ne seront pas envoyés. Ce qui est déjà sur GitHub n\'est pas retiré.';

  @override
  String get histResumeNote =>
      'La reprise relit d\'abord GitHub : les fichiers déjà publiés ne sont jamais renvoyés.';

  @override
  String histAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tentatives',
      one: '1 tentative',
    );
    return '$_temp0';
  }

  @override
  String get entryPending => 'En attente';

  @override
  String get entryUploaded => 'Envoyé, commit à finaliser';

  @override
  String get entryDone => 'Publié';

  @override
  String get entrySkipped => 'Déjà présent sur GitHub';

  @override
  String get entryFailed => 'Échec';

  @override
  String get entryCancelled => 'Annulé';

  @override
  String get strategyApi => 'API';

  @override
  String get strategyLfs => 'Git LFS';

  @override
  String get strategyGit => 'Git';

  @override
  String get pubCancelRunning => 'Annuler la publication';

  @override
  String get pubCancelled => 'Publication annulée : rien n\'a été publié.';

  @override
  String get pubQueuedNote =>
      'La publication passe par la file d\'attente : vous pouvez quitter cet écran, elle se poursuit et reste visible dans l\'Historique.';

  @override
  String get pubViaLfs => 'Gros fichier : envoyé par Git LFS';

  @override
  String get pubViaGit => 'Envoyé par Git natif';

  @override
  String get pubBlockedLfsMax =>
      'Plus de 2 Gio : dépasse la taille maximale d\'un fichier Git LFS chez GitHub (compte gratuit)';

  @override
  String get pubLfsQuotaNote =>
      'Les fichiers Git LFS utilisent le quota de stockage LFS de votre compte GitHub.';

  @override
  String errDuplicate(String path) {
    return '« $path » est déjà en attente de publication vers ce dépôt.';
  }

  @override
  String errPathConflict(String path) {
    return '« $path » a été modifié sur GitHub depuis l\'analyse. Rien n\'a été publié : relancez l\'analyse.';
  }

  @override
  String get settingsPublishing => 'Publication';

  @override
  String get settingsLfs => 'Git LFS pour les fichiers de plus de 50 Mio';

  @override
  String get settingsLfsHelp =>
      'Recommandé. Fonctionne aussi sous Android, sans outil à installer. Utilise le quota LFS du compte GitHub.';

  @override
  String get settingsNativeGit => 'Publier avec le Git de l\'ordinateur';

  @override
  String get settingsNativeGitHelp =>
      'Linux, si Git est détecté. Les gros fichiers passent toujours par Git LFS en HTTP.';

  @override
  String get settingsNativeGitUnavailable =>
      'Git n\'est pas détecté sur cet appareil : l\'API GitHub est utilisée.';

  @override
  String get agentDisabledTitle => 'L\'assistant IA est désactivé';

  @override
  String get agentDisabledBody =>
      'L\'application fonctionne entièrement sans IA. Pour utiliser l\'agent, activez-le et configurez un fournisseur (Mistral recommandé) dans les paramètres.';

  @override
  String get agentOpenSettings => 'Ouvrir les paramètres de l\'IA';

  @override
  String agentNeedsKey(String provider) {
    return 'Enregistrez d\'abord une clé d\'API pour $provider dans les paramètres.';
  }

  @override
  String get agentNeedsModel => 'Choisissez un modèle dans les paramètres.';

  @override
  String get agentConsentTitle => 'Avant de commencer';

  @override
  String agentConsentBody(String provider) {
    return 'Pour comprendre vos demandes, l\'agent envoie à $provider votre message et des métadonnées : noms de fichiers, tailles, dates, albums, dimensions, présence d\'une position GPS (jamais la position elle-même), noms de vos dépôts GitHub et historique des publications.\n\nAucune image ni vidéo n\'est envoyée. Aucun jeton ni aucune clé n\'est transmis au modèle.';
  }

  @override
  String get agentConsentAccept => 'J\'accepte';

  @override
  String get agentInputHint =>
      'Ex. : « Publie ces photos dans mon dépôt Portfolio »';

  @override
  String get agentSend => 'Envoyer';

  @override
  String get agentThinking => 'L\'agent réfléchit…';

  @override
  String agentConsulting(String tool) {
    return 'L\'agent consulte : $tool';
  }

  @override
  String get agentStop => 'Arrêter';

  @override
  String get agentNewConversation => 'Nouvelle conversation';

  @override
  String get agentExamplesTitle => 'Exemples de demandes';

  @override
  String get agentExamples =>
      'Publie les photos sélectionnées dans mon dépôt Portfolio\nClasse mes images dans des albums par année et par mois\nRéduis la taille des photos sans trop perdre en qualité\nPrépare un album de voyage et génère un README\nExplique pourquoi ma dernière publication a échoué\nTrouve les doublons avant la publication\nQuelles vidéos passeront par Git LFS ?';

  @override
  String agentToolsUsed(String tools) {
    return 'Informations consultées : $tools';
  }

  @override
  String get agentSafetyNote =>
      'L\'agent ne peut rien supprimer ni remplacer, et n\'agit qu\'après votre confirmation.';

  @override
  String get toolGetSelection => 'sélection';

  @override
  String get toolSearchMedia => 'bibliothèque';

  @override
  String get toolListAlbums => 'albums';

  @override
  String get toolFindSimilar => 'doublons';

  @override
  String get toolGithubStatus => 'GitHub';

  @override
  String get toolRecentOperations => 'historique';

  @override
  String get toolPreviewPublication => 'aperçu de publication';

  @override
  String get planTitle => 'Plan proposé';

  @override
  String planMediaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count médias',
      one: '1 média',
    );
    return '$_temp0';
  }

  @override
  String planFromStep(int step) {
    return 'les copies de l\'étape $step';
  }

  @override
  String planStepMove(String target, String album) {
    return 'Ranger $target dans l\'album « $album »';
  }

  @override
  String planStepOrganizeYear(String target) {
    return 'Ranger $target dans des albums par année';
  }

  @override
  String planStepOrganizeMonth(String target) {
    return 'Ranger $target dans des albums par mois (AAAA-MM)';
  }

  @override
  String planStepOptimize(int count, String preset) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '1 image',
    );
    return 'Créer des versions optimisées de $_temp0 — $preset. Originaux conservés, métadonnées retirées.';
  }

  @override
  String planStepConvert(int count, String preset) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vidéos',
      one: '1 vidéo',
    );
    return 'Créer des versions converties de $_temp0 — $preset. Originaux conservés.';
  }

  @override
  String planStepPublish(String target, String repo, String branch) {
    return 'Publier $target dans $repo, branche $branch';
  }

  @override
  String get planReadmeOnly => 'un README';

  @override
  String planPublishFolder(String folder) {
    return 'Dossier : $folder';
  }

  @override
  String get planPublishRoot => 'Dossier : racine du dépôt';

  @override
  String planPublishMessage(String message) {
    return 'Message du commit : $message';
  }

  @override
  String get planPublishReadme => 'Ajoute un README.md au même commit';

  @override
  String get planPublishSafety =>
      'Un seul commit. Aucun fichier existant n\'est remplacé (renommage en cas de conflit). Les fichiers déjà publiés à l\'identique sont ignorés.';

  @override
  String planWarnGps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos publiées contiennent',
      one: '1 photo publiée contient',
    );
    return '$_temp0 une position GPS.';
  }

  @override
  String planWarnPublic(String repo) {
    return '$repo est un dépôt public : les fichiers seront visibles par tout le monde.';
  }

  @override
  String get planWarnVideo =>
      'La conversion vidéo n\'est pas disponible sur cet appareil : cette étape échouera.';

  @override
  String get planExecute => 'Exécuter le plan';

  @override
  String get planReject => 'Refuser';

  @override
  String get planConfirmTitle => 'Exécuter ce plan ?';

  @override
  String planConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions vont être exécutées dans l\'ordre.',
      one: '1 action va être exécutée.',
    );
    return '$_temp0 Vous pourrez arrêter entre deux fichiers. Rien n\'est supprimé.';
  }

  @override
  String get planConfirmPublish => 'Des fichiers seront publiés sur GitHub.';

  @override
  String get planStatusRejected => 'Plan refusé : rien n\'a été fait.';

  @override
  String get planStatusExpired =>
      'Plan non confirmé, remplacé par votre nouvelle demande.';

  @override
  String get planStatusRunning => 'Exécution en cours…';

  @override
  String planProgress(int step, int done, int total) {
    return 'Étape $step — $done/$total';
  }

  @override
  String get planDoneOk => 'Plan exécuté et vérifié.';

  @override
  String get planDonePartial =>
      'Plan exécuté avec des réserves (voir le détail).';

  @override
  String get planDoneFailed => 'Le plan n\'a pas pu être exécuté entièrement.';

  @override
  String get planDoneCancelled => 'Exécution arrêtée.';

  @override
  String planArchived(String summary) {
    return 'Plan d\'une conversation précédente (ne peut plus être exécuté) : $summary';
  }

  @override
  String get stepDone => 'Fait';

  @override
  String get stepPartial => 'Fait en partie';

  @override
  String get stepFailed => 'Échec';

  @override
  String get stepSkipped => 'Non exécutée';

  @override
  String get stepCancelled => 'Arrêtée';

  @override
  String stepAffected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments traités',
      one: '1 élément traité',
    );
    return '$_temp0';
  }

  @override
  String stepProduced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count copies créées',
      one: '1 copie créée',
    );
    return '$_temp0';
  }

  @override
  String get stepAlreadyPublished =>
      'Déjà publié à l\'identique : aucun commit nécessaire.';

  @override
  String stepRenamed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers renommés',
      one: '1 fichier renommé',
    );
    return '$_temp0 pour ne rien écraser';
  }

  @override
  String get stepVerified => 'Contenu vérifié sur GitHub';

  @override
  String get stepNotVerified => 'Commit créé, mais contenu distant non vérifié';

  @override
  String get aiErrUnauthorized =>
      'Clé d\'API refusée par le fournisseur. Vérifiez-la dans les paramètres.';

  @override
  String get aiErrForbidden =>
      'Accès refusé par le fournisseur (droits de la clé ou modèle non autorisé).';

  @override
  String get aiErrNotFound =>
      'Modèle ou service introuvable. Choisissez un autre modèle.';

  @override
  String get aiErrRateLimited =>
      'Trop de requêtes ou quota épuisé. Réessayez plus tard.';

  @override
  String get aiErrBadRequest => 'Le fournisseur a refusé la demande.';

  @override
  String get aiErrToolsUnsupported =>
      'Ce modèle ne sait pas utiliser d\'outils. Choisissez un modèle compatible (par ex. mistral-small-latest).';

  @override
  String get aiErrNetwork =>
      'Impossible de joindre le fournisseur. Vérifiez la connexion.';

  @override
  String get aiErrTimeout => 'Le fournisseur n\'a pas répondu à temps.';

  @override
  String get aiErrServer =>
      'Le fournisseur rencontre une erreur. Réessayez plus tard.';

  @override
  String get aiErrInvalid => 'Réponse inattendue du fournisseur.';

  @override
  String get aiErrNotConfigured => 'L\'IA n\'est pas configurée (paramètres).';

  @override
  String get aiErrLoop =>
      'L\'agent n\'a pas réussi à conclure. Reformulez votre demande.';

  @override
  String aiErrDetail(String detail) {
    return 'Détail : $detail';
  }

  @override
  String get aiEnable => 'Activer l\'assistant IA';

  @override
  String get aiEnableHelp =>
      'Désactivé par défaut. Toutes les autres fonctions marchent sans IA.';

  @override
  String get aiProvider => 'Fournisseur';

  @override
  String get aiApiKey => 'Clé d\'API';

  @override
  String get aiKeySaved => 'Clé enregistrée dans le trousseau du système';

  @override
  String get aiKeyMissing => 'Aucune clé enregistrée';

  @override
  String get aiKeyHint => 'Collez votre clé ici';

  @override
  String get aiKeySave => 'Enregistrer la clé';

  @override
  String get aiKeyDelete => 'Supprimer la clé';

  @override
  String get aiKeyGet => 'Obtenir une clé';

  @override
  String get aiKeyStoreUnavailable =>
      'Trousseau du système indisponible : aucune clé ne peut être enregistrée de façon sûre.';

  @override
  String get aiBaseUrl => 'Adresse du serveur';

  @override
  String get aiBaseUrlSave => 'Enregistrer l\'adresse';

  @override
  String get aiBaseUrlInvalid =>
      'Adresse refusée (http:// ou https://, sans identifiants).';

  @override
  String get aiModel => 'Modèle';

  @override
  String get aiModelLoad => 'Charger la liste des modèles';

  @override
  String get aiModelTools => 'outils';

  @override
  String get aiModelNoTools => 'sans outils';

  @override
  String get aiTest => 'Tester la connexion';

  @override
  String aiTestOk(String detail) {
    return 'Connexion réussie — $detail';
  }

  @override
  String get aiTestFailed => 'Échec de la connexion';

  @override
  String get aiConsent => 'Autoriser l\'envoi des métadonnées à ce fournisseur';

  @override
  String get aiConsentHelp =>
      'Noms, tailles, dates, albums, dépôts. Jamais d\'image ni de vidéo.';

  @override
  String get aiSaveConversations =>
      'Enregistrer les conversations sur l\'appareil';

  @override
  String get aiSaveConversationsHelp =>
      'Désactivé par défaut. Elles restent locales et peuvent être effacées.';

  @override
  String get aiDeleteConversations => 'Effacer les conversations enregistrées';

  @override
  String get aiDeleteConversationsDone => 'Conversations effacées.';

  @override
  String get aiVerifiedReal => 'Testé avec le vrai service';

  @override
  String get aiNotVerifiedReal =>
      'Non testé avec le vrai service (serveur simulé uniquement)';

  @override
  String get aiCapabilities =>
      'Conversation et appels d\'outils. Vision non utilisée : aucun média n\'est envoyé.';

  @override
  String get helpSearchHint =>
      'Rechercher dans le mode d\'emploi (ex. : jeton, LFS, erreur 404)';

  @override
  String get helpNoResults =>
      'Aucune rubrique ne correspond à cette recherche.';

  @override
  String get helpTopics => 'Rubriques';

  @override
  String get helpContents => 'Sommaire';

  @override
  String get helpNextTopic => 'Rubrique suivante';

  @override
  String get helpUnknownTopic => 'Rubrique introuvable.';

  @override
  String get helpContextual => 'Aide sur cet écran';

  @override
  String get commonClear => 'Effacer';

  @override
  String get tourTitle => 'Parcours guidé';

  @override
  String get tourIntro =>
      'Les étapes se cochent toutes seules dès que vous les avez réalisées.';

  @override
  String tourProgress(int done, int total) {
    return '$done sur $total';
  }

  @override
  String get tourDone => 'Bravo : vous savez publier vos médias sur GitHub !';

  @override
  String get tourOptional => 'facultatif';

  @override
  String get tourStepDone => 'Étape faite';

  @override
  String get tourStepTodo => 'Étape à faire';

  @override
  String get tourGo => 'Y aller';

  @override
  String get tourRead => 'Lire l\'aide';

  @override
  String get tourImportTitle => 'Importer une photo';

  @override
  String get tourImportBody =>
      'Galerie › Importer. Vos fichiers d\'origine ne sont jamais modifiés.';

  @override
  String get tourGithubTitle => 'Se connecter à GitHub';

  @override
  String get tourGithubBody =>
      'Avec un jeton limité à vos dépôts de photos, gardé dans le trousseau du système.';

  @override
  String get tourRepoTitle => 'Choisir un dépôt actif';

  @override
  String get tourRepoBody =>
      'Créez un dépôt (privé de préférence) ou choisissez-en un existant.';

  @override
  String get tourOptimizeTitle => 'Alléger les photos';

  @override
  String get tourOptimizeBody =>
      'Des copies plus légères et sans position GPS ; les originaux restent intacts.';

  @override
  String get tourPublishTitle => 'Publier';

  @override
  String get tourPublishBody =>
      'L\'assistant montre exactement ce qui sera envoyé avant de publier.';

  @override
  String get tourHistoryTitle => 'Consulter l\'historique';

  @override
  String get tourHistoryBody =>
      'Chaque publication y figure avec son commit et un lien vers GitHub.';

  @override
  String get tourAiTitle => 'Essayer l\'agent IA';

  @override
  String get tourAiBody =>
      'Désactivé par défaut. Il propose des plans que vous confirmez.';

  @override
  String get diagLog => 'Journal technique';

  @override
  String get diagLogHelp =>
      'Événements récents de cette session (secrets masqués). Effacé à la fermeture.';

  @override
  String get diagLogEmpty => 'Aucun événement pour l\'instant.';

  @override
  String get diagLogCopy => 'Copier le journal';

  @override
  String get diagReport => 'Rapport de diagnostic';

  @override
  String get diagReportHelp =>
      'Version, plateforme, outils et compteurs. Sans jeton, clé, nom de compte, nom de dépôt ni nom de fichier : vous pouvez le joindre à une demande d\'aide.';

  @override
  String get diagReportCopy => 'Copier le rapport';

  @override
  String get diagCopied => 'Copié dans le presse-papiers.';

  @override
  String get settingsExport => 'Exporter les paramètres';

  @override
  String get settingsExportHelp =>
      'Préférences non sensibles au format JSON (thème, langue, publication, choix de l\'IA). Aucun jeton ni aucune clé.';

  @override
  String get settingsExportCopy => 'Copier';

  @override
  String get settingsExportSave => 'Enregistrer dans un fichier…';

  @override
  String settingsExportSaved(String path) {
    return 'Paramètres enregistrés : $path';
  }

  @override
  String get commonShow => 'Afficher le jeton';

  @override
  String get commonHide => 'Masquer le jeton';
}
