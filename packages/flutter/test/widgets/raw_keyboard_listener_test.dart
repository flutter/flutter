// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('`FocusNode.onKey` test', (WidgetTester tester) async {
    final GlobalKey key1 = GlobalKey(debugLabel: '1');
    bool? keyEventHandled;
    final FocusNode focusNode = FocusNode(
        onKey: (FocusNode node, RawKeyEvent event) {
          keyEventHandled = true;
          return KeyEventResult.handled;
        }
    );

    await tester.pumpWidget(
      RawKeyboardListener(
        focusNode: focusNode,
        child: Container(key: key1),
      ),
    );

    Focus.of(key1.currentContext!).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(keyEventHandled, true);
  });

  testWidgets('Can dispose without keyboard', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    await tester.pumpWidget(RawKeyboardListener(focusNode: focusNode, onKey: null, child: Container()));
    await tester.pumpWidget(RawKeyboardListener(focusNode: focusNode, onKey: null, child: Container()));
    await tester.pumpWidget(Container());
  });

  testWidgets('Fuchsia key event', (WidgetTester tester) async {
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

    await tester.sendKeyEvent(LogicalKeyboardKey.metaLeft, platform: 'fuchsia');
    await tester.idle();

    expect(events.length, 2);
    expect(events[0].runtimeType, equals(RawKeyDownEvent));
    expect(events[0].data.runtimeType, equals(RawKeyEventDataFuchsia));
    final RawKeyEventDataFuchsia typedData = events[0].data as RawKeyEventDataFuchsia;
    expect(typedData.hidUsage, 0x700e3);
    expect(typedData.codePoint, 0x0);
    expect(typedData.modifiers, RawKeyEventDataFuchsia.modifierLeftMeta);
    expect(typedData.isModifierPressed(ModifierKey.metaModifier, side: KeyboardSide.left), isTrue);

    await tester.pumpWidget(Container());
    focusNode.dispose();
  }, skip: isBrowser); // This is a Fuchsia-specific test.

  testWidgets('Web key event', (WidgetTester tester) async {
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

    await tester.sendKeyEvent(LogicalKeyboardKey.metaLeft, platform: 'web');
    await tester.idle();

    expect(events.length, 2);
    expect(events[0].runtimeType, equals(RawKeyDownEvent));
    expect(events[0].data, isA<RawKeyEventDataWeb>());
    final RawKeyEventDataWeb typedData = events[0].data as RawKeyEventDataWeb;
    expect(typedData.code, 'MetaLeft');
    expect(typedData.metaState, RawKeyEventDataWeb.modifierMeta);
    expect(typedData.isModifierPressed(ModifierKey.metaModifier, side: KeyboardSide.left), isTrue);

    await tester.pumpWidget(Container());
    focusNode.dispose();
  });

  testWidgets('Defunct listeners do not receive events', (WidgetTester tester) async {
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

    await tester.sendKeyEvent(LogicalKeyboardKey.metaLeft, platform: 'fuchsia');
    await tester.idle();

    expect(events.length, 2);
    events.clear();

    await tester.pumpWidget(Container());

    await tester.sendKeyEvent(LogicalKeyboardKey.metaLeft, platform: 'fuchsia');

    await tester.idle();

    expect(events.length, 0);

    await tester.pumpWidget(Container());
    focusNode.dispose();
  });
}
