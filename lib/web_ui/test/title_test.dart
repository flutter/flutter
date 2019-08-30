// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:test/test.dart';

void main() {
  const MethodCodec codec = JSONMethodCodec();

  group('Title', () {
    test('is set on the document by platform message', () {
      // Run the unit test without emulating Flutter tester environment.
      ui.debugEmulateFlutterTesterEnvironment = false;

      // TODO(yjbanov): https://github.com/flutter/flutter/issues/39159
      document.title = '';
      expect(document.title, '');

      ui.window.sendPlatformMessage(
          'flutter/platform',
          codec.encodeMethodCall(const MethodCall(
              'SystemChrome.setApplicationSwitcherDescription',
              <String, dynamic>{
                'label': 'Title Test',
                'primaryColor': 0xFF00FF00,
              })),
          null);

      expect(document.title, 'Title Test');

      ui.window.sendPlatformMessage(
          'flutter/platform',
          codec.encodeMethodCall(const MethodCall(
              'SystemChrome.setApplicationSwitcherDescription',
              <String, dynamic>{
                'label': 'Different title',
                'primaryColor': 0xFF00FF00,
              })),
          null);

      expect(document.title, 'Different title');
    });
  });
}
