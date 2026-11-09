import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../publishing/application/publish_queue.dart'
    show DuplicatePublicationException;
import '../../publishing/application/publisher.dart' show PublishCancelled;
import '../../publishing/domain/publish_plan.dart'
    show PublishConflictException;
import '../data/device_flow.dart';
import '../data/github_exception.dart';

/// Explication compréhensible d'une erreur, sans jargon inutile.
String describeError(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  if (error is DeviceFlowException) {
    return switch (error.error) {
      DeviceFlowError.denied => l10n.ghDeviceDenied,
      DeviceFlowError.expired => l10n.ghDeviceExpired,
      DeviceFlowError.misconfigured => l10n.ghDeviceMisconfigured(
        error.detail ?? '',
      ),
    };
  }
  if (error is PublishCancelled) return l10n.pubCancelled;
  if (error is DuplicatePublicationException) {
    return l10n.errDuplicate(error.remotePath);
  }
  if (error is PublishConflictException) {
    return l10n.errPathConflict(error.remotePath);
  }
  if (error is! GithubException) return l10n.commonUnknownError('$error');
  return switch (error.kind) {
    GithubErrorKind.unauthorized => l10n.errUnauthorized,
    GithubErrorKind.forbidden => l10n.errForbidden(error.message),
    GithubErrorKind.notFound => l10n.errNotFound,
    GithubErrorKind.rateLimited =>
      error.resetAt == null
          ? l10n.errRateLimitedNoTime
          : l10n.errRateLimited(
              DateFormat.Hm(
                Localizations.localeOf(context).languageCode,
              ).format(error.resetAt!),
            ),
    GithubErrorKind.conflict => l10n.errConflict,
    GithubErrorKind.emptyRepository => l10n.errEmptyRepository,
    GithubErrorKind.validation => l10n.errValidation(error.message),
    GithubErrorKind.network => l10n.errNetwork(error.message),
    GithubErrorKind.server => l10n.errServer,
    GithubErrorKind.unknown => l10n.commonUnknownError(error.message),
  };
}
