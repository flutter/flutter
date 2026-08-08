import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sample_consuming_plugin_method_channel.dart';

abstract class SampleConsumingPluginPlatform extends PlatformInterface {
  /// Constructs a SampleConsumingPluginPlatform.
  SampleConsumingPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static SampleConsumingPluginPlatform _instance = MethodChannelSampleConsumingPlugin();

  /// The default instance of [SampleConsumingPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelSampleConsumingPlugin].
  static SampleConsumingPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SampleConsumingPluginPlatform] when
  /// they register themselves.
  static set instance(SampleConsumingPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
