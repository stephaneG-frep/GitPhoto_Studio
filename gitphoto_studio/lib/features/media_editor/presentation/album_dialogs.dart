import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Saisie d'un nom d'album (création ou renommage).
Future<String?> showAlbumNameDialog(
  BuildContext context, {
  String initial = '',
  required String title,
  required String action,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        _AlbumNameDialog(initial: initial, title: title, action: action),
  );
}

/// Le champ appartient au dialogue : il n'est libéré qu'une fois le dialogue
/// entièrement fermé (animation de sortie comprise).
class _AlbumNameDialog extends StatefulWidget {
  const _AlbumNameDialog({
    required this.initial,
    required this.title,
    required this.action,
  });

  final String initial;
  final String title;
  final String action;

  @override
  State<_AlbumNameDialog> createState() => _AlbumNameDialogState();
}

class _AlbumNameDialogState extends State<_AlbumNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final empty = _controller.text.trim().isEmpty;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 100,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: l10n.albumName,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: empty ? null : _submit,
          child: Text(widget.action),
        ),
      ],
    );
  }
}
