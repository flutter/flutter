import 'package:flutter_test/flutter_test.dart';
import 'package:unmigrated_sample_plugin/unmigrated_sample_plugin.dart';
import 'package:unmigrated_sample_plugin/unmigrated_sample_plugin_platform_interface.dart';
import 'package:unmigrated_sample_plugin/unmigrated_sample_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockUnmigratedSamplePluginPlatform
    with MockPlatformInterfaceMixin
    implements UnmigratedSamplePluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final UnmigratedSamplePluginPlatform initialPlatform = UnmigratedSamplePluginPlatform.instance;

  test('$MethodChannelUnmigratedSamplePlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelUnmigratedSamplePlugin>());
  });

  test('getPlatformVersion', () async {
    UnmigratedSamplePlugin unmigratedSamplePlugin = UnmigratedSamplePlugin();
    MockUnmigratedSamplePluginPlatform fakePlatform = MockUnmigratedSamplePluginPlatform();
    UnmigratedSamplePluginPlatform.instance = fakePlatform;

    expect(await unmigratedSamplePlugin.getPlatformVersion(), '42');
  });
}
