// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GitPhoto Studio AI';

  @override
  String get appTagline => 'The connected media workshop';

  @override
  String get navDashboard => 'Home';

  @override
  String get navGallery => 'Gallery';

  @override
  String get navEditor => 'Editor';

  @override
  String get navGithub => 'GitHub';

  @override
  String get navPublish => 'Publish';

  @override
  String get navAgent => 'AI agent';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get navHelp => 'User guide';

  @override
  String get navMore => 'More';

  @override
  String get navMenu => 'Navigation menu';

  @override
  String get commonLoading => 'Loading…';

  @override
  String commonError(String message) {
    return 'An error occurred: $message';
  }

  @override
  String get commonRetry => 'Retry';

  @override
  String get plannedTitle => 'Coming soon';

  @override
  String plannedPhase(int phase, String phaseName) {
    return 'Planned for phase $phase — $phaseName';
  }

  @override
  String get plannedHonesty =>
      'No action is offered here yet: controls will appear once the feature is actually implemented and tested.';

  @override
  String get phaseAdvancedPublishing => 'Advanced publishing';

  @override
  String get phaseAiAgent => 'AI agent';

  @override
  String get phaseDocumentation => 'Documentation';

  @override
  String get agentIntro =>
      'Describe what you want to do; the agent proposes a plan and waits for your approval before acting.';

  @override
  String get agentFeatures =>
      'Preferred provider: Mistral (other providers configurable)\nTyped, validated tools, no free shell access\nAction plan shown before execution\nMandatory confirmation\nNo media sent to an AI without your consent';

  @override
  String get helpIntro => 'Built-in documentation, available offline.';

  @override
  String get helpFeatures =>
      'Getting started and guided tour\nGitHub sign-in and repository creation\nPublishing a photo or a video\nCommits, branches and Git LFS\nUsing the AI agent\nCommon errors, FAQ and glossary';

  @override
  String get dashActiveRepo => 'Active repository';

  @override
  String get dashNoRepo => 'No repository connected';

  @override
  String get dashLocalMedia => 'Local media';

  @override
  String get dashPending => 'Pending';

  @override
  String get dashLocalStorage => 'Local storage';

  @override
  String get dashTransfers => 'Transfers';

  @override
  String get dashNoTransfers => 'No transfer in progress';

  @override
  String get dashRecentCommits => 'Recent commits';

  @override
  String get dashShortcuts => 'Shortcuts';

  @override
  String get pixelName => 'Pixel';

  @override
  String get pixelSemantics => 'Pixel, the studio\'s robot assistant';

  @override
  String get pixelWelcome =>
      'Hi! I\'m Pixel. Import your media in the gallery, connect GitHub, then publish in a few steps.';

  @override
  String get pixelSettingsHint =>
      'Tokens and keys are never stored in the local database.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsAiProviders => 'AI providers';

  @override
  String get settingsAiProvidersNote => 'The app works fully without AI.';

  @override
  String get aiProviderPriority => 'Preferred';

  @override
  String get aiProviderLocal => 'Local';

  @override
  String get aiNotConfigured => 'Not configured';

  @override
  String get settingsDiagnostics => 'Diagnostics';

  @override
  String get diagPlatform => 'Platform';

  @override
  String get diagDatabase => 'Database';

  @override
  String diagSchemaVersion(int version) {
    return 'Schema v$version';
  }

  @override
  String get diagGit => 'Git';

  @override
  String get diagGitLfs => 'Git LFS';

  @override
  String get diagNotFound => 'Not found';

  @override
  String get diagNotApplicable => 'Not applicable on this platform';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get galleryImport => 'Import';

  @override
  String get gallerySearchHint => 'Search by name';

  @override
  String get galleryFilterAll => 'All';

  @override
  String get galleryFilterImages => 'Photos';

  @override
  String get galleryFilterVideos => 'Videos';

  @override
  String get gallerySort => 'Sort';

  @override
  String get gallerySortDate => 'Date';

  @override
  String get gallerySortName => 'Name';

  @override
  String get gallerySortType => 'Type';

  @override
  String get gallerySortSize => 'Size';

  @override
  String get gallerySortAscending => 'Ascending';

  @override
  String get gallerySortDescending => 'Descending';

  @override
  String get galleryViewGrid => 'Grid view';

  @override
  String get galleryViewList => 'List view';

  @override
  String get galleryEmptyTitle => 'Your library is empty';

  @override
  String get galleryEmptyBody =>
      'Import photos and videos: the studio keeps a working copy, your original files stay untouched.';

  @override
  String get galleryEmptyDropHint =>
      'You can also drag and drop files or folders into this window.';

  @override
  String get galleryNoResults => 'No media matches these criteria.';

  @override
  String galleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No media',
    );
    return '$_temp0';
  }

  @override
  String gallerySelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get gallerySelectAll => 'Select all';

  @override
  String get galleryClearSelection => 'Clear selection';

  @override
  String get galleryRemove => 'Remove from library';

  @override
  String galleryRemoveTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove these $count items?',
      one: 'Remove this item?',
    );
    return '$_temp0';
  }

  @override
  String get galleryRemoveBody =>
      'The studio\'s working copies and thumbnails will be deleted. Your original files are not affected.';

  @override
  String get galleryRemoveConfirm => 'Remove';

  @override
  String galleryRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items removed',
      one: '1 item removed',
    );
    return '$_temp0';
  }

  @override
  String get galleryDropHere => 'Drop your files to import them';

  @override
  String get galleryVideoBadge => 'Video';

  @override
  String importProgress(int done, int total) {
    return 'Importing: $done of $total';
  }

  @override
  String get importStop => 'Stop';

  @override
  String importSummary(
    int imported,
    int duplicates,
    int unsupported,
    int failed,
  ) {
    return 'Import finished: $imported imported, $duplicates already present, $unsupported unsupported, $failed failed.';
  }

  @override
  String importCancelled(int imported) {
    return 'Import stopped: $imported imported before stopping.';
  }

  @override
  String importPickerError(String message) {
    return 'The file picker could not open: $message';
  }

  @override
  String get importDetails => 'Details';

  @override
  String get importReportTitle => 'Import report';

  @override
  String get importOutcomeImported => 'Imported';

  @override
  String get importOutcomeDuplicate => 'Already in the library';

  @override
  String get importOutcomeUnsupported => 'Unsupported format';

  @override
  String get importOutcomeFailed => 'Failed';

  @override
  String get viewerInfo => 'Information';

  @override
  String get viewerOpenExternal => 'Open with system application';

  @override
  String get viewerOpenExternalFailed =>
      'Could not open the file with the system.';

  @override
  String get viewerPreviewUnavailable =>
      'Preview unavailable for this format on this platform.';

  @override
  String get viewerVideoUnavailable =>
      'Built-in video playback is not available on Linux in this version (no video engine installed). You can open the video with the system player.';

  @override
  String viewerVideoError(String message) {
    return 'Cannot play this video: $message';
  }

  @override
  String get viewerPlay => 'Play';

  @override
  String get viewerPause => 'Pause';

  @override
  String get viewerNotFound => 'This item no longer exists in the library.';

  @override
  String get viewerFileMissing => 'This item\'s working copy is missing.';

  @override
  String get metaFileName => 'Name';

  @override
  String get metaType => 'Type';

  @override
  String get metaSize => 'Size';

  @override
  String get metaDimensions => 'Dimensions';

  @override
  String get metaDuration => 'Duration';

  @override
  String get metaTakenAt => 'Date';

  @override
  String get metaImportedAt => 'Imported on';

  @override
  String get metaCamera => 'Camera';

  @override
  String get metaGps => 'GPS location';

  @override
  String get metaGpsPresent =>
      'Present: it will be visible to everyone if the image is published as is.';

  @override
  String get metaGpsAbsent => 'None';

  @override
  String get metaSha256 => 'SHA-256 fingerprint';

  @override
  String get metaSource => 'Source';

  @override
  String get metaUnknown => 'Unknown';

  @override
  String get metaVideoUnavailable =>
      'Video metadata unavailable on this platform.';

  @override
  String get commonOpenInBrowser => 'Open in browser';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonBack => 'Back';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String commonUnknownError(String message) {
    return 'Unexpected error: $message';
  }

  @override
  String get ghConnectTitle => 'Connect to GitHub';

  @override
  String get ghConnectIntro =>
      'The token is checked with GitHub, then stored only in the system\'s secure keyring, never in the local database or logs.';

  @override
  String get ghStoreUnavailable =>
      'The system\'s secure keyring is unavailable. On Linux, make sure a secret service (GNOME Keyring, KWallet…) is running and unlocked. Without it, no credentials can be stored.';

  @override
  String get ghPatTitle => 'Personal access token (recommended)';

  @override
  String get ghPatHelp =>
      'Create a fine-grained token limited to the repositories you choose, with Contents read and write permission (Metadata read is added automatically). To create repositories from the app, add Administration write.';

  @override
  String get ghPatCreate => 'Create a token on GitHub';

  @override
  String get ghPatField => 'GitHub token';

  @override
  String get ghPatConnect => 'Verify and connect';

  @override
  String get ghDeviceTitle => 'Sign in with the browser';

  @override
  String get ghDeviceHelp =>
      'Requires the Client ID of an OAuth app or GitHub App with Device Flow enabled. No secret is required.';

  @override
  String get ghDeviceClientId => 'Client ID';

  @override
  String get ghDeviceStart => 'Sign in with the browser';

  @override
  String get ghDeviceCodeIntro =>
      'Enter this code on the GitHub page that just opened:';

  @override
  String get ghDeviceWaiting => 'Waiting for your authorization…';

  @override
  String get ghDeviceDenied => 'Authorization denied or cancelled.';

  @override
  String get ghDeviceExpired => 'The code expired. Please start again.';

  @override
  String ghDeviceMisconfigured(String detail) {
    return 'Configuration rejected by GitHub: $detail';
  }

  @override
  String ghConnectedAs(String login) {
    return 'Signed in as $login';
  }

  @override
  String get ghTokenFineGrained =>
      'Fine-grained or GitHub App token: permissions set on GitHub';

  @override
  String ghTokenScopes(String scopes) {
    return 'Token scopes: $scopes';
  }

  @override
  String ghTokenExpires(String date) {
    return 'Expires on $date';
  }

  @override
  String get ghDisconnect => 'Sign out';

  @override
  String get ghDisconnectTitle => 'Sign out of GitHub?';

  @override
  String get ghDisconnectBody =>
      'The token will be erased from this device\'s keyring. To revoke it permanently, also delete it in your GitHub account settings.';

  @override
  String get ghRevokePage => 'Manage my tokens on GitHub';

  @override
  String get ghSessionError => 'The stored token could not be verified.';

  @override
  String get ghRepos => 'Repositories';

  @override
  String get ghReposSearch => 'Filter repositories';

  @override
  String get ghReposEmpty => 'No repository accessible with this token.';

  @override
  String get ghPrivate => 'Private';

  @override
  String get ghPublic => 'Public';

  @override
  String get ghReadOnly => 'Read only';

  @override
  String get ghActive => 'Active';

  @override
  String get ghNewRepo => 'New repository';

  @override
  String get ghNewRepoName => 'Repository name';

  @override
  String get ghNewRepoNameInvalid =>
      'Letters, digits, \'-\', \'_\' and \'.\' only (100 characters max).';

  @override
  String get ghNewRepoDescription => 'Description (optional)';

  @override
  String get ghNewRepoPrivate => 'Private: visible to you and invited people';

  @override
  String get ghNewRepoPublic => 'Public: visible to everyone on the Internet';

  @override
  String get ghNewRepoCreate => 'Create';

  @override
  String get ghNewRepoPublicConfirmTitle => 'Create a public repository?';

  @override
  String ghNewRepoPublicConfirmBody(String name) {
    return 'Everything you publish to \'$name\' will be visible to anyone, including photo metadata (GPS location…).';
  }

  @override
  String get ghNewRepoPublicConfirm => 'Yes, create a public repository';

  @override
  String ghNewRepoCreated(String name) {
    return 'Repository $name created.';
  }

  @override
  String get ghBranch => 'Branch';

  @override
  String get ghRoot => 'Root';

  @override
  String get ghFolderEmpty => 'Empty folder.';

  @override
  String get ghRepoEmpty => 'This repository has no files yet.';

  @override
  String get ghCommits => 'Recent commits';

  @override
  String get ghSetActive => 'Set as active repository';

  @override
  String ghActiveSet(String name) {
    return '$name is now the active repository.';
  }

  @override
  String get ghPublishHere => 'Publish here';

  @override
  String get errUnauthorized =>
      'GitHub rejects the token: it is invalid, expired or revoked. Sign in again with a new token.';

  @override
  String errForbidden(String detail) {
    return 'Insufficient permission. For a fine-grained token, check that this repository is included and that the required permission (Contents write, or Administration to create a repository) is granted. Detail: $detail';
  }

  @override
  String get errNotFound =>
      'Not found. The repository, branch or folder does not exist, or your token cannot access it.';

  @override
  String errRateLimited(String time) {
    return 'GitHub request limit reached. Try again after $time.';
  }

  @override
  String get errRateLimitedNoTime =>
      'GitHub request limit reached. Try again in a few minutes.';

  @override
  String get errConflict =>
      'The branch changed on GitHub during publishing. Nothing was published: run the analysis again to take the changes into account.';

  @override
  String get errEmptyRepository => 'This repository is empty.';

  @override
  String errValidation(String detail) {
    return 'GitHub rejected the request: $detail';
  }

  @override
  String errNetwork(String detail) {
    return 'Cannot reach GitHub. Check your Internet connection. ($detail)';
  }

  @override
  String get errServer =>
      'GitHub is having trouble (server error). Try again later.';

  @override
  String get pubNotConnected => 'Sign in to GitHub to publish.';

  @override
  String get pubGoToGithub => 'Go to the GitHub screen';

  @override
  String get pubNoMedia =>
      'Your library is empty: import media in the gallery first.';

  @override
  String get pubStepMedia => 'Media';

  @override
  String get pubStepDestination => 'Destination';

  @override
  String get pubStepAnalysis => 'Analysis';

  @override
  String get pubStepMessage => 'Message';

  @override
  String get pubStepReview => 'Review';

  @override
  String get pubStepResult => 'Result';

  @override
  String pubSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items selected',
      one: '1 item selected',
      zero: 'No media selected',
    );
    return '$_temp0';
  }

  @override
  String get pubRepository => 'Repository';

  @override
  String get pubChooseRepository => 'Choose a repository';

  @override
  String get pubFolder => 'Folder in the repository';

  @override
  String get pubFolderHelp =>
      'E.g. photos/2024. A missing folder is created by adding the files. Leave empty for the root.';

  @override
  String get pubFolderInvalid =>
      'Invalid path (no \'..\', \'.git\' or special characters).';

  @override
  String get pubEmptyRepoNote =>
      'Empty repository: files will be published one by one (one commit per file), on the default branch.';

  @override
  String get pubAnalyze => 'Analyze';

  @override
  String pubAnalyzing(int done, int total) {
    return 'Analyzing: $done of $total';
  }

  @override
  String get pubActionAdd => 'New';

  @override
  String get pubActionSkip => 'Identical on GitHub — skipped';

  @override
  String get pubActionRenamed => 'Name taken — published under another name';

  @override
  String get pubActionOverwrite => 'Will replace the existing file';

  @override
  String get pubBlockedLfs =>
      'Over 100 MiB while Git LFS is disabled in settings';

  @override
  String get pubBlockedPath => 'File name incompatible with a repository';

  @override
  String get pubWarnLarge => 'Large (over 50 MiB): GitHub will flag it';

  @override
  String get pubWarnGpsPublic =>
      'Contains a GPS location and the repository is public';

  @override
  String get pubOverwriteToggle => 'Replace instead of renaming';

  @override
  String get pubTruncatedTree =>
      'The repository is very large: conflict analysis is partial. GitHub will still not overwrite anything unexpectedly.';

  @override
  String get pubOptimizationNote =>
      'Image optimization before publishing: available in phase 4.';

  @override
  String pubSummaryCounts(int upload, String size, int skipped, int blocked) {
    return '$upload to upload ($size), $skipped skipped, $blocked blocked';
  }

  @override
  String get pubNothingToUpload =>
      'Nothing to publish: all files are already present or blocked.';

  @override
  String get pubMessageLabel => 'Commit message';

  @override
  String pubMessageDefault(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count media files via GitPhoto Studio',
      one: 'Add one media file via GitPhoto Studio',
    );
    return '$_temp0';
  }

  @override
  String get pubMessageEmpty => 'The message cannot be empty.';

  @override
  String get pubReviewIntro => 'Here is exactly what will be sent:';

  @override
  String pubReviewTarget(String repo, String branch) {
    return '$repo · branch $branch';
  }

  @override
  String get pubReviewSingleCommit =>
      'All files will be added in a single commit.';

  @override
  String pubReviewOverwriteWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count existing files will be replaced.',
      one: '1 existing file will be replaced.',
    );
    return '$_temp0 The previous version remains in the Git history.';
  }

  @override
  String get pubConfirm => 'Publish to GitHub';

  @override
  String get pubConfirmTitle => 'Confirm publishing?';

  @override
  String pubConfirmBody(int count, String repo, String visibility) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files will be published',
      one: '1 file will be published',
    );
    return '$_temp0 to $repo ($visibility).';
  }

  @override
  String pubStepUploading(int done, int total) {
    return 'Uploading files: $done of $total';
  }

  @override
  String get pubStepCommitting => 'Creating the commit…';

  @override
  String get pubStepUpdating => 'Updating the branch…';

  @override
  String get pubStepVerifying => 'Verifying on GitHub…';

  @override
  String get pubSuccess => 'Published successfully';

  @override
  String get pubVerified =>
      'Verified: the files are on GitHub with the expected content.';

  @override
  String get pubNotVerified =>
      'Published, but remote verification could not confirm every file. Check the commit on GitHub.';

  @override
  String pubCommit(String sha) {
    return 'Commit $sha';
  }

  @override
  String get pubFailed => 'Publishing failed';

  @override
  String get pubNew => 'New publication';

  @override
  String get histEmpty => 'No operations yet.';

  @override
  String get histStatusRunning => 'Running';

  @override
  String get histStatusSuccess => 'Succeeded';

  @override
  String get histStatusFailed => 'Failed';

  @override
  String get histStatusInterrupted => 'Interrupted';

  @override
  String get histInterruptedHelp =>
      'The app was closed during the operation: its outcome is unknown. Check the repository on GitHub; a new analysis will skip files already published.';

  @override
  String histFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get histRetryNote =>
      'A failed or interrupted publication can be resumed: only files missing from GitHub are sent, without duplicates. After a lost connection, the app retries twice on its own.';

  @override
  String get histError => 'Error';

  @override
  String get dashNoCommitsConnect =>
      'Sign in to GitHub and choose an active repository to see its recent commits.';

  @override
  String get settingsGithub => 'GitHub account';

  @override
  String get settingsGithubNotConnected => 'Not connected';

  @override
  String get pixelPublishTip =>
      'Tip: check the GPS column before publishing to a public repository.';

  @override
  String get editorChooseMedia => 'Choose a media file to edit';

  @override
  String get editorNoMedia => 'Import media in the gallery first.';

  @override
  String get editorOriginalsSafe =>
      'Each operation creates a new version: the original is never modified.';

  @override
  String get editorFileName => 'File name';

  @override
  String get editorRename => 'Rename';

  @override
  String get editorRenamed => 'Media renamed.';

  @override
  String get editorRenameInvalid => 'Invalid file name.';

  @override
  String get editorAlbum => 'Album';

  @override
  String get editorNoAlbum => 'No album';

  @override
  String editorVersionOf(String name) {
    return 'Version of \'$name\'';
  }

  @override
  String get editorImageSection => 'Image optimization';

  @override
  String get presetWeb => 'Web (1920 px)';

  @override
  String get presetLight => 'Light (1280 px)';

  @override
  String get presetThumbnail => 'Thumbnail (400 px)';

  @override
  String get presetCustom => 'Custom';

  @override
  String editorMaxDimension(int px) {
    return 'Longest side: $px px';
  }

  @override
  String get editorKeepDimensions => 'Keep original dimensions';

  @override
  String get editorFormat => 'Format';

  @override
  String editorQuality(int quality) {
    return 'Quality: $quality%';
  }

  @override
  String get editorMetadata => 'Metadata';

  @override
  String get metaStripAll => 'Remove everything (recommended for publishing)';

  @override
  String get metaKeepBasic => 'Keep date and camera (never GPS)';

  @override
  String get editorPreview => 'Preview';

  @override
  String get editorPreviewing => 'Computing preview…';

  @override
  String get editorOriginal => 'Original';

  @override
  String get editorResult => 'Result';

  @override
  String editorSizeChange(String original, String result, String change) {
    return '$original → $result ($change)';
  }

  @override
  String get editorSaveVersion => 'Save as a new version';

  @override
  String editorVersionSaved(String name) {
    return 'New version created: $name';
  }

  @override
  String get editorVersionDuplicate =>
      'An identical version already exists in the library.';

  @override
  String get editorVideoSection => 'Video preparation';

  @override
  String get videoPresetLight => 'Light (480p)';

  @override
  String get videoPreset720 => '720p';

  @override
  String get videoPreset1080 => '1080p';

  @override
  String get videoRemoveAudio => 'Remove audio';

  @override
  String videoEstimate(String size, String original) {
    return 'Estimated size: $size (original: $original)';
  }

  @override
  String get videoEstimateUnknown =>
      'Unknown estimated size: video duration unavailable.';

  @override
  String videoEngine(String engine) {
    return 'Engine: $engine';
  }

  @override
  String get videoConvert => 'Convert to MP4';

  @override
  String videoConverting(int percent) {
    return 'Converting… $percent%';
  }

  @override
  String get videoUnavailableLinux =>
      'Video conversion unavailable: ffmpeg is not installed. Install it with \'sudo apt install ffmpeg\', then run detection again in Settings › Diagnostics.';

  @override
  String get videoUnavailable =>
      'Video conversion unavailable on this platform.';

  @override
  String get jobStop => 'Stop';

  @override
  String jobBatchProgress(int done, int total) {
    return 'Optimizing: $done of $total';
  }

  @override
  String jobDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versions created',
      one: '1 version created',
      zero: 'No version created',
    );
    return '$_temp0';
  }

  @override
  String get jobCancelled => 'Processing stopped.';

  @override
  String jobFailed(String message) {
    return 'Failed: $message';
  }

  @override
  String get dupTitle => 'Probable duplicates';

  @override
  String get dupHelp =>
      'Visually very similar images (resized, recompressed…). Exact copies are already rejected on import.';

  @override
  String get dupNone => 'No probable duplicates.';

  @override
  String dupGroup(int count) {
    return '$count similar images';
  }

  @override
  String get dupRemove => 'Remove';

  @override
  String get dupAnalyzing => 'Analyzing images…';

  @override
  String dupRemoveTitle(String name) {
    return 'Remove \'$name\'?';
  }

  @override
  String get albumsTitle => 'Albums';

  @override
  String get albumsNone => 'No albums yet.';

  @override
  String get albumNew => 'New album';

  @override
  String get albumName => 'Album name';

  @override
  String get albumCreate => 'Create';

  @override
  String get albumRename => 'Rename';

  @override
  String get albumDelete => 'Delete album';

  @override
  String albumDeleteBody(String name) {
    return 'The media in \'$name\' stay in the library, just outside any album.';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'empty',
    );
    return '$_temp0';
  }

  @override
  String get albumAutoOrganize => 'Organize by year and month';

  @override
  String albumAutoOrganizeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count media files outside albums will be placed in \'YYYY-MM\' albums by date.',
      one:
          '1 media file outside albums will be placed in a \'YYYY-MM\' album by date.',
      zero: 'No media outside albums to organize.',
    );
    return '$_temp0';
  }

  @override
  String albumAutoOrganized(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items organized',
      one: '1 item organized',
    );
    return '$_temp0';
  }

  @override
  String get galleryOptimize => 'Optimize';

  @override
  String galleryOptimizeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Optimize the $count selected images',
      one: 'Optimize the selected image',
    );
    return '$_temp0';
  }

  @override
  String get galleryOptimizeVideosIgnored =>
      'Selected videos are skipped: prepare them one at a time in the editor.';

  @override
  String get galleryAddToAlbum => 'Add to an album';

  @override
  String get galleryAllAlbums => 'All albums';

  @override
  String galleryMovedToAlbum(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items added',
      one: '1 item added',
    );
    return '$_temp0 to \'$name\'';
  }

  @override
  String get viewerEdit => 'Edit';

  @override
  String get metaVersionOf => 'Version of';

  @override
  String get diagFfmpeg => 'ffmpeg (video)';

  @override
  String videoNotSmaller(String source, String output) {
    return 'The conversion does not reduce the size ($source → $output): the version was not kept. The video is probably already well compressed; try \'Remove audio\' or a lower preset.';
  }

  @override
  String get histStatusQueued => 'Queued';

  @override
  String get histStatusCancelled => 'Cancelled';

  @override
  String get histResume => 'Resume';

  @override
  String get histCancel => 'Cancel';

  @override
  String get histCancelTitle => 'Cancel this publication?';

  @override
  String get histCancelBody =>
      'Files not yet published will not be sent. Anything already on GitHub is not removed.';

  @override
  String get histResumeNote =>
      'Resuming first re-reads GitHub: files already published are never sent again.';

  @override
  String histAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
      one: '1 attempt',
    );
    return '$_temp0';
  }

  @override
  String get entryPending => 'Pending';

  @override
  String get entryUploaded => 'Uploaded, commit pending';

  @override
  String get entryDone => 'Published';

  @override
  String get entrySkipped => 'Already on GitHub';

  @override
  String get entryFailed => 'Failed';

  @override
  String get entryCancelled => 'Cancelled';

  @override
  String get strategyApi => 'API';

  @override
  String get strategyLfs => 'Git LFS';

  @override
  String get strategyGit => 'Git';

  @override
  String get pubCancelRunning => 'Cancel publishing';

  @override
  String get pubCancelled => 'Publishing cancelled: nothing was published.';

  @override
  String get pubQueuedNote =>
      'Publishing goes through the queue: you can leave this screen, it continues and stays visible in History.';

  @override
  String get pubViaLfs => 'Large file: sent with Git LFS';

  @override
  String get pubViaGit => 'Sent with native Git';

  @override
  String get pubBlockedLfsMax =>
      'Over 2 GiB: exceeds GitHub\'s maximum Git LFS file size (free account)';

  @override
  String get pubLfsQuotaNote =>
      'Git LFS files use your GitHub account\'s LFS storage quota.';

  @override
  String errDuplicate(String path) {
    return '\'$path\' is already waiting to be published to this repository.';
  }

  @override
  String errPathConflict(String path) {
    return '\'$path\' changed on GitHub since the analysis. Nothing was published: run the analysis again.';
  }

  @override
  String get settingsPublishing => 'Publishing';

  @override
  String get settingsLfs => 'Git LFS for files over 50 MiB';

  @override
  String get settingsLfsHelp =>
      'Recommended. Also works on Android, with nothing to install. Uses the GitHub account\'s LFS quota.';

  @override
  String get settingsNativeGit => 'Publish with the computer\'s Git';

  @override
  String get settingsNativeGitHelp =>
      'Linux, if Git is detected. Large files still go through Git LFS over HTTP.';

  @override
  String get settingsNativeGitUnavailable =>
      'Git is not detected on this device: the GitHub API is used.';

  @override
  String get agentDisabledTitle => 'The AI assistant is turned off';

  @override
  String get agentDisabledBody =>
      'The app works fully without AI. To use the agent, turn it on and configure a provider (Mistral recommended) in Settings.';

  @override
  String get agentOpenSettings => 'Open AI settings';

  @override
  String agentNeedsKey(String provider) {
    return 'First save an API key for $provider in Settings.';
  }

  @override
  String get agentNeedsModel => 'Choose a model in Settings.';

  @override
  String get agentConsentTitle => 'Before you start';

  @override
  String agentConsentBody(String provider) {
    return 'To understand your requests, the agent sends $provider your message and metadata: file names, sizes, dates, albums, dimensions, whether a GPS position exists (never the position itself), your GitHub repository names and publishing history.\n\nNo image or video is sent. No token or key is ever given to the model.';
  }

  @override
  String get agentConsentAccept => 'I agree';

  @override
  String get agentInputHint =>
      'E.g. “Publish these photos to my Portfolio repository”';

  @override
  String get agentSend => 'Send';

  @override
  String get agentThinking => 'The agent is thinking…';

  @override
  String agentConsulting(String tool) {
    return 'The agent is checking: $tool';
  }

  @override
  String get agentStop => 'Stop';

  @override
  String get agentNewConversation => 'New conversation';

  @override
  String get agentExamplesTitle => 'Example requests';

  @override
  String get agentExamples =>
      'Publish the selected photos to my Portfolio repository\nSort my images into albums by year and month\nShrink the photos without losing much quality\nPrepare a travel album and write a README\nExplain why my last publication failed\nFind duplicates before publishing\nWhich videos will go through Git LFS?';

  @override
  String agentToolsUsed(String tools) {
    return 'Information checked: $tools';
  }

  @override
  String get agentSafetyNote =>
      'The agent cannot delete or replace anything, and only acts after you confirm.';

  @override
  String get toolGetSelection => 'selection';

  @override
  String get toolSearchMedia => 'library';

  @override
  String get toolListAlbums => 'albums';

  @override
  String get toolFindSimilar => 'duplicates';

  @override
  String get toolGithubStatus => 'GitHub';

  @override
  String get toolRecentOperations => 'history';

  @override
  String get toolPreviewPublication => 'publication preview';

  @override
  String get planTitle => 'Proposed plan';

  @override
  String planMediaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String planFromStep(int step) {
    return 'the copies from step $step';
  }

  @override
  String planStepMove(String target, String album) {
    return 'Move $target to the album “$album”';
  }

  @override
  String planStepOrganizeYear(String target) {
    return 'Sort $target into albums by year';
  }

  @override
  String planStepOrganizeMonth(String target) {
    return 'Sort $target into albums by month (YYYY-MM)';
  }

  @override
  String planStepOptimize(int count, String preset) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '1 image',
    );
    return 'Create optimized versions of $_temp0 — $preset. Originals kept, metadata removed.';
  }

  @override
  String planStepConvert(int count, String preset) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
    );
    return 'Create converted versions of $_temp0 — $preset. Originals kept.';
  }

  @override
  String planStepPublish(String target, String repo, String branch) {
    return 'Publish $target to $repo, branch $branch';
  }

  @override
  String get planReadmeOnly => 'a README';

  @override
  String planPublishFolder(String folder) {
    return 'Folder: $folder';
  }

  @override
  String get planPublishRoot => 'Folder: repository root';

  @override
  String planPublishMessage(String message) {
    return 'Commit message: $message';
  }

  @override
  String get planPublishReadme => 'Adds a README.md to the same commit';

  @override
  String get planPublishSafety =>
      'A single commit. No existing file is replaced (renamed on conflict). Files already published unchanged are skipped.';

  @override
  String planWarnGps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count published photos contain',
      one: '1 published photo contains',
    );
    return '$_temp0 a GPS position.';
  }

  @override
  String planWarnPublic(String repo) {
    return '$repo is a public repository: the files will be visible to everyone.';
  }

  @override
  String get planWarnVideo =>
      'Video conversion is not available on this device: this step will fail.';

  @override
  String get planExecute => 'Run the plan';

  @override
  String get planReject => 'Decline';

  @override
  String get planConfirmTitle => 'Run this plan?';

  @override
  String planConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions will run in order.',
      one: '1 action will run.',
    );
    return '$_temp0 You can stop between two files. Nothing is deleted.';
  }

  @override
  String get planConfirmPublish => 'Files will be published to GitHub.';

  @override
  String get planStatusRejected => 'Plan declined: nothing was done.';

  @override
  String get planStatusExpired =>
      'Plan not confirmed, replaced by your new request.';

  @override
  String get planStatusRunning => 'Running…';

  @override
  String planProgress(int step, int done, int total) {
    return 'Step $step — $done/$total';
  }

  @override
  String get planDoneOk => 'Plan completed and verified.';

  @override
  String get planDonePartial =>
      'Plan completed with reservations (see details).';

  @override
  String get planDoneFailed => 'The plan could not be fully completed.';

  @override
  String get planDoneCancelled => 'Run stopped.';

  @override
  String planArchived(String summary) {
    return 'Plan from a previous conversation (can no longer be run): $summary';
  }

  @override
  String get stepDone => 'Done';

  @override
  String get stepPartial => 'Partly done';

  @override
  String get stepFailed => 'Failed';

  @override
  String get stepSkipped => 'Not run';

  @override
  String get stepCancelled => 'Stopped';

  @override
  String stepAffected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items processed',
      one: '1 item processed',
    );
    return '$_temp0';
  }

  @override
  String stepProduced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count copies created',
      one: '1 copy created',
    );
    return '$_temp0';
  }

  @override
  String get stepAlreadyPublished =>
      'Already published unchanged: no commit needed.';

  @override
  String stepRenamed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files renamed',
      one: '1 file renamed',
    );
    return '$_temp0 to avoid overwriting';
  }

  @override
  String get stepVerified => 'Content verified on GitHub';

  @override
  String get stepNotVerified =>
      'Commit created, but remote content not verified';

  @override
  String get aiErrUnauthorized =>
      'API key rejected by the provider. Check it in Settings.';

  @override
  String get aiErrForbidden =>
      'Access denied by the provider (key permissions or model not allowed).';

  @override
  String get aiErrNotFound =>
      'Model or service not found. Choose another model.';

  @override
  String get aiErrRateLimited =>
      'Too many requests or quota exhausted. Try again later.';

  @override
  String get aiErrBadRequest => 'The provider rejected the request.';

  @override
  String get aiErrToolsUnsupported =>
      'This model cannot use tools. Choose a compatible model (e.g. mistral-small-latest).';

  @override
  String get aiErrNetwork =>
      'Cannot reach the provider. Check your connection.';

  @override
  String get aiErrTimeout => 'The provider did not answer in time.';

  @override
  String get aiErrServer => 'The provider has an error. Try again later.';

  @override
  String get aiErrInvalid => 'Unexpected answer from the provider.';

  @override
  String get aiErrNotConfigured => 'AI is not configured (Settings).';

  @override
  String get aiErrLoop => 'The agent could not finish. Rephrase your request.';

  @override
  String aiErrDetail(String detail) {
    return 'Detail: $detail';
  }

  @override
  String get aiEnable => 'Turn on the AI assistant';

  @override
  String get aiEnableHelp =>
      'Off by default. Every other feature works without AI.';

  @override
  String get aiProvider => 'Provider';

  @override
  String get aiApiKey => 'API key';

  @override
  String get aiKeySaved => 'Key saved in the system keychain';

  @override
  String get aiKeyMissing => 'No key saved';

  @override
  String get aiKeyHint => 'Paste your key here';

  @override
  String get aiKeySave => 'Save key';

  @override
  String get aiKeyDelete => 'Delete key';

  @override
  String get aiKeyGet => 'Get a key';

  @override
  String get aiKeyStoreUnavailable =>
      'System keychain unavailable: no key can be stored safely.';

  @override
  String get aiBaseUrl => 'Server address';

  @override
  String get aiBaseUrlSave => 'Save address';

  @override
  String get aiBaseUrlInvalid =>
      'Address rejected (http:// or https://, no credentials).';

  @override
  String get aiModel => 'Model';

  @override
  String get aiModelLoad => 'Load the model list';

  @override
  String get aiModelTools => 'tools';

  @override
  String get aiModelNoTools => 'no tools';

  @override
  String get aiTest => 'Test connection';

  @override
  String aiTestOk(String detail) {
    return 'Connection OK — $detail';
  }

  @override
  String get aiTestFailed => 'Connection failed';

  @override
  String get aiConsent => 'Allow sending metadata to this provider';

  @override
  String get aiConsentHelp =>
      'Names, sizes, dates, albums, repositories. Never images or videos.';

  @override
  String get aiSaveConversations => 'Save conversations on this device';

  @override
  String get aiSaveConversationsHelp =>
      'Off by default. They stay local and can be erased.';

  @override
  String get aiDeleteConversations => 'Erase saved conversations';

  @override
  String get aiDeleteConversationsDone => 'Conversations erased.';

  @override
  String get aiVerifiedReal => 'Tested against the real service';

  @override
  String get aiNotVerifiedReal =>
      'Not tested against the real service (simulated server only)';

  @override
  String get aiCapabilities =>
      'Chat and tool calls. Vision unused: no media is sent.';
}
