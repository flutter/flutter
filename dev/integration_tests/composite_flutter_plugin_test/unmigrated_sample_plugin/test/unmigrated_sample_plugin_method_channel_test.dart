import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unmigrated_sample_plugin/unmigrated_sample_plugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelUnmigratedSamplePlugin platform = MethodChannelUnmigratedSamplePlugin();
  const MethodChannel channel = MethodChannel('unmigrated_sample_plugin');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
