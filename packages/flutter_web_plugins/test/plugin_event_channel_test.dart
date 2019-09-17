// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('chrome') // Uses web-only Flutter SDK

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
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
  group('Plugin Event Channel', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      webPluginRegistry.registerMessageHandler();
    });

    test('can send events to an $EventChannel', () async {
      EventChannel listeningChannel = EventChannel('test');
      PluginEventChannel sendingChannel = PluginEventChannel('test');

      StreamController<String> controller = StreamController();
      sendingChannel.controller = controller;

      expect(listeningChannel.receiveBroadcastStream(),
          emitsInOrder(<String>['hello', 'world']));

      controller.add('hello');
      controller.add('world');
      await controller.close();
    });

    test('can send errors to an $EventChannel', () async {
      EventChannel listeningChannel = EventChannel('test2');
      PluginEventChannel sendingChannel = PluginEventChannel('test2');

      StreamController<String> controller = StreamController();
      sendingChannel.controller = controller;

      expect(
          listeningChannel.receiveBroadcastStream(),
          emitsError(predicate<dynamic>((dynamic e) =>
              e is PlatformException && e.message == 'Test error')));

      controller.addError('Test error');
      await controller.close();
    });

    test('receives a listen event', () async {
      EventChannel listeningChannel = EventChannel('test3');
      PluginEventChannel sendingChannel = PluginEventChannel('test3');

      StreamController<String> controller =
          StreamController(onListen: expectAsync0<void>(() {}, count: 1));
      sendingChannel.controller = controller;

      expect(listeningChannel.receiveBroadcastStream(),
          emitsInOrder(<String>['hello']));

      controller.add('hello');
      await controller.close();
    });

    test('receives a cancel event', () async {
      EventChannel listeningChannel = EventChannel('test4');
      PluginEventChannel sendingChannel = PluginEventChannel('test4');

      StreamController<String> controller =
          StreamController(onCancel: expectAsync0<void>(() {}));
      sendingChannel.controller = controller;

      final Stream eventStream = listeningChannel.receiveBroadcastStream();
      StreamSubscription subscription;
      subscription = eventStream.listen(expectAsync1<void, dynamic>((dynamic x) {
        expect(x, equals('hello'));
        subscription.cancel();
      }));

      controller.add('hello');
    });
  });
}
