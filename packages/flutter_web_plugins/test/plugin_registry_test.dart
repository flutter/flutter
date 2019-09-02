// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('chrome') // Uses web-only Flutter SDK

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class TestPlugin {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'test_plugin',
      const StandardMethodCodec(),
      registrar.messenger,
    );
    final TestPlugin testPlugin = TestPlugin();
    channel.setMethodCallHandler(testPlugin.handleMethodCall);
  }

  static final List<String> calledMethods = <String>[];

  Future<void> handleMethodCall(MethodCall call) async {
    calledMethods.add(call.method);
  }
}

void main() {
  group('Plugin Registry', () {
    test('Can register a plugin', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      webPluginRegistry.registerMessageHandler();
      TestPlugin.calledMethods.clear();

      final Registrar registrar = webPluginRegistry.registrarFor(TestPlugin);
      TestPlugin.registerWith(registrar);

      final MethodChannel frameworkChannel =
          MethodChannel('test_plugin', const StandardMethodCodec());
      frameworkChannel.invokeMethod<void>('test1');

      expect(TestPlugin.calledMethods, ['test1']);
    });

    test('Throws when trying to send a platform message to the framework', () {
      expect(() => pluginBinaryMessenger.send('test', ByteData(0)),
          throwsFlutterError);
    });

    test('Throws when trying to set a mock handler', () {
      expect(
          () => pluginBinaryMessenger.setMockMessageHandler(
              'test', (ByteData data) async => ByteData(0)),
          throwsFlutterError);
    });
  }, skip: 'Tests will fail until 57f4ea from flutter/engine is pulled into the framework.');
}
