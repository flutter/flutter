import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'unmigrated_sample_plugin_platform_interface.dart';

/// An implementation of [UnmigratedSamplePluginPlatform] that uses method channels.
class MethodChannelUnmigratedSamplePlugin extends UnmigratedSamplePluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('unmigrated_sample_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
