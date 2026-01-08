// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  group('MediaQueryManager', () {
    late MediaQueryManager manager;

    const fakeMediaQueryString = '(fake-media-query: one)';
    const anotherFakeMediaQueryString = '(fake-media-query: another)';
    final DomEventTarget mockedMediaQuery = createDomElement('div');
    final DomEventTarget anotherMockedMediaQuery = createDomElement('div');
    final mockMap = <String, DomEventTarget>{
      fakeMediaQueryString: mockedMediaQuery,
      anotherFakeMediaQueryString: anotherMockedMediaQuery,
    };

    setUp(() {
      manager = MediaQueryManager();
      manager.debugOverrideMediaQueryBuilder = (String query) => mockMap[query]!;
    });

    test('addListener immediately calls onMatch', () {
      var called = false;
      manager.addListener(
        fakeMediaQueryString,
        onMatch: (bool match) {
          called = true;
        },
      );
      expect(called, isTrue);
    });

    test('Calls onMatch with value from event', () {
      bool? mediaQueryMatch;

      manager.addListener(
        fakeMediaQueryString,
        onMatch: (bool match) {
          mediaQueryMatch = match;
        },
      );
      expect(mediaQueryMatch, isFalse, reason: 'Default value for mocks.');

      // Trigger a DomMediaQueryListEvent
      mockedMediaQuery.dispatchEvent(
        createDomMediaQueryListEvent('change', {'media': fakeMediaQueryString, 'matches': true}),
      );
      expect(
        mediaQueryMatch,
        isTrue,
        reason: 'onMatch should be called with the `matches` value of the DomMediaQueryListEvent',
      );
    });

    test('Handles more than one media query.', () {
      bool? mediaQueryMatch;
      bool? anotherMediaQueryMatch;

      manager.addListener(
        fakeMediaQueryString,
        onMatch: (bool match) {
          mediaQueryMatch = match;
        },
      );
      manager.addListener(
        anotherFakeMediaQueryString,
        onMatch: (bool match) {
          anotherMediaQueryMatch = match;
        },
      );
      expect(mediaQueryMatch, isFalse);
      expect(anotherMediaQueryMatch, isFalse);

      mockedMediaQuery.dispatchEvent(
        createDomMediaQueryListEvent('change', {'media': fakeMediaQueryString, 'matches': true}),
      );
      expect(mediaQueryMatch, isTrue);
      expect(anotherMediaQueryMatch, isFalse);

      anotherMockedMediaQuery.dispatchEvent(
        createDomMediaQueryListEvent('change', {
          'media': anotherFakeMediaQueryString,
          'matches': true,
        }),
      );
      expect(mediaQueryMatch, isTrue);
      expect(anotherMediaQueryMatch, isTrue);
    });

    test('Listeners can be removed', () {
      bool? mediaQueryMatch;

      manager.addListener(
        fakeMediaQueryString,
        onMatch: (bool match) {
          mediaQueryMatch = match;
        },
      );
      // Trigger a DomMediaQueryListEvent
      mockedMediaQuery.dispatchEvent(
        createDomMediaQueryListEvent('change', {'media': fakeMediaQueryString, 'matches': true}),
      );
      expect(mediaQueryMatch, isTrue);

      manager.detachAll();
      // Trigger a DomMediaQueryListEvent
      mockedMediaQuery.dispatchEvent(
        createDomMediaQueryListEvent('change', {'media': fakeMediaQueryString, 'matches': false}),
      );
      expect(
        mediaQueryMatch,
        isTrue,
        reason: 'The event that sets `matches` to `false` should have been ignored.',
      );
    });
  });
}
