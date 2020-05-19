// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('chrome') // Uses web-only Flutter SDK

import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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

    platformViewRegistry.registerViewFactory('test_platform_view', (int id) {
      createdViewIds.add(id);
      return html.DivElement()
        ..text = 'Testing 123'
        ..id = 'platform_view_test';
    });
  }

  static final List<String> calledMethods = <String>[];
  static final List<int> createdViewIds = <int>[];

  Future<void> handleMethodCall(MethodCall call) async {
    calledMethods.add(call.method);
  }
}

void main() {
  // Disabling tester emulation because this test relies on real message channel communication.
  // ignore: undefined_prefixed_name
  ui.debugEmulateFlutterTesterEnvironment = false;

  group('Platform View Registry', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      webPluginRegistry.registerMessageHandler();
      final Registrar registrar = webPluginRegistry.registrarFor(TestPlugin);
      TestPlugin.registerWith(registrar);
    });

    testWidgets('can register platform view', (WidgetTester tester) async {
      TestPlugin.createdViewIds.clear();
      await tester
          .pumpWidget(const HtmlElementView(viewType: 'test_platform_view'));
      expect(TestPlugin.createdViewIds.length, equals(1));
      TestPlugin.createdViewIds.clear();

      // TODO(hterkelsen): Uncomment this once the engine support lands.
      //expect(html.document.getElementById('platform_view_test'), isNotNull);
      //expect(html.document.getElementById('platform_view_test').text,
      //    equals('Testing 123'));
    });
  });
}
