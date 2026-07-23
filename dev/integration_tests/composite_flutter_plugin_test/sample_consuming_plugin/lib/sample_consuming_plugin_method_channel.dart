import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sample_consuming_plugin_platform_interface.dart';

/// An implementation of [SampleConsumingPluginPlatform] that uses method channels.
class MethodChannelSampleConsumingPlugin extends SampleConsumingPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sample_consuming_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
