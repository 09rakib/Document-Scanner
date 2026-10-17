import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../documents/providers/document_providers.dart';
import '../../scan/providers/scan_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../providers/ad_providers.dart';
import '../../premium/providers/premium_providers.dart';

class AdHost extends ConsumerStatefulWidget {
  const AdHost({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<AdHost> createState() => _AdHostState();
}

class _AdHostState extends ConsumerState<AdHost> with WidgetsBindingObserver {
  late final GoRouter _router;
  bool _queued = false;
  void _queuePump() {
    if (_queued || !mounted) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      if (!mounted) return;
      final service = ref.read(adServiceProvider);
      service.setForeground(
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
      );
      service.pump();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = ref.read(appRouterProvider);
    _router.routerDelegate.addListener(_queuePump);
    final service = ref.read(adServiceProvider);
    service.safeToPresent = () {
      if (!mounted ||
          ref.read(settingsProvider).value?.onboarded != true ||
          ref.read(scanControllerProvider).isLoading ||
          ref.read(documentBusyProvider)) {
        return false;
      }
      if (ref.read(premiumBootstrapProvider) &&
          ref.read(premiumServiceProvider).storeBusy) {
        return false;
      }
      final route = ref.read(appRouterProvider).state.uri.path;
      return route == '/' || route == '/settings';
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref
        .read(adServiceProvider)
        .setForeground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) ref.read(adServiceProvider).pump();
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_queuePump);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(adServiceProvider);
    if (ref.watch(premiumBootstrapProvider)) {
      ref.watch(premiumServiceProvider);
    }
    ref.watch(settingsProvider);
    ref.watch(scanControllerProvider);
    ref.watch(documentBusyProvider);
    _queuePump();
    return AbsorbPointer(absorbing: service.modalBusy, child: widget.child);
  }
}
