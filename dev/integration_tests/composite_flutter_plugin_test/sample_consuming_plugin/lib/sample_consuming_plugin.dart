
import 'sample_consuming_plugin_platform_interface.dart';
export 'double_box.dart';

class SampleConsumingPlugin {
  Future<String?> getPlatformVersion() {
    return SampleConsumingPluginPlatform.instance.getPlatformVersion();
  }
}
