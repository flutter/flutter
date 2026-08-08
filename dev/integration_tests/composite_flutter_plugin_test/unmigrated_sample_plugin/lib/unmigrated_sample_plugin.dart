
import 'unmigrated_sample_plugin_platform_interface.dart';
export 'blue_box.dart';

class UnmigratedSamplePlugin {
  Future<String?> getPlatformVersion() {
    return UnmigratedSamplePluginPlatform.instance.getPlatformVersion();
  }
}
