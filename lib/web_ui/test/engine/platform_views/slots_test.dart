// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:ui/src/engine.dart';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('PlatformViewManager', () {
    final int viewId = 6;

    group('createPlatformViewSlot', () {
      test(
          'can render slot, even for views that might have never been rendered before',
          () async {
        final html.Element slot = createPlatformViewSlot(viewId);
        expect(slot, isNotNull);
        expect(slot.querySelector('slot'), isNotNull);
      });

      test('rendered markup contains required attributes', () async {
        final html.Element slot = createPlatformViewSlot(viewId);
        expect(slot.style.pointerEvents, 'auto',
            reason:
                'Should re-enable pointer events for the contents of the view.');
        final html.Element innerSlot = slot.querySelector('slot')!;
        expect(innerSlot.getAttribute('name'), contains('$viewId'),
            reason:
                'The name attribute of the inner SLOT tag must refer to the viewId.');
      });
    });
  });
}
