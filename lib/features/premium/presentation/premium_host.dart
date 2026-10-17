import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/premium_providers.dart';

class PremiumHost extends ConsumerStatefulWidget {
  const PremiumHost({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<PremiumHost> createState() => _PremiumHostState();
}

class _PremiumHostState extends ConsumerState<PremiumHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(premiumBootstrapProvider)) {
      ref.read(premiumServiceProvider).resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(premiumBootstrapProvider)) {
      final service = ref.watch(premiumServiceProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(service.start());
      });
    }
    return widget.child;
  }
}
