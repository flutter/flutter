import 'sample_plugin_platform_interface.dart';
export 'red_box.dart';

class SamplePlugin {
  Future<String?> getPlatformVersion() {
    return SamplePluginPlatform.instance.getPlatformVersion();
  }
}
