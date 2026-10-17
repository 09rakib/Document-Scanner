import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/page_edit.dart';
import 'crop_canvas.dart';
import 'crop_sliders.dart';
import 'editor_copy.dart';

class CropScreen extends StatefulWidget {
  const CropScreen({super.key, required this.page, required this.loadPreview});
  final PageEdit page;
  final Future<PagePreview> Function(PageEdit) loadPreview;
  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  late PageEdit _page;
  late Future<PagePreview> _future;
  @override
  void initState() {
    super.initState();
    _page = widget.page;
    _future = widget.loadPreview(_page);
  }

  void _rotate(int turns) => setState(() {
    for (var i = 0; i < turns; i++) {
      _page = _page.rotate();
    }
    _future = widget.loadPreview(_page);
  });
  Future<void> _precise() async {
    var crop = _page.crop;
    final next = await showModalBottomSheet<PageCrop>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: StatefulBuilder(
            builder: (context, update) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CropSliders(
                  crop: crop,
                  onChanged: (value) => update(() => crop = value),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, crop),
                  child: Text(AppLocalizations.of(context).applyCrop),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (next != null && mounted) {
      setState(() => _page = _page.copyWith(crop: next));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff55b79f),
        brightness: Brightness.dark,
      ).copyWith(primary: const Color(0xff65cab2)),
      scaffoldBackgroundColor: const Color(0xff191b1c),
    );
    return Theme(
      data: theme,
      child: FutureBuilder<PagePreview>(
        future: _future,
        builder: (context, snapshot) {
          final ready =
              snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData &&
              !snapshot.hasError;
          return Scaffold(
            appBar: AppBar(
              title: Text(s.cropTool),
              leading: IconButton(
                tooltip: s.cancel,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: ready
                          ? CropCanvas(
                              preview: snapshot.requireData,
                              crop: _page.crop,
                              onChanged: (crop) => setState(
                                () => _page = _page.copyWith(crop: crop),
                              ),
                            )
                          : snapshot.hasError
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(editFailureMessage(s, snapshot.error)),
                                  TextButton(
                                    onPressed: () => setState(
                                      () => _future = widget.loadPreview(_page),
                                    ),
                                    child: Text(s.retry),
                                  ),
                                ],
                              ),
                            )
                          : Center(
                              child: CircularProgressIndicator(
                                semanticsLabel: s.loading,
                              ),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      s.cropShortHelp,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: ready ? () => _rotate(3) : null,
                        icon: const Icon(Icons.rotate_left),
                        label: Text(s.rotateLeft),
                      ),
                      TextButton.icon(
                        onPressed: ready ? () => _rotate(1) : null,
                        icon: const Icon(Icons.rotate_right),
                        label: Text(s.rotateRight),
                      ),
                      TextButton.icon(
                        onPressed: ready
                            ? () => setState(
                                () => _page = _page.copyWith(
                                  crop: const PageCrop(),
                                ),
                              )
                            : null,
                        icon: const Icon(Icons.open_in_full),
                        label: Text(s.cropFullPage),
                      ),
                      TextButton(
                        onPressed: ready ? _precise : null,
                        child: Text(s.preciseCrop),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: ready
                            ? () => Navigator.pop(context, _page)
                            : null,
                        icon: const Icon(Icons.check),
                        label: Text(s.applyCrop),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
