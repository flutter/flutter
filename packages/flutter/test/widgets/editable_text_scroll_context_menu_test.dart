// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression test for https://github.com/flutter/flutter/issues/185230.
//
// On iOS the system hides the context menu as soon as a scroll begins. That used
// to call [EditableTextState.hideToolbar], which disposed the scroll-notification
// observer, so the [ScrollEndNotification] that should bring the toolbar back was
// never received. The toolbar then never reappeared after the scroll ended.
//
// With the fix, the observer stays alive while a scroll is in progress on
// platforms that fade the toolbar on scroll, so the toolbar reappears once the
// scroll settles.
void main() {
  testWidgets(
    'iOS context menu reappears after a scroll ends',
    (WidgetTester tester) async {
      final TargetPlatform? originalPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final TextEditingController controller = TextEditingController(
        text: 'Select some text at the top of this field, then scroll down.\n' * 20,
      );
      final FocusNode focusNode = FocusNode();
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                children: <Widget>[
                  TextField(controller: controller, focusNode: focusNode, maxLines: null),
                ],
              ),
            ),
          ),
        );
        focusNode.requestFocus();
        await tester.pump();

        // Select all of the text to reveal the context menu.
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
        await tester.pump();

        final EditableTextState state = tester.state<EditableTextState>(
          find.byType(EditableText),
        );
        expect(state.showToolbar(), isTrue);
        await tester.pumpAndSettle();

        // The toolbar should be visible.
        expect(find.byType(AdaptiveTextSelectionToolbar), findsWidgets);

        // Simulate a scroll: the iOS system hides the menu as the scroll begins,
        // then the scroll ends with the selection still in view.
        await tester.fling(find.byType(ListView), const Offset(0, -100), 200);
        await tester.pumpAndSettle();

        // After the scroll ends the toolbar should reappear.
        expect(find.byType(AdaptiveTextSelectionToolbar), findsWidgets);
      } finally {
        debugDefaultTargetPlatformOverride = originalPlatform;
        focusNode.dispose();
        controller.dispose();
      }
    },
    skip: kIsWeb,
  );
}
