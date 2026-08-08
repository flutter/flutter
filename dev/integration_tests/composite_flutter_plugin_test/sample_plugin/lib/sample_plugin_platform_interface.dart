import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sample_plugin_method_channel.dart';

abstract class SamplePluginPlatform extends PlatformInterface {
  /// Constructs a SamplePluginPlatform.
  SamplePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static SamplePluginPlatform _instance = MethodChannelSamplePlugin();

  /// The default instance of [SamplePluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelSamplePlugin].
  static SamplePluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SamplePluginPlatform] when
  /// they register themselves.
  static set instance(SamplePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
