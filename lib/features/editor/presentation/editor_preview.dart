import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/page_edit.dart';
import 'editor_copy.dart';

class EditorPreview extends StatelessWidget {
  const EditorPreview({super.key, required this.future});
  final Future<PagePreview>? future;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return SizedBox(
      height: (MediaQuery.sizeOf(context).height * .45).clamp(240, 450),
      child: FutureBuilder<PagePreview>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(editFailureMessage(s, snapshot.error)));
          }
          if (snapshot.connectionState != ConnectionState.done ||
              !snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(semanticsLabel: s.loading),
            );
          }
          return ColoredBox(
            color: const Color(0xff191b1c),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.memory(
                snapshot.requireData.bytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                semanticLabel: s.editPages,
              ),
            ),
          );
        },
      ),
    );
  }
}
