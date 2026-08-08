import 'package:flutter_test/flutter_test.dart';
import 'package:sample_consuming_plugin/sample_consuming_plugin.dart';
import 'package:sample_consuming_plugin/sample_consuming_plugin_platform_interface.dart';
import 'package:sample_consuming_plugin/sample_consuming_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSampleConsumingPluginPlatform
    with MockPlatformInterfaceMixin
    implements SampleConsumingPluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SampleConsumingPluginPlatform initialPlatform = SampleConsumingPluginPlatform.instance;

  test('$MethodChannelSampleConsumingPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSampleConsumingPlugin>());
  });

  test('getPlatformVersion', () async {
    SampleConsumingPlugin sampleConsumingPlugin = SampleConsumingPlugin();
    MockSampleConsumingPluginPlatform fakePlatform = MockSampleConsumingPluginPlatform();
    SampleConsumingPluginPlatform.instance = fakePlatform;

    expect(await sampleConsumingPlugin.getPlatformVersion(), '42');
  });
}
