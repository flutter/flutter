import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'unmigrated_sample_plugin_method_channel.dart';

abstract class UnmigratedSamplePluginPlatform extends PlatformInterface {
  /// Constructs a UnmigratedSamplePluginPlatform.
  UnmigratedSamplePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static UnmigratedSamplePluginPlatform _instance = MethodChannelUnmigratedSamplePlugin();

  /// The default instance of [UnmigratedSamplePluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelUnmigratedSamplePlugin].
  static UnmigratedSamplePluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [UnmigratedSamplePluginPlatform] when
  /// they register themselves.
  static set instance(UnmigratedSamplePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
