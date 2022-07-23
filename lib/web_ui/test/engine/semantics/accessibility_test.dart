// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show Future;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/semantics.dart';
import 'package:ui/src/engine/services.dart';

const StandardMessageCodec codec = StandardMessageCodec();
const String testMessage = 'This is an tooltip.';
const Map<dynamic, dynamic> testInput = <dynamic, dynamic>{
  'data': <dynamic, dynamic>{'message': testMessage}
};

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  late AccessibilityAnnouncements accessibilityAnnouncements;

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
      expect(domDocument.getElementById('accessibility-element'), isNull);

      accessibilityAnnouncements.handleMessage(codec,
          codec.encodeMessage(testInput));
      expect(
        domDocument.getElementById('accessibility-element'),
        isNotNull,
      );
      final DomHTMLLabelElement input =
          domDocument.getElementById('accessibility-element')! as DomHTMLLabelElement;
      expect(input.getAttribute('aria-live'), equals('polite'));
      expect(input.text, testMessage);

      // The element should have been removed after the duration.
      Future<void>.delayed(
          accessibilityAnnouncements.durationA11yMessageIsOnDom,
          () =>
              expect(domDocument.getElementById('accessibility-element'), isNull));
    });

    test('Default value of aria-live is polite when assertiveness is not specified', () {
      const Map<dynamic, dynamic> testInput = <dynamic, dynamic>{'data': <dynamic, dynamic>{'message': 'message'}};
      accessibilityAnnouncements.handleMessage(codec, codec.encodeMessage(testInput));
      final DomHTMLLabelElement input = domDocument.getElementById('accessibility-element')! as DomHTMLLabelElement;

      expect(input.getAttribute('aria-live'), equals('polite'));
    });

     test('aria-live is assertive when assertiveness is set to 1', () {
      const Map<dynamic, dynamic> testInput = <dynamic, dynamic>{'data': <dynamic, dynamic>{'message': 'message', 'assertiveness': 1}};
      accessibilityAnnouncements.handleMessage(codec, codec.encodeMessage(testInput));
      final DomHTMLLabelElement input = domDocument.getElementById('accessibility-element')! as DomHTMLLabelElement;

      expect(input.getAttribute('aria-live'), equals('assertive'));
    });

    test('aria-live is polite when assertiveness is null', () {
      const Map<dynamic, dynamic> testInput = <dynamic, dynamic>{'data': <dynamic, dynamic>{'message': 'message', 'assertiveness': null}};
      accessibilityAnnouncements.handleMessage(codec, codec.encodeMessage(testInput));
      final DomHTMLLabelElement input = domDocument.getElementById('accessibility-element')! as DomHTMLLabelElement;

      expect(input.getAttribute('aria-live'), equals('polite'));
    });

    test('aria-live is polite when assertiveness is set to 0', () {
      const Map<dynamic, dynamic> testInput = <dynamic, dynamic>{'data': <dynamic, dynamic>{'message': 'message', 'assertiveness': 0}};
      accessibilityAnnouncements.handleMessage(codec, codec.encodeMessage(testInput));
      final DomHTMLLabelElement input = domDocument.getElementById('accessibility-element')! as DomHTMLLabelElement;

      expect(input.getAttribute('aria-live'), equals('polite'));
    });
  });
}
