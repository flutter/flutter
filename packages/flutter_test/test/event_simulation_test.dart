// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const List<String> platforms = <String>['linux', 'macos', 'android', 'fuchsia'];

void main() {
  testWidgets('simulates keyboard events', (WidgetTester tester) async {
    final List<RawKeyEvent> events = <RawKeyEvent>[];

    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      RawKeyboardListener(
        focusNode: focusNode,
        onKey: events.add,
        child: Container(),
      ),
    );

    focusNode.requestFocus();
    await tester.idle();

    for (final String platform in platforms) {
      await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft, platform: platform);
      await tester.sendKeyEvent(LogicalKeyboardKey.shift, platform: platform);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA, platform: platform);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA, platform: platform);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.numpad1, platform: platform);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.numpad1, platform: platform);
      await tester.idle();

      expect(events.length, 8);
      for (int i = 0; i < events.length; ++i) {
        final bool isEven = i.isEven;
        if (isEven) {
          expect(events[i].runtimeType, equals(RawKeyDownEvent));
        } else {
          expect(events[i].runtimeType, equals(RawKeyUpEvent));
        }
        if (i < 4) {
          expect(events[i].data.isModifierPressed(ModifierKey.shiftModifier, side: KeyboardSide.left), equals(isEven));
        }
      }
      events.clear();
    }

    await tester.pumpWidget(Container());
    focusNode.dispose();
  });
}
