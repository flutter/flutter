// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
@TestOn('!chrome')
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Cursor animates on iOS',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Material(child: TextField())));

      final Finder textFinder = find.byType(TextField);
      await tester.tap(textFinder);
      await tester.pump();

      final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
      final RenderEditable renderEditable = editableTextState.renderEditable;

      expect(renderEditable.cursorColor!.opacity, 1.0);

      var walltimeMicrosecond = 0;
      var lastVerifiedOpacity = 1.0;

      Future<void> verifyKeyFrame({required double opacity, required int at}) async {
        const delta = 1;
        assert(at - delta > walltimeMicrosecond);
        await tester.pump(Duration(microseconds: at - delta - walltimeMicrosecond));

        // Instead of verifying the opacity at each key frame, this function
        // verifies the opacity immediately *before* each key frame to avoid
        // fp precision issues.
        expect(
          renderEditable.cursorColor!.opacity,
          closeTo(lastVerifiedOpacity, 0.01),
          reason: 'opacity at ${at - delta} microseconds',
        );

        walltimeMicrosecond = at - delta;
        lastVerifiedOpacity = opacity;
      }

      await verifyKeyFrame(opacity: 1.0, at: 500000);
      await verifyKeyFrame(opacity: 0.75, at: 537500);
      await verifyKeyFrame(opacity: 0.5, at: 575000);
      await verifyKeyFrame(opacity: 0.25, at: 612500);
      await verifyKeyFrame(opacity: 0.0, at: 650000);
      await verifyKeyFrame(opacity: 0.0, at: 850000);
      await verifyKeyFrame(opacity: 0.25, at: 887500);
      await verifyKeyFrame(opacity: 0.5, at: 925000);
      await verifyKeyFrame(opacity: 0.75, at: 962500);
      await verifyKeyFrame(opacity: 1.0, at: 1000000);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
  );

  testWidgets(
    'Cursor does not animate on non-iOS platforms',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Material(child: TextField(maxLines: 3))));

      await tester.tap(find.byType(TextField));
      await tester.pump();
      // Wait for the current animation to finish. If the cursor never stops its
      // blinking animation the test will timeout.
      await tester.pumpAndSettle();

      for (var i = 0; i < 40; i += 1) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.hasRunningAnimations, false);
      }
    },
    variant: TargetPlatformVariant.all(excluding: <TargetPlatform>{TargetPlatform.iOS}),
  );

  testWidgets('Cursor does not animate on Android', (WidgetTester tester) async {
    final defaultCursorColor = Color(ThemeData.fallback().colorScheme.primary.value);
    final Widget widget = MaterialApp(
      home: Material(child: TextField(maxLines: 3, cursorColor: defaultCursorColor)),
    );
    await tester.pumpWidget(widget);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;

    await tester.pump();
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: defaultCursorColor));

    // Android cursor goes from exactly on to exactly off on the 500ms dot.
    await tester.pump(const Duration(milliseconds: 499));
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: defaultCursorColor));

    await tester.pump(const Duration(milliseconds: 1));
    expect(renderEditable.cursorColor!.alpha, 0);
    // Don't try to draw the cursor.
    expect(renderEditable, paintsExactlyCountTimes(#drawRect, 0));

    await tester.pump(const Duration(milliseconds: 500));
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: defaultCursorColor));

    await tester.pump(const Duration(milliseconds: 500));
    expect(renderEditable.cursorColor!.alpha, 0);
    expect(renderEditable, paintsExactlyCountTimes(#drawRect, 0));
  });

  testWidgets(
    'Cursor radius is 2.0 on Apple platforms',
    (WidgetTester tester) async {
      const Widget widget = MaterialApp(home: Material(child: TextField(maxLines: 3)));
      await tester.pumpWidget(widget);

      final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
      final RenderEditable renderEditable = editableTextState.renderEditable;

      expect(renderEditable.cursorRadius, const Radius.circular(2.0));
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    }),
  );
}
