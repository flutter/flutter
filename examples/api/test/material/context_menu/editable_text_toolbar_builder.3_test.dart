// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/context_menu/editable_text_toolbar_builder.3.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'the TextField context menu is shown after disabling the browser context menu',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MyApp(),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);

    // The selectWordsInRange with SelectionChangedCause.tap seems to be needed to show the toolbar.
    final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));
    state.renderEditable.selectWordsInRange(
        from: Offset.zero, cause: SelectionChangedCause.tap);

    expect(state.showToolbar(), true);

    // This is needed for the AnimatedOpacity to turn from 0 to 1 so the toolbar is visible.
    await tester.pumpAndSettle();

    expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);

    // The buttons use the default buttons.
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        expect(find.byType(CupertinoTextSelectionToolbarButton),
            findsAtLeastNWidgets(1));
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        expect(find.byType(TextSelectionToolbarTextButton),
            findsAtLeastNWidgets(1));
        break;
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(find.byType(DesktopTextSelectionToolbarButton),
            findsAtLeastNWidgets(1));
        break;
      case TargetPlatform.macOS:
        expect(find.byType(CupertinoDesktopTextSelectionToolbarButton),
            findsAtLeastNWidgets(1));
        break;
    }

    // Tap to dismiss.
    await tester.tapAt(tester.getTopLeft(find.byType(EditableText)));
    await tester.pumpAndSettle();

    expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
    expect(find.byType(CupertinoTextSelectionToolbarButton), findsNothing);
    expect(find.byType(TextSelectionToolbarTextButton), findsNothing);
    expect(find.byType(DesktopTextSelectionToolbarButton), findsNothing);
    expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsNothing);
  }, skip: !kIsWeb); // [intended] This test targets the browser context menu.
}
