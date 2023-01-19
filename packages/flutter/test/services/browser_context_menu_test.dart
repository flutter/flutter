// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> log = <MethodCall>[];

  Future<void> verify(AsyncCallback test, List<Object> expectations) async {
    log.clear();
    await test();
    expect(log, expectations);
  }

  test('disableContextMenu calls its platform channel method', () async {
    // Asserts when not on web.
    if (!kIsWeb) {
      try {
        BrowserContextMenu.disableContextMenu();
      } catch (error) {
        expect(error, isAssertionError);
      }
      return;
    }

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.contextMenu, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    await verify(BrowserContextMenu.disableContextMenu, <Object>[
      isMethodCall('disableContextMenu', arguments: null),
    ]);

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.contextMenu, null);
  });

  test('enableContextMenu calls its platform channel method', () async {
    // Asserts when not on web.
    if (!kIsWeb) {
      try {
        BrowserContextMenu.enableContextMenu();
      } catch (error) {
        expect(error, isAssertionError);
      }
      return;
    }

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.contextMenu, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    await verify(BrowserContextMenu.enableContextMenu, <Object>[
      isMethodCall('enableContextMenu', arguments: null),
    ]);

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.contextMenu, null);
  });
}
