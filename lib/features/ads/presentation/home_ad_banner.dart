import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/ad_contracts.dart';
import '../providers/ad_providers.dart';

class HomeAdBanner extends ConsumerWidget {
  const HomeAdBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(adServiceProvider);
    if (!service.bannerAllowed || ModalRoute.isCurrentOf(context) != true) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.floor();
          if (width < 1) return const SizedBox.shrink();
          return _Banner(key: ValueKey(width), width: width);
        },
      ),
    );
  }
}

class _Banner extends ConsumerStatefulWidget {
  const _Banner({super.key, required this.width});
  final int width;
  @override
  ConsumerState<_Banner> createState() => _BannerState();
}

class _BannerState extends ConsumerState<_Banner> {
  BannerHandle? _ad;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ad = await ref.read(adServiceProvider).loadBanner(widget.width);
    if (!mounted) {
      ad?.dispose();
      return;
    }
    setState(() => _ad = ad);
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            AppLocalizations.of(context).advertisement,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        SizedBox(width: ad.width, height: ad.height, child: ad.widget),
      ],
    );
  }
}
