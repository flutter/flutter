import 'package:flutter_test/flutter_test.dart';
import 'package:sample_plugin/sample_plugin.dart';
import 'package:sample_plugin/sample_plugin_platform_interface.dart';
import 'package:sample_plugin/sample_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSamplePluginPlatform
    with MockPlatformInterfaceMixin
    implements SamplePluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SamplePluginPlatform initialPlatform = SamplePluginPlatform.instance;

  test('$MethodChannelSamplePlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSamplePlugin>());
  });

  test('getPlatformVersion', () async {
    SamplePlugin samplePlugin = SamplePlugin();
    MockSamplePluginPlatform fakePlatform = MockSamplePluginPlatform();
    SamplePluginPlatform.instance = fakePlatform;

    expect(await samplePlugin.getPlatformVersion(), '42');
  });
}
