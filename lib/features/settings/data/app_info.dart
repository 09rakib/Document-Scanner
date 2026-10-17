import 'package:flutter/services.dart';

class AppInfo {
  static const _channel = MethodChannel('com.example.docscan/app_info');
  Future<String> version() async =>
      await _channel
          .invokeMethod<String>('version')
          .timeout(const Duration(seconds: 10)) ??
      '';
  Future<void> rate() => _channel.invokeMethod<void>('rate');
}
