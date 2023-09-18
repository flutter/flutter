// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('$MouseCursor', () {
    test('sets correct `cursor` style on root element', () {
      final DomElement rootViewElement = createDomElement('div');
      final MouseCursor mouseCursor = MouseCursor(rootViewElement);

      mouseCursor.activateSystemCursor('alias');
      expect(rootViewElement.style.cursor, 'alias');

      mouseCursor.activateSystemCursor('move');
      expect(rootViewElement.style.cursor, 'move');

      mouseCursor.activateSystemCursor('precise');
      expect(rootViewElement.style.cursor, 'crosshair');

      mouseCursor.activateSystemCursor('resizeDownRight');
      expect(rootViewElement.style.cursor, 'se-resize');
    });

    test('handles unknown cursor type', () {
      final DomElement rootViewElement = createDomElement('div');
      final MouseCursor mouseCursor = MouseCursor(rootViewElement);

      mouseCursor.activateSystemCursor('unknown');
      expect(rootViewElement.style.cursor, 'default');
    });
  });
}
