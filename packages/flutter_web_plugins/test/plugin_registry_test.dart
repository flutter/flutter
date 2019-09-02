// Copyright 2019 The Chromium Authors. All rights reserved.
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
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      webPluginRegistry.registerMessageHandler();
    });

    test('Can register a plugin', () {
      TestPlugin.calledMethods.clear();

      final Registrar registrar = webPluginRegistry.registrarFor(TestPlugin);
      TestPlugin.registerWith(registrar);

      const MethodChannel frameworkChannel =
          MethodChannel('test_plugin', StandardMethodCodec());
      frameworkChannel.invokeMethod<void>('test1');

      expect(TestPlugin.calledMethods, <String>['test1']);
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
  });
}
