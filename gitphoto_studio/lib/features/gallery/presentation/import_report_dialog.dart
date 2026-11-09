import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/media_importer.dart';

Future<void> showImportReport(BuildContext context, ImportReport report) {
  final l10n = AppLocalizations.of(context);
  String label(ImportOutcome o) => switch (o) {
    ImportOutcome.imported => l10n.importOutcomeImported,
    ImportOutcome.duplicate => l10n.importOutcomeDuplicate,
    ImportOutcome.unsupported => l10n.importOutcomeUnsupported,
    ImportOutcome.failed => l10n.importOutcomeFailed,
  };
  IconData icon(ImportOutcome o) => switch (o) {
    ImportOutcome.imported => Icons.check_circle_outline,
    ImportOutcome.duplicate => Icons.copy_all_outlined,
    ImportOutcome.unsupported => Icons.block,
    ImportOutcome.failed => Icons.error_outline,
  };
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.importReportTitle),
      content: SizedBox(
        width: 480,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final item in report.items)
              ListTile(
                dense: true,
                leading: Icon(icon(item.outcome)),
                title: Text(item.name),
                subtitle: Text(
                  item.error == null
                      ? label(item.outcome)
                      : '${label(item.outcome)} : ${item.error}',
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonClose),
        ),
      ],
    ),
  );
}
