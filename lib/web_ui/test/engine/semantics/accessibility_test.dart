// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/initialization.dart';
import 'package:ui/src/engine/semantics.dart';
import 'package:ui/src/engine/services.dart';

const StandardMessageCodec codec = StandardMessageCodec();

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpAll(() async {
    await initializeEngine();
  });

  group('$AccessibilityAnnouncements', () {
    void expectAnnouncementElements({required bool present}) {
      expect(
        domDocument.getElementById('ftl-announcement-polite'),
        present ? isNotNull : isNull,
      );
      expect(
        domDocument.getElementById('ftl-announcement-assertive'),
        present ? isNotNull : isNull,
      );
    }

    test('Initialization and disposal', () {
      // Elements should be there right after engine initialization.
      expectAnnouncementElements(present: true);

      accessibilityAnnouncements.dispose();
      expectAnnouncementElements(present: false);

      initializeAccessibilityAnnouncements();
      expectAnnouncementElements(present: true);
    });

    void resetAccessibilityAnnouncements() {
      accessibilityAnnouncements.dispose();
      initializeAccessibilityAnnouncements();
      expectAnnouncementElements(present: true);
    }

    test('Default value of aria-live is polite when assertiveness is not specified', () {
      resetAccessibilityAnnouncements();
      const Map<dynamic, dynamic> testInput = <dynamic, dynamic>{'data': <dynamic, dynamic>{'message': 'polite message'}};
      accessibilityAnnouncements.handleMessage(codec, codec.encodeMessage(testInput));
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.polite).text, 'polite message');
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.assertive).text, '');
    });

    test('aria-live is assertive when assertiveness is set to 1', () {
      resetAccessibilityAnnouncements();
      const Map<dynamic, dynamic> testInput = <dynamic, dynamic>{'data': <dynamic, dynamic>{'message': 'assertive message', 'assertiveness': 1}};
      accessibilityAnnouncements.handleMessage(codec, codec.encodeMessage(testInput));
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.polite).text, '');
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.assertive).text, 'assertive message');
    });

    test('aria-live is polite when assertiveness is null', () {
      resetAccessibilityAnnouncements();
      const Map<dynamic, dynamic> testInput = <dynamic, dynamic>{'data': <dynamic, dynamic>{'message': 'polite message', 'assertiveness': null}};
      accessibilityAnnouncements.handleMessage(codec, codec.encodeMessage(testInput));
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.polite).text, 'polite message');
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.assertive).text, '');
    });

    test('aria-live is polite when assertiveness is set to 0', () {
      resetAccessibilityAnnouncements();
      const Map<dynamic, dynamic> testInput = <dynamic, dynamic>{'data': <dynamic, dynamic>{'message': 'polite message', 'assertiveness': 0}};
      accessibilityAnnouncements.handleMessage(codec, codec.encodeMessage(testInput));
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.polite).text, 'polite message');
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.assertive).text, '');
    });

    test('The same message announced twice is altered to convince the screen reader to read it again.', () {
      resetAccessibilityAnnouncements();
      const Map<dynamic, dynamic> testInput = <dynamic, dynamic>{'data': <dynamic, dynamic>{'message': 'Hello'}};
      accessibilityAnnouncements.handleMessage(codec, codec.encodeMessage(testInput));
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.polite).text, 'Hello');
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.assertive).text, '');

      // The DOM value gains a "." to make the message look updated.
      const Map<dynamic, dynamic> testInput2 = <dynamic, dynamic>{'data': <dynamic, dynamic>{'message': 'Hello'}};
      accessibilityAnnouncements.handleMessage(codec, codec.encodeMessage(testInput2));
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.polite).text, 'Hello.');
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.assertive).text, '');

      // Now the "." is removed because the message without it will also look updated.
      const Map<dynamic, dynamic> testInput3 = <dynamic, dynamic>{'data': <dynamic, dynamic>{'message': 'Hello'}};
      accessibilityAnnouncements.handleMessage(codec, codec.encodeMessage(testInput3));
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.polite).text, 'Hello');
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.assertive).text, '');
    });

    test('announce() polite', () {
      resetAccessibilityAnnouncements();
      accessibilityAnnouncements.announce('polite message', Assertiveness.polite);
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.polite).text, 'polite message');
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.assertive).text, '');
    });

    test('announce() assertive', () {
      resetAccessibilityAnnouncements();
      accessibilityAnnouncements.announce('assertive message', Assertiveness.assertive);
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.polite).text, '');
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.assertive).text, 'assertive message');
    });
  });
}
