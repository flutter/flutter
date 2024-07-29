// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_api_samples/material/selection_area/selection_area.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {

  Future<void> sendKeyCombination(
    WidgetTester tester,
    SingleActivator activator,
  ) async {
    final List<LogicalKeyboardKey> modifiers = <LogicalKeyboardKey>[
      if (activator.control) LogicalKeyboardKey.control,
      if (activator.meta) LogicalKeyboardKey.meta,
    ];
    for (final LogicalKeyboardKey modifier in modifiers) {
      await tester.sendKeyDownEvent(modifier);
    }
    await tester.sendKeyDownEvent(activator.trigger);
    await tester.sendKeyUpEvent(activator.trigger);
    await tester.pump();
    for (final LogicalKeyboardKey modifier in modifiers.reversed) {
      await tester.sendKeyUpEvent(modifier);
    }
  }

  testWidgets('Mouse hovering over selectable Text uses SystemMouseCursor.text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SelectionAreaExampleApp(),
    );


    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.widgetWithText(AppBar, 'SelectionArea Sample')));

    await tester.pump();

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);

    for (int i = 1; i <= 3; i++) {
      await gesture.moveTo(tester.getCenter(find.text('Row $i')));
      await tester.pump();
      expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);
    }
  });

  testWidgets('can select all non-Apple', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SelectionAreaExampleApp(),
    );
    await tester.tapAt(tester.getCenter(find.widgetWithText(AppBar, 'SelectionArea Sample'))); // Put the focus to the title.
    await tester.pump();

    await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.keyA, control: true));
    await tester.pump();

    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('SelectionArea Sample'), matching: find.byType(RichText)));
    expect(paragraph.selections[0], const TextSelection(baseOffset: 0, extentOffset: 'SelectionArea Sample'.length));
    for (int i = 1; i <= 3; i++) {
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Row $i'), matching: find.byType(RichText)));
      expect(paragraph.selections[0], TextSelection(baseOffset: 0, extentOffset: 'Row $i'.length));
    }
  }, variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.android, TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.fuchsia}));

  testWidgets('can select all - Apple', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SelectionAreaExampleApp(),
    );
    await tester.tapAt(tester.getCenter(find.widgetWithText(AppBar, 'SelectionArea Sample'))); // Put the focus to the title.
    await tester.pump();

    await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.keyA, meta: true));
    await tester.pump();

    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('SelectionArea Sample'), matching: find.byType(RichText)));
    expect(paragraph.selections[0], const TextSelection(baseOffset: 0, extentOffset: 'SelectionArea Sample'.length));
    for (int i = 1; i <= 3; i++) {
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Row $i'), matching: find.byType(RichText)));
      expect(paragraph.selections[0], TextSelection(baseOffset: 0, extentOffset: 'Row $i'.length));
    }
  }, variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS, TargetPlatform.macOS}));
}
