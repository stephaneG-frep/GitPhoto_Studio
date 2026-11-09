import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'GitPhoto Studio IA'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In fr, this message translates to:
  /// **'L\'atelier des médias connectés'**
  String get appTagline;

  /// No description provided for @navDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navDashboard;

  /// No description provided for @navGallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get navGallery;

  /// No description provided for @navEditor.
  ///
  /// In fr, this message translates to:
  /// **'Éditeur'**
  String get navEditor;

  /// No description provided for @navGithub.
  ///
  /// In fr, this message translates to:
  /// **'GitHub'**
  String get navGithub;

  /// No description provided for @navPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publication'**
  String get navPublish;

  /// No description provided for @navAgent.
  ///
  /// In fr, this message translates to:
  /// **'Agent IA'**
  String get navAgent;

  /// No description provided for @navHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get navSettings;

  /// No description provided for @navHelp.
  ///
  /// In fr, this message translates to:
  /// **'Mode d\'emploi'**
  String get navHelp;

  /// No description provided for @navMore.
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get navMore;

  /// No description provided for @navMenu.
  ///
  /// In fr, this message translates to:
  /// **'Menu de navigation'**
  String get navMenu;

  /// No description provided for @commonLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue : {message}'**
  String commonError(String message);

  /// No description provided for @commonRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// No description provided for @plannedTitle.
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get plannedTitle;

  /// No description provided for @plannedPhase.
  ///
  /// In fr, this message translates to:
  /// **'Prévu en phase {phase} — {phaseName}'**
  String plannedPhase(int phase, String phaseName);

  /// No description provided for @plannedHonesty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune action n\'est proposée ici pour l\'instant : les commandes apparaîtront lorsque la fonctionnalité sera réellement implémentée et testée.'**
  String get plannedHonesty;

  /// No description provided for @phaseAdvancedPublishing.
  ///
  /// In fr, this message translates to:
  /// **'Publications avancées'**
  String get phaseAdvancedPublishing;

  /// No description provided for @phaseAiAgent.
  ///
  /// In fr, this message translates to:
  /// **'Agent IA'**
  String get phaseAiAgent;

  /// No description provided for @phaseDocumentation.
  ///
  /// In fr, this message translates to:
  /// **'Documentation'**
  String get phaseDocumentation;

  /// No description provided for @agentIntro.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez ce que vous voulez faire ; l\'agent propose un plan et attend votre validation avant d\'agir.'**
  String get agentIntro;

  /// No description provided for @agentFeatures.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur prioritaire : Mistral (autres fournisseurs configurables)\nOutils typés et validés, aucun accès shell libre\nPlan d\'action présenté avant exécution\nConfirmation obligatoire\nAucun média envoyé à une IA sans votre accord'**
  String get agentFeatures;

  /// No description provided for @helpIntro.
  ///
  /// In fr, this message translates to:
  /// **'Documentation intégrée, consultable hors ligne.'**
  String get helpIntro;

  /// No description provided for @helpFeatures.
  ///
  /// In fr, this message translates to:
  /// **'Premiers pas et parcours guidé\nConnexion GitHub et création d\'un dépôt\nPublication d\'une photo ou d\'une vidéo\nCommits, branches et Git LFS\nUtilisation de l\'agent IA\nErreurs fréquentes, FAQ et glossaire'**
  String get helpFeatures;

  /// No description provided for @dashActiveRepo.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt actif'**
  String get dashActiveRepo;

  /// No description provided for @dashNoRepo.
  ///
  /// In fr, this message translates to:
  /// **'Aucun dépôt connecté'**
  String get dashNoRepo;

  /// No description provided for @dashLocalMedia.
  ///
  /// In fr, this message translates to:
  /// **'Médias locaux'**
  String get dashLocalMedia;

  /// No description provided for @dashPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get dashPending;

  /// No description provided for @dashLocalStorage.
  ///
  /// In fr, this message translates to:
  /// **'Espace local'**
  String get dashLocalStorage;

  /// No description provided for @dashTransfers.
  ///
  /// In fr, this message translates to:
  /// **'Transferts'**
  String get dashTransfers;

  /// No description provided for @dashNoTransfers.
  ///
  /// In fr, this message translates to:
  /// **'Aucun transfert en cours'**
  String get dashNoTransfers;

  /// No description provided for @dashRecentCommits.
  ///
  /// In fr, this message translates to:
  /// **'Derniers commits'**
  String get dashRecentCommits;

  /// No description provided for @dashShortcuts.
  ///
  /// In fr, this message translates to:
  /// **'Raccourcis'**
  String get dashShortcuts;

  /// No description provided for @pixelName.
  ///
  /// In fr, this message translates to:
  /// **'Pixel'**
  String get pixelName;

  /// No description provided for @pixelSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Pixel, le robot assistant du studio'**
  String get pixelSemantics;

  /// No description provided for @pixelWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour ! Je suis Pixel. Importez vos médias dans la galerie, connectez GitHub, puis publiez-les en quelques étapes.'**
  String get pixelWelcome;

  /// No description provided for @pixelSettingsHint.
  ///
  /// In fr, this message translates to:
  /// **'Les jetons et clés ne sont jamais enregistrés dans la base locale.'**
  String get pixelSettingsHint;

  /// No description provided for @settingsAppearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsAiProviders.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseurs IA'**
  String get settingsAiProviders;

  /// No description provided for @settingsAiProvidersNote.
  ///
  /// In fr, this message translates to:
  /// **'L\'application fonctionne entièrement sans IA.'**
  String get settingsAiProvidersNote;

  /// No description provided for @aiProviderPriority.
  ///
  /// In fr, this message translates to:
  /// **'Prioritaire'**
  String get aiProviderPriority;

  /// No description provided for @aiProviderLocal.
  ///
  /// In fr, this message translates to:
  /// **'Local'**
  String get aiProviderLocal;

  /// No description provided for @aiNotConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Non configuré'**
  String get aiNotConfigured;

  /// No description provided for @settingsDiagnostics.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostic'**
  String get settingsDiagnostics;

  /// No description provided for @diagPlatform.
  ///
  /// In fr, this message translates to:
  /// **'Plateforme'**
  String get diagPlatform;

  /// No description provided for @diagDatabase.
  ///
  /// In fr, this message translates to:
  /// **'Base de données'**
  String get diagDatabase;

  /// No description provided for @diagSchemaVersion.
  ///
  /// In fr, this message translates to:
  /// **'Schéma v{version}'**
  String diagSchemaVersion(int version);

  /// No description provided for @diagGit.
  ///
  /// In fr, this message translates to:
  /// **'Git'**
  String get diagGit;

  /// No description provided for @diagGitLfs.
  ///
  /// In fr, this message translates to:
  /// **'Git LFS'**
  String get diagGitLfs;

  /// No description provided for @diagNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Non détecté'**
  String get diagNotFound;

  /// No description provided for @diagNotApplicable.
  ///
  /// In fr, this message translates to:
  /// **'Non applicable sur cette plateforme'**
  String get diagNotApplicable;

  /// No description provided for @settingsAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonClose;

  /// No description provided for @galleryImport.
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get galleryImport;

  /// No description provided for @gallerySearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher par nom'**
  String get gallerySearchHint;

  /// No description provided for @galleryFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get galleryFilterAll;

  /// No description provided for @galleryFilterImages.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get galleryFilterImages;

  /// No description provided for @galleryFilterVideos.
  ///
  /// In fr, this message translates to:
  /// **'Vidéos'**
  String get galleryFilterVideos;

  /// No description provided for @gallerySort.
  ///
  /// In fr, this message translates to:
  /// **'Trier'**
  String get gallerySort;

  /// No description provided for @gallerySortDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get gallerySortDate;

  /// No description provided for @gallerySortName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get gallerySortName;

  /// No description provided for @gallerySortType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get gallerySortType;

  /// No description provided for @gallerySortSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get gallerySortSize;

  /// No description provided for @gallerySortAscending.
  ///
  /// In fr, this message translates to:
  /// **'Ordre croissant'**
  String get gallerySortAscending;

  /// No description provided for @gallerySortDescending.
  ///
  /// In fr, this message translates to:
  /// **'Ordre décroissant'**
  String get gallerySortDescending;

  /// No description provided for @galleryViewGrid.
  ///
  /// In fr, this message translates to:
  /// **'Affichage en grille'**
  String get galleryViewGrid;

  /// No description provided for @galleryViewList.
  ///
  /// In fr, this message translates to:
  /// **'Affichage en liste'**
  String get galleryViewList;

  /// No description provided for @galleryEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre bibliothèque est vide'**
  String get galleryEmptyTitle;

  /// No description provided for @galleryEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Importez des photos et des vidéos : le studio en conserve une copie de travail, vos fichiers originaux restent intacts.'**
  String get galleryEmptyBody;

  /// No description provided for @galleryEmptyDropHint.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez aussi glisser-déposer des fichiers ou des dossiers dans cette fenêtre.'**
  String get galleryEmptyDropHint;

  /// No description provided for @galleryNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun média ne correspond à ces critères.'**
  String get galleryNoResults;

  /// No description provided for @galleryCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun média} =1{1 média} other{{count} médias}}'**
  String galleryCount(int count);

  /// No description provided for @gallerySelectedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 sélectionné} other{{count} sélectionnés}}'**
  String gallerySelectedCount(int count);

  /// No description provided for @gallerySelectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get gallerySelectAll;

  /// No description provided for @galleryClearSelection.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la sélection'**
  String get galleryClearSelection;

  /// No description provided for @galleryRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la bibliothèque'**
  String get galleryRemove;

  /// No description provided for @galleryRemoveTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Retirer ce média ?} other{Retirer ces {count} médias ?}}'**
  String galleryRemoveTitle(int count);

  /// No description provided for @galleryRemoveBody.
  ///
  /// In fr, this message translates to:
  /// **'Les copies de travail et les miniatures du studio seront effacées. Vos fichiers originaux ne sont pas touchés.'**
  String get galleryRemoveBody;

  /// No description provided for @galleryRemoveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get galleryRemoveConfirm;

  /// No description provided for @galleryRemoved.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 média retiré} other{{count} médias retirés}}'**
  String galleryRemoved(int count);

  /// No description provided for @galleryDropHere.
  ///
  /// In fr, this message translates to:
  /// **'Déposez vos fichiers pour les importer'**
  String get galleryDropHere;

  /// No description provided for @galleryVideoBadge.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get galleryVideoBadge;

  /// No description provided for @importProgress.
  ///
  /// In fr, this message translates to:
  /// **'Import en cours : {done} sur {total}'**
  String importProgress(int done, int total);

  /// No description provided for @importStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get importStop;

  /// No description provided for @importSummary.
  ///
  /// In fr, this message translates to:
  /// **'Import terminé : {imported} importé(s), {duplicates} déjà présent(s), {unsupported} non pris en charge, {failed} en échec.'**
  String importSummary(
    int imported,
    int duplicates,
    int unsupported,
    int failed,
  );

  /// No description provided for @importCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Import arrêté : {imported} importé(s) avant l\'arrêt.'**
  String importCancelled(int imported);

  /// No description provided for @importPickerError.
  ///
  /// In fr, this message translates to:
  /// **'Le sélecteur de fichiers n\'a pas pu s\'ouvrir : {message}'**
  String importPickerError(String message);

  /// No description provided for @importDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get importDetails;

  /// No description provided for @importReportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport d\'import'**
  String get importReportTitle;

  /// No description provided for @importOutcomeImported.
  ///
  /// In fr, this message translates to:
  /// **'Importé'**
  String get importOutcomeImported;

  /// No description provided for @importOutcomeDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Déjà présent dans la bibliothèque'**
  String get importOutcomeDuplicate;

  /// No description provided for @importOutcomeUnsupported.
  ///
  /// In fr, this message translates to:
  /// **'Format non pris en charge'**
  String get importOutcomeUnsupported;

  /// No description provided for @importOutcomeFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec'**
  String get importOutcomeFailed;

  /// No description provided for @viewerInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get viewerInfo;

  /// No description provided for @viewerOpenExternal.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir avec l\'application du système'**
  String get viewerOpenExternal;

  /// No description provided for @viewerOpenExternalFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le fichier avec le système.'**
  String get viewerOpenExternalFailed;

  /// No description provided for @viewerPreviewUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu indisponible pour ce format sur cette plateforme.'**
  String get viewerPreviewUnavailable;

  /// No description provided for @viewerVideoUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La lecture vidéo intégrée n\'est pas disponible sous Linux dans cette version (aucun moteur vidéo installé). Vous pouvez ouvrir la vidéo avec le lecteur du système.'**
  String get viewerVideoUnavailable;

  /// No description provided for @viewerVideoError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire cette vidéo : {message}'**
  String viewerVideoError(String message);

  /// No description provided for @viewerPlay.
  ///
  /// In fr, this message translates to:
  /// **'Lecture'**
  String get viewerPlay;

  /// No description provided for @viewerPause.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get viewerPause;

  /// No description provided for @viewerNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ce média n\'existe plus dans la bibliothèque.'**
  String get viewerNotFound;

  /// No description provided for @viewerFileMissing.
  ///
  /// In fr, this message translates to:
  /// **'La copie de travail de ce média est introuvable.'**
  String get viewerFileMissing;

  /// No description provided for @metaFileName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get metaFileName;

  /// No description provided for @metaType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get metaType;

  /// No description provided for @metaSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get metaSize;

  /// No description provided for @metaDimensions.
  ///
  /// In fr, this message translates to:
  /// **'Dimensions'**
  String get metaDimensions;

  /// No description provided for @metaDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get metaDuration;

  /// No description provided for @metaTakenAt.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get metaTakenAt;

  /// No description provided for @metaImportedAt.
  ///
  /// In fr, this message translates to:
  /// **'Importé le'**
  String get metaImportedAt;

  /// No description provided for @metaCamera.
  ///
  /// In fr, this message translates to:
  /// **'Appareil'**
  String get metaCamera;

  /// No description provided for @metaGps.
  ///
  /// In fr, this message translates to:
  /// **'Position GPS'**
  String get metaGps;

  /// No description provided for @metaGpsPresent.
  ///
  /// In fr, this message translates to:
  /// **'Présente : elle sera visible par tous si l\'image est publiée telle quelle.'**
  String get metaGpsPresent;

  /// No description provided for @metaGpsAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Absente'**
  String get metaGpsAbsent;

  /// No description provided for @metaSha256.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte SHA-256'**
  String get metaSha256;

  /// No description provided for @metaSource.
  ///
  /// In fr, this message translates to:
  /// **'Provenance'**
  String get metaSource;

  /// No description provided for @metaUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Inconnue'**
  String get metaUnknown;

  /// No description provided for @metaVideoUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Métadonnées vidéo indisponibles sur cette plateforme.'**
  String get metaVideoUnavailable;

  /// No description provided for @commonOpenInBrowser.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir dans le navigateur'**
  String get commonOpenInBrowser;

  /// No description provided for @commonCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get commonCopy;

  /// No description provided for @commonCopied.
  ///
  /// In fr, this message translates to:
  /// **'Copié'**
  String get commonCopied;

  /// No description provided for @commonContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get commonContinue;

  /// No description provided for @commonBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get commonBack;

  /// No description provided for @commonRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get commonRefresh;

  /// No description provided for @commonUnknownError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inattendue : {message}'**
  String commonUnknownError(String message);

  /// No description provided for @ghConnectTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion à GitHub'**
  String get ghConnectTitle;

  /// No description provided for @ghConnectIntro.
  ///
  /// In fr, this message translates to:
  /// **'Le jeton est vérifié auprès de GitHub puis conservé uniquement dans le trousseau sécurisé du système, jamais dans la base locale ni dans les journaux.'**
  String get ghConnectIntro;

  /// No description provided for @ghStoreUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le trousseau sécurisé du système est inaccessible. Sous Linux, vérifiez qu\'un service de secrets (GNOME Keyring, KWallet…) est actif et déverrouillé. Sans lui, aucun identifiant ne peut être enregistré.'**
  String get ghStoreUnavailable;

  /// No description provided for @ghPatTitle.
  ///
  /// In fr, this message translates to:
  /// **'Jeton d\'accès personnel (recommandé)'**
  String get ghPatTitle;

  /// No description provided for @ghPatHelp.
  ///
  /// In fr, this message translates to:
  /// **'Créez un jeton « fine-grained » limité aux seuls dépôts voulus, avec la permission Contents en lecture et écriture (Metadata en lecture est ajouté automatiquement). Pour créer des dépôts depuis l\'application, ajoutez Administration en écriture.'**
  String get ghPatHelp;

  /// No description provided for @ghPatCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer un jeton sur GitHub'**
  String get ghPatCreate;

  /// No description provided for @ghPatField.
  ///
  /// In fr, this message translates to:
  /// **'Jeton GitHub'**
  String get ghPatField;

  /// No description provided for @ghPatConnect.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier et se connecter'**
  String get ghPatConnect;

  /// No description provided for @ghDeviceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion par le navigateur'**
  String get ghDeviceTitle;

  /// No description provided for @ghDeviceHelp.
  ///
  /// In fr, this message translates to:
  /// **'Nécessite l\'identifiant client (Client ID) d\'une application OAuth ou GitHub App dont le « Device Flow » est activé. Aucun secret n\'est requis.'**
  String get ghDeviceHelp;

  /// No description provided for @ghDeviceClientId.
  ///
  /// In fr, this message translates to:
  /// **'Client ID'**
  String get ghDeviceClientId;

  /// No description provided for @ghDeviceStart.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec le navigateur'**
  String get ghDeviceStart;

  /// No description provided for @ghDeviceCodeIntro.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez ce code sur la page GitHub qui vient de s\'ouvrir :'**
  String get ghDeviceCodeIntro;

  /// No description provided for @ghDeviceWaiting.
  ///
  /// In fr, this message translates to:
  /// **'En attente de votre autorisation…'**
  String get ghDeviceWaiting;

  /// No description provided for @ghDeviceDenied.
  ///
  /// In fr, this message translates to:
  /// **'Autorisation refusée ou annulée.'**
  String get ghDeviceDenied;

  /// No description provided for @ghDeviceExpired.
  ///
  /// In fr, this message translates to:
  /// **'Le code a expiré. Recommencez.'**
  String get ghDeviceExpired;

  /// No description provided for @ghDeviceMisconfigured.
  ///
  /// In fr, this message translates to:
  /// **'Configuration refusée par GitHub : {detail}'**
  String ghDeviceMisconfigured(String detail);

  /// No description provided for @ghConnectedAs.
  ///
  /// In fr, this message translates to:
  /// **'Connecté en tant que {login}'**
  String ghConnectedAs(String login);

  /// No description provided for @ghTokenFineGrained.
  ///
  /// In fr, this message translates to:
  /// **'Jeton fine-grained ou GitHub App : permissions définies sur GitHub'**
  String get ghTokenFineGrained;

  /// No description provided for @ghTokenScopes.
  ///
  /// In fr, this message translates to:
  /// **'Portées du jeton : {scopes}'**
  String ghTokenScopes(String scopes);

  /// No description provided for @ghTokenExpires.
  ///
  /// In fr, this message translates to:
  /// **'Expire le {date}'**
  String ghTokenExpires(String date);

  /// No description provided for @ghDisconnect.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get ghDisconnect;

  /// No description provided for @ghDisconnectTitle.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter de GitHub ?'**
  String get ghDisconnectTitle;

  /// No description provided for @ghDisconnectBody.
  ///
  /// In fr, this message translates to:
  /// **'Le jeton sera effacé du trousseau de cet appareil. Pour le révoquer définitivement, supprimez-le aussi dans les paramètres de votre compte GitHub.'**
  String get ghDisconnectBody;

  /// No description provided for @ghRevokePage.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mes jetons sur GitHub'**
  String get ghRevokePage;

  /// No description provided for @ghSessionError.
  ///
  /// In fr, this message translates to:
  /// **'Le jeton enregistré n\'a pas pu être vérifié.'**
  String get ghSessionError;

  /// No description provided for @ghRepos.
  ///
  /// In fr, this message translates to:
  /// **'Dépôts'**
  String get ghRepos;

  /// No description provided for @ghReposSearch.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer les dépôts'**
  String get ghReposSearch;

  /// No description provided for @ghReposEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun dépôt accessible avec ce jeton.'**
  String get ghReposEmpty;

  /// No description provided for @ghPrivate.
  ///
  /// In fr, this message translates to:
  /// **'Privé'**
  String get ghPrivate;

  /// No description provided for @ghPublic.
  ///
  /// In fr, this message translates to:
  /// **'Public'**
  String get ghPublic;

  /// No description provided for @ghReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule'**
  String get ghReadOnly;

  /// No description provided for @ghActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get ghActive;

  /// No description provided for @ghNewRepo.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau dépôt'**
  String get ghNewRepo;

  /// No description provided for @ghNewRepoName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du dépôt'**
  String get ghNewRepoName;

  /// No description provided for @ghNewRepoNameInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Lettres, chiffres, « - », « _ » et « . » uniquement (100 caractères maximum).'**
  String get ghNewRepoNameInvalid;

  /// No description provided for @ghNewRepoDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description (facultative)'**
  String get ghNewRepoDescription;

  /// No description provided for @ghNewRepoPrivate.
  ///
  /// In fr, this message translates to:
  /// **'Privé : visible par vous et les personnes invitées'**
  String get ghNewRepoPrivate;

  /// No description provided for @ghNewRepoPublic.
  ///
  /// In fr, this message translates to:
  /// **'Public : visible par tout le monde sur Internet'**
  String get ghNewRepoPublic;

  /// No description provided for @ghNewRepoCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get ghNewRepoCreate;

  /// No description provided for @ghNewRepoPublicConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un dépôt public ?'**
  String get ghNewRepoPublicConfirmTitle;

  /// No description provided for @ghNewRepoPublicConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Tout ce que vous publierez dans « {name} » sera visible par n\'importe qui, y compris les métadonnées des photos (position GPS…).'**
  String ghNewRepoPublicConfirmBody(String name);

  /// No description provided for @ghNewRepoPublicConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Oui, créer un dépôt public'**
  String get ghNewRepoPublicConfirm;

  /// No description provided for @ghNewRepoCreated.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt {name} créé.'**
  String ghNewRepoCreated(String name);

  /// No description provided for @ghBranch.
  ///
  /// In fr, this message translates to:
  /// **'Branche'**
  String get ghBranch;

  /// No description provided for @ghRoot.
  ///
  /// In fr, this message translates to:
  /// **'Racine'**
  String get ghRoot;

  /// No description provided for @ghFolderEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Dossier vide.'**
  String get ghFolderEmpty;

  /// No description provided for @ghRepoEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Ce dépôt ne contient encore aucun fichier.'**
  String get ghRepoEmpty;

  /// No description provided for @ghCommits.
  ///
  /// In fr, this message translates to:
  /// **'Derniers commits'**
  String get ghCommits;

  /// No description provided for @ghSetActive.
  ///
  /// In fr, this message translates to:
  /// **'Définir comme dépôt actif'**
  String get ghSetActive;

  /// No description provided for @ghActiveSet.
  ///
  /// In fr, this message translates to:
  /// **'{name} est maintenant le dépôt actif.'**
  String ghActiveSet(String name);

  /// No description provided for @ghPublishHere.
  ///
  /// In fr, this message translates to:
  /// **'Publier ici'**
  String get ghPublishHere;

  /// No description provided for @errUnauthorized.
  ///
  /// In fr, this message translates to:
  /// **'GitHub refuse le jeton : il est invalide, expiré ou révoqué. Reconnectez-vous avec un nouveau jeton.'**
  String get errUnauthorized;

  /// No description provided for @errForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Permission insuffisante. Pour un jeton fine-grained, vérifiez que ce dépôt est inclus et que la permission nécessaire (Contents en écriture, ou Administration pour créer un dépôt) est accordée. Détail : {detail}'**
  String errForbidden(String detail);

  /// No description provided for @errNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Introuvable. Le dépôt, la branche ou le dossier n\'existe pas, ou votre jeton n\'y a pas accès.'**
  String get errNotFound;

  /// No description provided for @errRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Limite de requêtes GitHub atteinte. Réessayez après {time}.'**
  String errRateLimited(String time);

  /// No description provided for @errRateLimitedNoTime.
  ///
  /// In fr, this message translates to:
  /// **'Limite de requêtes GitHub atteinte. Réessayez dans quelques minutes.'**
  String get errRateLimitedNoTime;

  /// No description provided for @errConflict.
  ///
  /// In fr, this message translates to:
  /// **'La branche a été modifiée sur GitHub pendant la publication. Rien n\'a été publié : relancez l\'analyse pour tenir compte des nouveautés.'**
  String get errConflict;

  /// No description provided for @errEmptyRepository.
  ///
  /// In fr, this message translates to:
  /// **'Ce dépôt est vide.'**
  String get errEmptyRepository;

  /// No description provided for @errValidation.
  ///
  /// In fr, this message translates to:
  /// **'GitHub a refusé la demande : {detail}'**
  String errValidation(String detail);

  /// No description provided for @errNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Connexion à GitHub impossible. Vérifiez votre accès à Internet. ({detail})'**
  String errNetwork(String detail);

  /// No description provided for @errServer.
  ///
  /// In fr, this message translates to:
  /// **'GitHub rencontre un problème (erreur serveur). Réessayez plus tard.'**
  String get errServer;

  /// No description provided for @pubNotConnected.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à GitHub pour publier.'**
  String get pubNotConnected;

  /// No description provided for @pubGoToGithub.
  ///
  /// In fr, this message translates to:
  /// **'Aller à l\'écran GitHub'**
  String get pubGoToGithub;

  /// No description provided for @pubNoMedia.
  ///
  /// In fr, this message translates to:
  /// **'Votre bibliothèque est vide : importez d\'abord des médias dans la galerie.'**
  String get pubNoMedia;

  /// No description provided for @pubStepMedia.
  ///
  /// In fr, this message translates to:
  /// **'Médias'**
  String get pubStepMedia;

  /// No description provided for @pubStepDestination.
  ///
  /// In fr, this message translates to:
  /// **'Destination'**
  String get pubStepDestination;

  /// No description provided for @pubStepAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Analyse'**
  String get pubStepAnalysis;

  /// No description provided for @pubStepMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get pubStepMessage;

  /// No description provided for @pubStepReview.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get pubStepReview;

  /// No description provided for @pubStepResult.
  ///
  /// In fr, this message translates to:
  /// **'Résultat'**
  String get pubStepResult;

  /// No description provided for @pubSelectedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun média sélectionné} =1{1 média sélectionné} other{{count} médias sélectionnés}}'**
  String pubSelectedCount(int count);

  /// No description provided for @pubRepository.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt'**
  String get pubRepository;

  /// No description provided for @pubChooseRepository.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un dépôt'**
  String get pubChooseRepository;

  /// No description provided for @pubFolder.
  ///
  /// In fr, this message translates to:
  /// **'Dossier dans le dépôt'**
  String get pubFolder;

  /// No description provided for @pubFolderHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : photos/2024. Un dossier inexistant sera créé par l\'ajout des fichiers. Laisser vide pour la racine.'**
  String get pubFolderHelp;

  /// No description provided for @pubFolderInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Chemin invalide (pas de « .. », de « .git » ni de caractères spéciaux).'**
  String get pubFolderInvalid;

  /// No description provided for @pubEmptyRepoNote.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt vide : les fichiers seront publiés un par un (un commit par fichier), sur la branche par défaut.'**
  String get pubEmptyRepoNote;

  /// No description provided for @pubAnalyze.
  ///
  /// In fr, this message translates to:
  /// **'Analyser'**
  String get pubAnalyze;

  /// No description provided for @pubAnalyzing.
  ///
  /// In fr, this message translates to:
  /// **'Analyse : {done} sur {total}'**
  String pubAnalyzing(int done, int total);

  /// No description provided for @pubActionAdd.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get pubActionAdd;

  /// No description provided for @pubActionSkip.
  ///
  /// In fr, this message translates to:
  /// **'Identique sur GitHub — ignoré'**
  String get pubActionSkip;

  /// No description provided for @pubActionRenamed.
  ///
  /// In fr, this message translates to:
  /// **'Nom déjà pris — publié sous un autre nom'**
  String get pubActionRenamed;

  /// No description provided for @pubActionOverwrite.
  ///
  /// In fr, this message translates to:
  /// **'Remplacera le fichier existant'**
  String get pubActionOverwrite;

  /// No description provided for @pubBlockedLfs.
  ///
  /// In fr, this message translates to:
  /// **'Plus de 100 Mio alors que Git LFS est désactivé dans les paramètres'**
  String get pubBlockedLfs;

  /// No description provided for @pubBlockedPath.
  ///
  /// In fr, this message translates to:
  /// **'Nom de fichier incompatible avec un dépôt'**
  String get pubBlockedPath;

  /// No description provided for @pubWarnLarge.
  ///
  /// In fr, this message translates to:
  /// **'Volumineux (plus de 50 Mio) : GitHub le signalera'**
  String get pubWarnLarge;

  /// No description provided for @pubWarnGpsPublic.
  ///
  /// In fr, this message translates to:
  /// **'Contient une position GPS et le dépôt est public'**
  String get pubWarnGpsPublic;

  /// No description provided for @pubOverwriteToggle.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer plutôt que renommer'**
  String get pubOverwriteToggle;

  /// No description provided for @pubTruncatedTree.
  ///
  /// In fr, this message translates to:
  /// **'Le dépôt est très volumineux : l\'analyse des conflits est partielle. GitHub n\'écrasera toutefois rien sans que ce soit prévu.'**
  String get pubTruncatedTree;

  /// No description provided for @pubOptimizationNote.
  ///
  /// In fr, this message translates to:
  /// **'Optimisation des images avant publication : disponible en phase 4.'**
  String get pubOptimizationNote;

  /// No description provided for @pubSummaryCounts.
  ///
  /// In fr, this message translates to:
  /// **'{upload} à envoyer ({size}), {skipped} ignoré(s), {blocked} bloqué(s)'**
  String pubSummaryCounts(int upload, String size, int skipped, int blocked);

  /// No description provided for @pubNothingToUpload.
  ///
  /// In fr, this message translates to:
  /// **'Rien à publier : tous les fichiers sont déjà présents ou bloqués.'**
  String get pubNothingToUpload;

  /// No description provided for @pubMessageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Message de commit'**
  String get pubMessageLabel;

  /// No description provided for @pubMessageDefault.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Ajout d\'un média via GitPhoto Studio} other{Ajout de {count} médias via GitPhoto Studio}}'**
  String pubMessageDefault(int count);

  /// No description provided for @pubMessageEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Le message ne peut pas être vide.'**
  String get pubMessageEmpty;

  /// No description provided for @pubReviewIntro.
  ///
  /// In fr, this message translates to:
  /// **'Voici exactement ce qui sera envoyé :'**
  String get pubReviewIntro;

  /// No description provided for @pubReviewTarget.
  ///
  /// In fr, this message translates to:
  /// **'{repo} · branche {branch}'**
  String pubReviewTarget(String repo, String branch);

  /// No description provided for @pubReviewSingleCommit.
  ///
  /// In fr, this message translates to:
  /// **'Tous les fichiers seront ajoutés en un seul commit.'**
  String get pubReviewSingleCommit;

  /// No description provided for @pubReviewOverwriteWarning.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 fichier existant sera remplacé.} other{{count} fichiers existants seront remplacés.}} L\'ancienne version reste consultable dans l\'historique Git.'**
  String pubReviewOverwriteWarning(int count);

  /// No description provided for @pubConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Publier sur GitHub'**
  String get pubConfirm;

  /// No description provided for @pubConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la publication ?'**
  String get pubConfirmTitle;

  /// No description provided for @pubConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 fichier sera publié} other{{count} fichiers seront publiés}} dans {repo} ({visibility}).'**
  String pubConfirmBody(int count, String repo, String visibility);

  /// No description provided for @pubStepUploading.
  ///
  /// In fr, this message translates to:
  /// **'Envoi des fichiers : {done} sur {total}'**
  String pubStepUploading(int done, int total);

  /// No description provided for @pubStepCommitting.
  ///
  /// In fr, this message translates to:
  /// **'Création du commit…'**
  String get pubStepCommitting;

  /// No description provided for @pubStepUpdating.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour de la branche…'**
  String get pubStepUpdating;

  /// No description provided for @pubStepVerifying.
  ///
  /// In fr, this message translates to:
  /// **'Vérification sur GitHub…'**
  String get pubStepVerifying;

  /// No description provided for @pubSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Publication réussie'**
  String get pubSuccess;

  /// No description provided for @pubVerified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié : les fichiers sont présents sur GitHub avec le contenu attendu.'**
  String get pubVerified;

  /// No description provided for @pubNotVerified.
  ///
  /// In fr, this message translates to:
  /// **'Publié, mais la vérification distante n\'a pas pu confirmer tous les fichiers. Consultez le commit sur GitHub.'**
  String get pubNotVerified;

  /// No description provided for @pubCommit.
  ///
  /// In fr, this message translates to:
  /// **'Commit {sha}'**
  String pubCommit(String sha);

  /// No description provided for @pubFailed.
  ///
  /// In fr, this message translates to:
  /// **'La publication a échoué'**
  String get pubFailed;

  /// No description provided for @pubNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle publication'**
  String get pubNew;

  /// No description provided for @histEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération pour l\'instant.'**
  String get histEmpty;

  /// No description provided for @histStatusRunning.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get histStatusRunning;

  /// No description provided for @histStatusSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Réussie'**
  String get histStatusSuccess;

  /// No description provided for @histStatusFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échouée'**
  String get histStatusFailed;

  /// No description provided for @histStatusInterrupted.
  ///
  /// In fr, this message translates to:
  /// **'Interrompue'**
  String get histStatusInterrupted;

  /// No description provided for @histInterruptedHelp.
  ///
  /// In fr, this message translates to:
  /// **'L\'application a été fermée pendant l\'opération : son résultat est inconnu. Vérifiez le dépôt sur GitHub ; une nouvelle analyse ignorera les fichiers déjà publiés.'**
  String get histInterruptedHelp;

  /// No description provided for @histFiles.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 fichier} other{{count} fichiers}}'**
  String histFiles(int count);

  /// No description provided for @histRetryNote.
  ///
  /// In fr, this message translates to:
  /// **'Une publication échouée ou interrompue peut être reprise : seuls les fichiers absents de GitHub sont envoyés, sans doublon. Après une perte de connexion, l\'application réessaie d\'elle-même deux fois.'**
  String get histRetryNote;

  /// No description provided for @histError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get histError;

  /// No description provided for @dashNoCommitsConnect.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à GitHub et choisissez un dépôt actif pour voir ses derniers commits.'**
  String get dashNoCommitsConnect;

  /// No description provided for @settingsGithub.
  ///
  /// In fr, this message translates to:
  /// **'Compte GitHub'**
  String get settingsGithub;

  /// No description provided for @settingsGithubNotConnected.
  ///
  /// In fr, this message translates to:
  /// **'Non connecté'**
  String get settingsGithubNotConnected;

  /// No description provided for @pixelPublishTip.
  ///
  /// In fr, this message translates to:
  /// **'Astuce : vérifiez la colonne GPS avant de publier dans un dépôt public.'**
  String get pixelPublishTip;

  /// No description provided for @editorChooseMedia.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un média à retoucher'**
  String get editorChooseMedia;

  /// No description provided for @editorNoMedia.
  ///
  /// In fr, this message translates to:
  /// **'Importez d\'abord des médias dans la galerie.'**
  String get editorNoMedia;

  /// No description provided for @editorOriginalsSafe.
  ///
  /// In fr, this message translates to:
  /// **'Chaque traitement crée une nouvelle version : l\'original n\'est jamais modifié.'**
  String get editorOriginalsSafe;

  /// No description provided for @editorFileName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du fichier'**
  String get editorFileName;

  /// No description provided for @editorRename.
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get editorRename;

  /// No description provided for @editorRenamed.
  ///
  /// In fr, this message translates to:
  /// **'Média renommé.'**
  String get editorRenamed;

  /// No description provided for @editorRenameInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Nom de fichier invalide.'**
  String get editorRenameInvalid;

  /// No description provided for @editorAlbum.
  ///
  /// In fr, this message translates to:
  /// **'Album'**
  String get editorAlbum;

  /// No description provided for @editorNoAlbum.
  ///
  /// In fr, this message translates to:
  /// **'Aucun album'**
  String get editorNoAlbum;

  /// No description provided for @editorVersionOf.
  ///
  /// In fr, this message translates to:
  /// **'Version de « {name} »'**
  String editorVersionOf(String name);

  /// No description provided for @editorImageSection.
  ///
  /// In fr, this message translates to:
  /// **'Optimisation de l\'image'**
  String get editorImageSection;

  /// No description provided for @presetWeb.
  ///
  /// In fr, this message translates to:
  /// **'Web (1920 px)'**
  String get presetWeb;

  /// No description provided for @presetLight.
  ///
  /// In fr, this message translates to:
  /// **'Léger (1280 px)'**
  String get presetLight;

  /// No description provided for @presetThumbnail.
  ///
  /// In fr, this message translates to:
  /// **'Miniature (400 px)'**
  String get presetThumbnail;

  /// No description provided for @presetCustom.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisé'**
  String get presetCustom;

  /// No description provided for @editorMaxDimension.
  ///
  /// In fr, this message translates to:
  /// **'Plus grand côté : {px} px'**
  String editorMaxDimension(int px);

  /// No description provided for @editorKeepDimensions.
  ///
  /// In fr, this message translates to:
  /// **'Garder les dimensions d\'origine'**
  String get editorKeepDimensions;

  /// No description provided for @editorFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format'**
  String get editorFormat;

  /// No description provided for @editorQuality.
  ///
  /// In fr, this message translates to:
  /// **'Qualité : {quality} %'**
  String editorQuality(int quality);

  /// No description provided for @editorMetadata.
  ///
  /// In fr, this message translates to:
  /// **'Métadonnées'**
  String get editorMetadata;

  /// No description provided for @metaStripAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout retirer (recommandé pour publier)'**
  String get metaStripAll;

  /// No description provided for @metaKeepBasic.
  ///
  /// In fr, this message translates to:
  /// **'Garder date et appareil (jamais le GPS)'**
  String get metaKeepBasic;

  /// No description provided for @editorPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get editorPreview;

  /// No description provided for @editorPreviewing.
  ///
  /// In fr, this message translates to:
  /// **'Calcul de l\'aperçu…'**
  String get editorPreviewing;

  /// No description provided for @editorOriginal.
  ///
  /// In fr, this message translates to:
  /// **'Original'**
  String get editorOriginal;

  /// No description provided for @editorResult.
  ///
  /// In fr, this message translates to:
  /// **'Résultat'**
  String get editorResult;

  /// No description provided for @editorSizeChange.
  ///
  /// In fr, this message translates to:
  /// **'{original} → {result} ({change})'**
  String editorSizeChange(String original, String result, String change);

  /// No description provided for @editorSaveVersion.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer comme nouvelle version'**
  String get editorSaveVersion;

  /// No description provided for @editorVersionSaved.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle version créée : {name}'**
  String editorVersionSaved(String name);

  /// No description provided for @editorVersionDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Une version identique existe déjà dans la bibliothèque.'**
  String get editorVersionDuplicate;

  /// No description provided for @editorVideoSection.
  ///
  /// In fr, this message translates to:
  /// **'Préparation de la vidéo'**
  String get editorVideoSection;

  /// No description provided for @videoPresetLight.
  ///
  /// In fr, this message translates to:
  /// **'Légère (480p)'**
  String get videoPresetLight;

  /// No description provided for @videoPreset720.
  ///
  /// In fr, this message translates to:
  /// **'720p'**
  String get videoPreset720;

  /// No description provided for @videoPreset1080.
  ///
  /// In fr, this message translates to:
  /// **'1080p'**
  String get videoPreset1080;

  /// No description provided for @videoRemoveAudio.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le son'**
  String get videoRemoveAudio;

  /// No description provided for @videoEstimate.
  ///
  /// In fr, this message translates to:
  /// **'Taille estimée : {size} (original : {original})'**
  String videoEstimate(String size, String original);

  /// No description provided for @videoEstimateUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Taille estimée inconnue : durée de la vidéo non disponible.'**
  String get videoEstimateUnknown;

  /// No description provided for @videoEngine.
  ///
  /// In fr, this message translates to:
  /// **'Moteur : {engine}'**
  String videoEngine(String engine);

  /// No description provided for @videoConvert.
  ///
  /// In fr, this message translates to:
  /// **'Convertir en MP4'**
  String get videoConvert;

  /// No description provided for @videoConverting.
  ///
  /// In fr, this message translates to:
  /// **'Conversion en cours… {percent} %'**
  String videoConverting(int percent);

  /// No description provided for @videoUnavailableLinux.
  ///
  /// In fr, this message translates to:
  /// **'Conversion vidéo indisponible : ffmpeg n\'est pas installé. Installez-le avec « sudo apt install ffmpeg », puis relancez la détection dans Paramètres › Diagnostic.'**
  String get videoUnavailableLinux;

  /// No description provided for @videoUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Conversion vidéo indisponible sur cette plateforme.'**
  String get videoUnavailable;

  /// No description provided for @jobStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get jobStop;

  /// No description provided for @jobBatchProgress.
  ///
  /// In fr, this message translates to:
  /// **'Optimisation : {done} sur {total}'**
  String jobBatchProgress(int done, int total);

  /// No description provided for @jobDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune version créée} =1{1 version créée} other{{count} versions créées}}'**
  String jobDone(int count);

  /// No description provided for @jobCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Traitement arrêté.'**
  String get jobCancelled;

  /// No description provided for @jobFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec : {message}'**
  String jobFailed(String message);

  /// No description provided for @dupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Doublons probables'**
  String get dupTitle;

  /// No description provided for @dupHelp.
  ///
  /// In fr, this message translates to:
  /// **'Images visuellement très proches (redimensionnées, recompressées…). Les copies exactes sont déjà refusées à l\'import.'**
  String get dupHelp;

  /// No description provided for @dupNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun doublon probable.'**
  String get dupNone;

  /// No description provided for @dupGroup.
  ///
  /// In fr, this message translates to:
  /// **'{count} images semblables'**
  String dupGroup(int count);

  /// No description provided for @dupRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get dupRemove;

  /// No description provided for @dupAnalyzing.
  ///
  /// In fr, this message translates to:
  /// **'Analyse des images…'**
  String get dupAnalyzing;

  /// No description provided for @dupRemoveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer « {name} » ?'**
  String dupRemoveTitle(String name);

  /// No description provided for @albumsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Albums'**
  String get albumsTitle;

  /// No description provided for @albumsNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun album pour l\'instant.'**
  String get albumsNone;

  /// No description provided for @albumNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel album'**
  String get albumNew;

  /// No description provided for @albumName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'album'**
  String get albumName;

  /// No description provided for @albumCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get albumCreate;

  /// No description provided for @albumRename.
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get albumRename;

  /// No description provided for @albumDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'album'**
  String get albumDelete;

  /// No description provided for @albumDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Les médias de « {name} » restent dans la bibliothèque, simplement hors album.'**
  String albumDeleteBody(String name);

  /// No description provided for @albumCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{vide} =1{1 média} other{{count} médias}}'**
  String albumCount(int count);

  /// No description provided for @albumAutoOrganize.
  ///
  /// In fr, this message translates to:
  /// **'Classer par année et mois'**
  String get albumAutoOrganize;

  /// No description provided for @albumAutoOrganizeBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun média hors album à classer.} =1{1 média hors album sera rangé dans un album « AAAA-MM » selon sa date.} other{{count} médias hors album seront rangés dans des albums « AAAA-MM » selon leur date.}}'**
  String albumAutoOrganizeBody(int count);

  /// No description provided for @albumAutoOrganized.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 média classé} other{{count} médias classés}}'**
  String albumAutoOrganized(int count);

  /// No description provided for @galleryOptimize.
  ///
  /// In fr, this message translates to:
  /// **'Optimiser'**
  String get galleryOptimize;

  /// No description provided for @galleryOptimizeTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Optimiser l\'image sélectionnée} other{Optimiser les {count} images sélectionnées}}'**
  String galleryOptimizeTitle(int count);

  /// No description provided for @galleryOptimizeVideosIgnored.
  ///
  /// In fr, this message translates to:
  /// **'Les vidéos sélectionnées sont ignorées : préparez-les une par une dans l\'éditeur.'**
  String get galleryOptimizeVideosIgnored;

  /// No description provided for @galleryAddToAlbum.
  ///
  /// In fr, this message translates to:
  /// **'Ranger dans un album'**
  String get galleryAddToAlbum;

  /// No description provided for @galleryAllAlbums.
  ///
  /// In fr, this message translates to:
  /// **'Tous les albums'**
  String get galleryAllAlbums;

  /// No description provided for @galleryMovedToAlbum.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 média rangé} other{{count} médias rangés}} dans « {name} »'**
  String galleryMovedToAlbum(int count, String name);

  /// No description provided for @viewerEdit.
  ///
  /// In fr, this message translates to:
  /// **'Retoucher'**
  String get viewerEdit;

  /// No description provided for @metaVersionOf.
  ///
  /// In fr, this message translates to:
  /// **'Version de'**
  String get metaVersionOf;

  /// No description provided for @diagFfmpeg.
  ///
  /// In fr, this message translates to:
  /// **'ffmpeg (vidéo)'**
  String get diagFfmpeg;

  /// No description provided for @videoNotSmaller.
  ///
  /// In fr, this message translates to:
  /// **'La conversion ne réduit pas la taille ({source} → {output}) : la version n\'a pas été conservée. La vidéo est sans doute déjà bien compressée ; essayez « Retirer le son » ou un préréglage plus bas.'**
  String videoNotSmaller(String source, String output);

  /// No description provided for @histStatusQueued.
  ///
  /// In fr, this message translates to:
  /// **'En file d\'attente'**
  String get histStatusQueued;

  /// No description provided for @histStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get histStatusCancelled;

  /// No description provided for @histResume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get histResume;

  /// No description provided for @histCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get histCancel;

  /// No description provided for @histCancelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler cette publication ?'**
  String get histCancelTitle;

  /// No description provided for @histCancelBody.
  ///
  /// In fr, this message translates to:
  /// **'Les fichiers pas encore publiés ne seront pas envoyés. Ce qui est déjà sur GitHub n\'est pas retiré.'**
  String get histCancelBody;

  /// No description provided for @histResumeNote.
  ///
  /// In fr, this message translates to:
  /// **'La reprise relit d\'abord GitHub : les fichiers déjà publiés ne sont jamais renvoyés.'**
  String get histResumeNote;

  /// No description provided for @histAttempts.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 tentative} other{{count} tentatives}}'**
  String histAttempts(int count);

  /// No description provided for @entryPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get entryPending;

  /// No description provided for @entryUploaded.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé, commit à finaliser'**
  String get entryUploaded;

  /// No description provided for @entryDone.
  ///
  /// In fr, this message translates to:
  /// **'Publié'**
  String get entryDone;

  /// No description provided for @entrySkipped.
  ///
  /// In fr, this message translates to:
  /// **'Déjà présent sur GitHub'**
  String get entrySkipped;

  /// No description provided for @entryFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec'**
  String get entryFailed;

  /// No description provided for @entryCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get entryCancelled;

  /// No description provided for @strategyApi.
  ///
  /// In fr, this message translates to:
  /// **'API'**
  String get strategyApi;

  /// No description provided for @strategyLfs.
  ///
  /// In fr, this message translates to:
  /// **'Git LFS'**
  String get strategyLfs;

  /// No description provided for @strategyGit.
  ///
  /// In fr, this message translates to:
  /// **'Git'**
  String get strategyGit;

  /// No description provided for @pubCancelRunning.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la publication'**
  String get pubCancelRunning;

  /// No description provided for @pubCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Publication annulée : rien n\'a été publié.'**
  String get pubCancelled;

  /// No description provided for @pubQueuedNote.
  ///
  /// In fr, this message translates to:
  /// **'La publication passe par la file d\'attente : vous pouvez quitter cet écran, elle se poursuit et reste visible dans l\'Historique.'**
  String get pubQueuedNote;

  /// No description provided for @pubViaLfs.
  ///
  /// In fr, this message translates to:
  /// **'Gros fichier : envoyé par Git LFS'**
  String get pubViaLfs;

  /// No description provided for @pubViaGit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé par Git natif'**
  String get pubViaGit;

  /// No description provided for @pubBlockedLfsMax.
  ///
  /// In fr, this message translates to:
  /// **'Plus de 2 Gio : dépasse la taille maximale d\'un fichier Git LFS chez GitHub (compte gratuit)'**
  String get pubBlockedLfsMax;

  /// No description provided for @pubLfsQuotaNote.
  ///
  /// In fr, this message translates to:
  /// **'Les fichiers Git LFS utilisent le quota de stockage LFS de votre compte GitHub.'**
  String get pubLfsQuotaNote;

  /// No description provided for @errDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'« {path} » est déjà en attente de publication vers ce dépôt.'**
  String errDuplicate(String path);

  /// No description provided for @errPathConflict.
  ///
  /// In fr, this message translates to:
  /// **'« {path} » a été modifié sur GitHub depuis l\'analyse. Rien n\'a été publié : relancez l\'analyse.'**
  String errPathConflict(String path);

  /// No description provided for @settingsPublishing.
  ///
  /// In fr, this message translates to:
  /// **'Publication'**
  String get settingsPublishing;

  /// No description provided for @settingsLfs.
  ///
  /// In fr, this message translates to:
  /// **'Git LFS pour les fichiers de plus de 50 Mio'**
  String get settingsLfs;

  /// No description provided for @settingsLfsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Recommandé. Fonctionne aussi sous Android, sans outil à installer. Utilise le quota LFS du compte GitHub.'**
  String get settingsLfsHelp;

  /// No description provided for @settingsNativeGit.
  ///
  /// In fr, this message translates to:
  /// **'Publier avec le Git de l\'ordinateur'**
  String get settingsNativeGit;

  /// No description provided for @settingsNativeGitHelp.
  ///
  /// In fr, this message translates to:
  /// **'Linux, si Git est détecté. Les gros fichiers passent toujours par Git LFS en HTTP.'**
  String get settingsNativeGitHelp;

  /// No description provided for @settingsNativeGitUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Git n\'est pas détecté sur cet appareil : l\'API GitHub est utilisée.'**
  String get settingsNativeGitUnavailable;

  /// No description provided for @agentDisabledTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'assistant IA est désactivé'**
  String get agentDisabledTitle;

  /// No description provided for @agentDisabledBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'application fonctionne entièrement sans IA. Pour utiliser l\'agent, activez-le et configurez un fournisseur (Mistral recommandé) dans les paramètres.'**
  String get agentDisabledBody;

  /// No description provided for @agentOpenSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les paramètres de l\'IA'**
  String get agentOpenSettings;

  /// No description provided for @agentNeedsKey.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez d\'abord une clé d\'API pour {provider} dans les paramètres.'**
  String agentNeedsKey(String provider);

  /// No description provided for @agentNeedsModel.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un modèle dans les paramètres.'**
  String get agentNeedsModel;

  /// No description provided for @agentConsentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avant de commencer'**
  String get agentConsentTitle;

  /// No description provided for @agentConsentBody.
  ///
  /// In fr, this message translates to:
  /// **'Pour comprendre vos demandes, l\'agent envoie à {provider} votre message et des métadonnées : noms de fichiers, tailles, dates, albums, dimensions, présence d\'une position GPS (jamais la position elle-même), noms de vos dépôts GitHub et historique des publications.\n\nAucune image ni vidéo n\'est envoyée. Aucun jeton ni aucune clé n\'est transmis au modèle.'**
  String agentConsentBody(String provider);

  /// No description provided for @agentConsentAccept.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte'**
  String get agentConsentAccept;

  /// No description provided for @agentInputHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : « Publie ces photos dans mon dépôt Portfolio »'**
  String get agentInputHint;

  /// No description provided for @agentSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get agentSend;

  /// No description provided for @agentThinking.
  ///
  /// In fr, this message translates to:
  /// **'L\'agent réfléchit…'**
  String get agentThinking;

  /// No description provided for @agentConsulting.
  ///
  /// In fr, this message translates to:
  /// **'L\'agent consulte : {tool}'**
  String agentConsulting(String tool);

  /// No description provided for @agentStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get agentStop;

  /// No description provided for @agentNewConversation.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle conversation'**
  String get agentNewConversation;

  /// No description provided for @agentExamplesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exemples de demandes'**
  String get agentExamplesTitle;

  /// No description provided for @agentExamples.
  ///
  /// In fr, this message translates to:
  /// **'Publie les photos sélectionnées dans mon dépôt Portfolio\nClasse mes images dans des albums par année et par mois\nRéduis la taille des photos sans trop perdre en qualité\nPrépare un album de voyage et génère un README\nExplique pourquoi ma dernière publication a échoué\nTrouve les doublons avant la publication\nQuelles vidéos passeront par Git LFS ?'**
  String get agentExamples;

  /// No description provided for @agentToolsUsed.
  ///
  /// In fr, this message translates to:
  /// **'Informations consultées : {tools}'**
  String agentToolsUsed(String tools);

  /// No description provided for @agentSafetyNote.
  ///
  /// In fr, this message translates to:
  /// **'L\'agent ne peut rien supprimer ni remplacer, et n\'agit qu\'après votre confirmation.'**
  String get agentSafetyNote;

  /// No description provided for @toolGetSelection.
  ///
  /// In fr, this message translates to:
  /// **'sélection'**
  String get toolGetSelection;

  /// No description provided for @toolSearchMedia.
  ///
  /// In fr, this message translates to:
  /// **'bibliothèque'**
  String get toolSearchMedia;

  /// No description provided for @toolListAlbums.
  ///
  /// In fr, this message translates to:
  /// **'albums'**
  String get toolListAlbums;

  /// No description provided for @toolFindSimilar.
  ///
  /// In fr, this message translates to:
  /// **'doublons'**
  String get toolFindSimilar;

  /// No description provided for @toolGithubStatus.
  ///
  /// In fr, this message translates to:
  /// **'GitHub'**
  String get toolGithubStatus;

  /// No description provided for @toolRecentOperations.
  ///
  /// In fr, this message translates to:
  /// **'historique'**
  String get toolRecentOperations;

  /// No description provided for @toolPreviewPublication.
  ///
  /// In fr, this message translates to:
  /// **'aperçu de publication'**
  String get toolPreviewPublication;

  /// No description provided for @planTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plan proposé'**
  String get planTitle;

  /// No description provided for @planMediaCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 média} other{{count} médias}}'**
  String planMediaCount(int count);

  /// No description provided for @planFromStep.
  ///
  /// In fr, this message translates to:
  /// **'les copies de l\'étape {step}'**
  String planFromStep(int step);

  /// No description provided for @planStepMove.
  ///
  /// In fr, this message translates to:
  /// **'Ranger {target} dans l\'album « {album} »'**
  String planStepMove(String target, String album);

  /// No description provided for @planStepOrganizeYear.
  ///
  /// In fr, this message translates to:
  /// **'Ranger {target} dans des albums par année'**
  String planStepOrganizeYear(String target);

  /// No description provided for @planStepOrganizeMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ranger {target} dans des albums par mois (AAAA-MM)'**
  String planStepOrganizeMonth(String target);

  /// No description provided for @planStepOptimize.
  ///
  /// In fr, this message translates to:
  /// **'Créer des versions optimisées de {count, plural, =1{1 image} other{{count} images}} — {preset}. Originaux conservés, métadonnées retirées.'**
  String planStepOptimize(int count, String preset);

  /// No description provided for @planStepConvert.
  ///
  /// In fr, this message translates to:
  /// **'Créer des versions converties de {count, plural, =1{1 vidéo} other{{count} vidéos}} — {preset}. Originaux conservés.'**
  String planStepConvert(int count, String preset);

  /// No description provided for @planStepPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier {target} dans {repo}, branche {branch}'**
  String planStepPublish(String target, String repo, String branch);

  /// No description provided for @planReadmeOnly.
  ///
  /// In fr, this message translates to:
  /// **'un README'**
  String get planReadmeOnly;

  /// No description provided for @planPublishFolder.
  ///
  /// In fr, this message translates to:
  /// **'Dossier : {folder}'**
  String planPublishFolder(String folder);

  /// No description provided for @planPublishRoot.
  ///
  /// In fr, this message translates to:
  /// **'Dossier : racine du dépôt'**
  String get planPublishRoot;

  /// No description provided for @planPublishMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message du commit : {message}'**
  String planPublishMessage(String message);

  /// No description provided for @planPublishReadme.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute un README.md au même commit'**
  String get planPublishReadme;

  /// No description provided for @planPublishSafety.
  ///
  /// In fr, this message translates to:
  /// **'Un seul commit. Aucun fichier existant n\'est remplacé (renommage en cas de conflit). Les fichiers déjà publiés à l\'identique sont ignorés.'**
  String get planPublishSafety;

  /// No description provided for @planWarnGps.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 photo publiée contient} other{{count} photos publiées contiennent}} une position GPS.'**
  String planWarnGps(int count);

  /// No description provided for @planWarnPublic.
  ///
  /// In fr, this message translates to:
  /// **'{repo} est un dépôt public : les fichiers seront visibles par tout le monde.'**
  String planWarnPublic(String repo);

  /// No description provided for @planWarnVideo.
  ///
  /// In fr, this message translates to:
  /// **'La conversion vidéo n\'est pas disponible sur cet appareil : cette étape échouera.'**
  String get planWarnVideo;

  /// No description provided for @planExecute.
  ///
  /// In fr, this message translates to:
  /// **'Exécuter le plan'**
  String get planExecute;

  /// No description provided for @planReject.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get planReject;

  /// No description provided for @planConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exécuter ce plan ?'**
  String get planConfirmTitle;

  /// No description provided for @planConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 action va être exécutée.} other{{count} actions vont être exécutées dans l\'ordre.}} Vous pourrez arrêter entre deux fichiers. Rien n\'est supprimé.'**
  String planConfirmBody(int count);

  /// No description provided for @planConfirmPublish.
  ///
  /// In fr, this message translates to:
  /// **'Des fichiers seront publiés sur GitHub.'**
  String get planConfirmPublish;

  /// No description provided for @planStatusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Plan refusé : rien n\'a été fait.'**
  String get planStatusRejected;

  /// No description provided for @planStatusExpired.
  ///
  /// In fr, this message translates to:
  /// **'Plan non confirmé, remplacé par votre nouvelle demande.'**
  String get planStatusExpired;

  /// No description provided for @planStatusRunning.
  ///
  /// In fr, this message translates to:
  /// **'Exécution en cours…'**
  String get planStatusRunning;

  /// No description provided for @planProgress.
  ///
  /// In fr, this message translates to:
  /// **'Étape {step} — {done}/{total}'**
  String planProgress(int step, int done, int total);

  /// No description provided for @planDoneOk.
  ///
  /// In fr, this message translates to:
  /// **'Plan exécuté et vérifié.'**
  String get planDoneOk;

  /// No description provided for @planDonePartial.
  ///
  /// In fr, this message translates to:
  /// **'Plan exécuté avec des réserves (voir le détail).'**
  String get planDonePartial;

  /// No description provided for @planDoneFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le plan n\'a pas pu être exécuté entièrement.'**
  String get planDoneFailed;

  /// No description provided for @planDoneCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Exécution arrêtée.'**
  String get planDoneCancelled;

  /// No description provided for @planArchived.
  ///
  /// In fr, this message translates to:
  /// **'Plan d\'une conversation précédente (ne peut plus être exécuté) : {summary}'**
  String planArchived(String summary);

  /// No description provided for @stepDone.
  ///
  /// In fr, this message translates to:
  /// **'Fait'**
  String get stepDone;

  /// No description provided for @stepPartial.
  ///
  /// In fr, this message translates to:
  /// **'Fait en partie'**
  String get stepPartial;

  /// No description provided for @stepFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec'**
  String get stepFailed;

  /// No description provided for @stepSkipped.
  ///
  /// In fr, this message translates to:
  /// **'Non exécutée'**
  String get stepSkipped;

  /// No description provided for @stepCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Arrêtée'**
  String get stepCancelled;

  /// No description provided for @stepAffected.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 élément traité} other{{count} éléments traités}}'**
  String stepAffected(int count);

  /// No description provided for @stepProduced.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 copie créée} other{{count} copies créées}}'**
  String stepProduced(int count);

  /// No description provided for @stepAlreadyPublished.
  ///
  /// In fr, this message translates to:
  /// **'Déjà publié à l\'identique : aucun commit nécessaire.'**
  String get stepAlreadyPublished;

  /// No description provided for @stepRenamed.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 fichier renommé} other{{count} fichiers renommés}} pour ne rien écraser'**
  String stepRenamed(int count);

  /// No description provided for @stepVerified.
  ///
  /// In fr, this message translates to:
  /// **'Contenu vérifié sur GitHub'**
  String get stepVerified;

  /// No description provided for @stepNotVerified.
  ///
  /// In fr, this message translates to:
  /// **'Commit créé, mais contenu distant non vérifié'**
  String get stepNotVerified;

  /// No description provided for @aiErrUnauthorized.
  ///
  /// In fr, this message translates to:
  /// **'Clé d\'API refusée par le fournisseur. Vérifiez-la dans les paramètres.'**
  String get aiErrUnauthorized;

  /// No description provided for @aiErrForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé par le fournisseur (droits de la clé ou modèle non autorisé).'**
  String get aiErrForbidden;

  /// No description provided for @aiErrNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Modèle ou service introuvable. Choisissez un autre modèle.'**
  String get aiErrNotFound;

  /// No description provided for @aiErrRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop de requêtes ou quota épuisé. Réessayez plus tard.'**
  String get aiErrRateLimited;

  /// No description provided for @aiErrBadRequest.
  ///
  /// In fr, this message translates to:
  /// **'Le fournisseur a refusé la demande.'**
  String get aiErrBadRequest;

  /// No description provided for @aiErrToolsUnsupported.
  ///
  /// In fr, this message translates to:
  /// **'Ce modèle ne sait pas utiliser d\'outils. Choisissez un modèle compatible (par ex. mistral-small-latest).'**
  String get aiErrToolsUnsupported;

  /// No description provided for @aiErrNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de joindre le fournisseur. Vérifiez la connexion.'**
  String get aiErrNetwork;

  /// No description provided for @aiErrTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Le fournisseur n\'a pas répondu à temps.'**
  String get aiErrTimeout;

  /// No description provided for @aiErrServer.
  ///
  /// In fr, this message translates to:
  /// **'Le fournisseur rencontre une erreur. Réessayez plus tard.'**
  String get aiErrServer;

  /// No description provided for @aiErrInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Réponse inattendue du fournisseur.'**
  String get aiErrInvalid;

  /// No description provided for @aiErrNotConfigured.
  ///
  /// In fr, this message translates to:
  /// **'L\'IA n\'est pas configurée (paramètres).'**
  String get aiErrNotConfigured;

  /// No description provided for @aiErrLoop.
  ///
  /// In fr, this message translates to:
  /// **'L\'agent n\'a pas réussi à conclure. Reformulez votre demande.'**
  String get aiErrLoop;

  /// No description provided for @aiErrDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail : {detail}'**
  String aiErrDetail(String detail);

  /// No description provided for @aiEnable.
  ///
  /// In fr, this message translates to:
  /// **'Activer l\'assistant IA'**
  String get aiEnable;

  /// No description provided for @aiEnableHelp.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé par défaut. Toutes les autres fonctions marchent sans IA.'**
  String get aiEnableHelp;

  /// No description provided for @aiProvider.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur'**
  String get aiProvider;

  /// No description provided for @aiApiKey.
  ///
  /// In fr, this message translates to:
  /// **'Clé d\'API'**
  String get aiApiKey;

  /// No description provided for @aiKeySaved.
  ///
  /// In fr, this message translates to:
  /// **'Clé enregistrée dans le trousseau du système'**
  String get aiKeySaved;

  /// No description provided for @aiKeyMissing.
  ///
  /// In fr, this message translates to:
  /// **'Aucune clé enregistrée'**
  String get aiKeyMissing;

  /// No description provided for @aiKeyHint.
  ///
  /// In fr, this message translates to:
  /// **'Collez votre clé ici'**
  String get aiKeyHint;

  /// No description provided for @aiKeySave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la clé'**
  String get aiKeySave;

  /// No description provided for @aiKeyDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la clé'**
  String get aiKeyDelete;

  /// No description provided for @aiKeyGet.
  ///
  /// In fr, this message translates to:
  /// **'Obtenir une clé'**
  String get aiKeyGet;

  /// No description provided for @aiKeyStoreUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Trousseau du système indisponible : aucune clé ne peut être enregistrée de façon sûre.'**
  String get aiKeyStoreUnavailable;

  /// No description provided for @aiBaseUrl.
  ///
  /// In fr, this message translates to:
  /// **'Adresse du serveur'**
  String get aiBaseUrl;

  /// No description provided for @aiBaseUrlSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer l\'adresse'**
  String get aiBaseUrlSave;

  /// No description provided for @aiBaseUrlInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Adresse refusée (http:// ou https://, sans identifiants).'**
  String get aiBaseUrlInvalid;

  /// No description provided for @aiModel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle'**
  String get aiModel;

  /// No description provided for @aiModelLoad.
  ///
  /// In fr, this message translates to:
  /// **'Charger la liste des modèles'**
  String get aiModelLoad;

  /// No description provided for @aiModelTools.
  ///
  /// In fr, this message translates to:
  /// **'outils'**
  String get aiModelTools;

  /// No description provided for @aiModelNoTools.
  ///
  /// In fr, this message translates to:
  /// **'sans outils'**
  String get aiModelNoTools;

  /// No description provided for @aiTest.
  ///
  /// In fr, this message translates to:
  /// **'Tester la connexion'**
  String get aiTest;

  /// No description provided for @aiTestOk.
  ///
  /// In fr, this message translates to:
  /// **'Connexion réussie — {detail}'**
  String aiTestOk(String detail);

  /// No description provided for @aiTestFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la connexion'**
  String get aiTestFailed;

  /// No description provided for @aiConsent.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser l\'envoi des métadonnées à ce fournisseur'**
  String get aiConsent;

  /// No description provided for @aiConsentHelp.
  ///
  /// In fr, this message translates to:
  /// **'Noms, tailles, dates, albums, dépôts. Jamais d\'image ni de vidéo.'**
  String get aiConsentHelp;

  /// No description provided for @aiSaveConversations.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les conversations sur l\'appareil'**
  String get aiSaveConversations;

  /// No description provided for @aiSaveConversationsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé par défaut. Elles restent locales et peuvent être effacées.'**
  String get aiSaveConversationsHelp;

  /// No description provided for @aiDeleteConversations.
  ///
  /// In fr, this message translates to:
  /// **'Effacer les conversations enregistrées'**
  String get aiDeleteConversations;

  /// No description provided for @aiDeleteConversationsDone.
  ///
  /// In fr, this message translates to:
  /// **'Conversations effacées.'**
  String get aiDeleteConversationsDone;

  /// No description provided for @aiVerifiedReal.
  ///
  /// In fr, this message translates to:
  /// **'Testé avec le vrai service'**
  String get aiVerifiedReal;

  /// No description provided for @aiNotVerifiedReal.
  ///
  /// In fr, this message translates to:
  /// **'Non testé avec le vrai service (serveur simulé uniquement)'**
  String get aiNotVerifiedReal;

  /// No description provided for @aiCapabilities.
  ///
  /// In fr, this message translates to:
  /// **'Conversation et appels d\'outils. Vision non utilisée : aucun média n\'est envoyé.'**
  String get aiCapabilities;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
