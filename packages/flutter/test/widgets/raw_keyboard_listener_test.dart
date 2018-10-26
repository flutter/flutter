// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void sendFakeKeyEvent(Map<String, dynamic> data) {
  BinaryMessages.handlePlatformMessage(
    SystemChannels.keyEvent.name,
    SystemChannels.keyEvent.codec.encodeMessage(data),
    (ByteData data) { },
  );
}

void main() {
  testWidgets('Can dispose without keyboard', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    await tester.pumpWidget(RawKeyboardListener(focusNode: focusNode, onKey: null, child: Container()));
    await tester.pumpWidget(RawKeyboardListener(focusNode: focusNode, onKey: null, child: Container()));
    await tester.pumpWidget(Container());
  });

  testWidgets('Fuchsia key event', (WidgetTester tester) async {
    final List<RawKeyEvent> events = <RawKeyEvent>[];

    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(RawKeyboardListener(
      focusNode: focusNode,
      onKey: events.add,
      child: Container(),
    ));

    tester.binding.focusManager.rootScope.requestFocus(focusNode);
    await tester.idle();

    sendFakeKeyEvent(<String, dynamic>{
      'type': 'keydown',
      'keymap': 'fuchsia',
      'hidUsage': 0x04,
      'codePoint': 0x64,
      'modifiers': 0x08,
    });
    await tester.idle();

    expect(events.length, 1);
    expect(events[0].runtimeType, equals(RawKeyDownEvent));
    expect(events[0].data.runtimeType, equals(RawKeyEventDataFuchsia));
    final RawKeyEventDataFuchsia typedData = events[0].data;
    expect(typedData.hidUsage, 0x04);
    expect(typedData.codePoint, 0x64);
    expect(typedData.modifiers, 0x08);

    await tester.pumpWidget(Container());
    focusNode.dispose();
  });

  testWidgets('Defunct listeners do not receive events',
      (WidgetTester tester) async {
    final List<RawKeyEvent> events = <RawKeyEvent>[];

    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(RawKeyboardListener(
      focusNode: focusNode,
      onKey: events.add,
      child: Container(),
    ));

    tester.binding.focusManager.rootScope.requestFocus(focusNode);
    await tester.idle();

    sendFakeKeyEvent(<String, dynamic>{
      'type': 'keydown',
      'keymap': 'fuchsia',
      'hidUsage': 0x04,
      'codePoint': 0x64,
      'modifiers': 0x08,
    });
    await tester.idle();

    expect(events.length, 1);
    events.clear();

    await tester.pumpWidget(Container());

    sendFakeKeyEvent(<String, dynamic>{
      'type': 'keydown',
      'keymap': 'fuchsia',
      'hidUsage': 0x04,
      'codePoint': 0x64,
      'modifiers': 0x08,
    });

    await tester.idle();

    expect(events.length, 0);

    await tester.pumpWidget(Container());
    focusNode.dispose();
  });
}
