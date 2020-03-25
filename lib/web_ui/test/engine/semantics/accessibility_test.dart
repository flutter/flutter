// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async' show Future;
import 'dart:html';

import 'package:ui/src/engine.dart';
import 'package:test/test.dart';

const MessageCodec<dynamic> codec = StandardMessageCodec();
const String testMessage = 'This is an tooltip.';
const Map<dynamic, dynamic> testInput = <dynamic, dynamic>{
  'data': <dynamic, dynamic>{'message': testMessage}
};

void main() {
  AccessibilityAnnouncements accessibilityAnnouncements;

  group('$AccessibilityAnnouncements', () {
    setUp(() {
      accessibilityAnnouncements = AccessibilityAnnouncements.instance;
    });

    test(
        'Creates element when handling a message and removes '
        'is after a delay', () {
      // Set the a11y announcement's duration on DOM to half seconds.
      accessibilityAnnouncements.durationA11yMessageIsOnDom =
          const Duration(milliseconds: 500);

      // Initially there is no accessibility-element
      expect(document.getElementById('accessibility-element'), isNull);

      accessibilityAnnouncements.handleMessage(codec,
          codec.encodeMessage(testInput));
      expect(
        document.getElementById('accessibility-element'),
        isNotNull,
      );
      final LabelElement input =
          document.getElementById('accessibility-element');
      expect(input.getAttribute('aria-live'), equals('polite'));
      expect(input.text, testMessage);

      // The element should have been removed after the duration.
      Future<void>.delayed(
          accessibilityAnnouncements.durationA11yMessageIsOnDom,
          () =>
              expect(document.getElementById('accessibility-element'), isNull));
    });
  });
}
