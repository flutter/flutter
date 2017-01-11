// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void sendFakeKeyEvent(Map<String, dynamic> data) {
  String message = JSON.encode(data);
  Uint8List encoded = UTF8.encoder.convert(message);
  PlatformMessages.handlePlatformMessage(
      'flutter/keyevent', encoded.buffer.asByteData(), (_) {});
}

void main() {
  testWidgets('Can dispose without keyboard', (WidgetTester tester) async {
    await tester.pumpWidget(new RawKeyboardListener(child: new Container()));
    await tester.pumpWidget(new RawKeyboardListener(child: new Container()));
    await tester.pumpWidget(new Container());
  });

  testWidgets('Fuchsia key event', (WidgetTester tester) async {
    List<RawKeyEvent> events = <RawKeyEvent>[];

    await tester.pumpWidget(new RawKeyboardListener(
      focused: true,
      onKey: (RawKeyEvent event) {
        events.add(event);
      },
      child: new Container(),
    ));

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
    RawKeyEventDataFuchsia typedData = events[0].data;
    expect(typedData.hidUsage, 0x04);
    expect(typedData.codePoint, 0x64);
    expect(typedData.modifiers, 0x08);
  });

  testWidgets('Defunct listeners do not receive events',
      (WidgetTester tester) async {
    List<RawKeyEvent> events = <RawKeyEvent>[];

    await tester.pumpWidget(new RawKeyboardListener(
      focused: true,
      onKey: (RawKeyEvent event) {
        events.add(event);
      },
      child: new Container(),
    ));

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

    await tester.pumpWidget(new Container());

    sendFakeKeyEvent(<String, dynamic>{
      'type': 'keydown',
      'keymap': 'fuchsia',
      'hidUsage': 0x04,
      'codePoint': 0x64,
      'modifiers': 0x08,
    });

    await tester.idle();

    expect(events.length, 0);
  });
}
