import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

Future<bool> confirmDelete(BuildContext context, int count) async {
  final s = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.deleteDocuments),
          content: Text(s.deleteConfirmation(count)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.delete),
            ),
          ],
        ),
      ) ??
      false;
}

Future<String?> requestDocumentName(BuildContext context, String name) =>
    showDialog<String>(context: context, builder: (_) => _RenameDialog(name));

class _RenameDialog extends StatefulWidget {
  const _RenameDialog(this.name);
  final String name;
  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.name);
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(s.rename),
      content: Form(
        key: _form,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 120,
          decoration: InputDecoration(labelText: s.documentName),
          validator: (text) =>
              (text ?? '').trim().isEmpty ? s.nameRequired : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(s.save)),
      ],
    );
  }
}
