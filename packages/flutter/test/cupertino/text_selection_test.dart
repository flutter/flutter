// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

void main() {
  group('canSelectAll', () {
    Widget createEditableText({
      Key key,
      String text,
      TextSelection selection,
    }) {
      final TextEditingController controller = TextEditingController(text: text)
        ..selection = selection ?? const TextSelection.collapsed(offset: -1);
      return CupertinoApp(
        home: EditableText(
          key: key,
          controller: controller,
          focusNode: FocusNode(),
          style: const TextStyle(),
          cursorColor: const Color.fromARGB(0, 0, 0, 0),
          backgroundCursorColor: const Color.fromARGB(0, 0, 0, 0),
        ),
      );
    }

    testWidgets('should return false when there is no text', (WidgetTester tester) async {
      final GlobalKey<EditableTextState> key = GlobalKey();
      await tester.pumpWidget(createEditableText(key: key));
      expect(cupertinoTextSelectionControls.canSelectAll(key.currentState), false);
    });

    testWidgets('should return true when there is text and collapsed selection', (WidgetTester tester) async {
      final GlobalKey<EditableTextState> key = GlobalKey();
      await tester.pumpWidget(createEditableText(
        key: key,
        text: '123',
      ));
      expect(cupertinoTextSelectionControls.canSelectAll(key.currentState), true);
    });

    testWidgets('should return false when there is text and partial uncollapsed selection', (WidgetTester tester) async {
      final GlobalKey<EditableTextState> key = GlobalKey();
      await tester.pumpWidget(createEditableText(
        key: key,
        text: '123',
        selection: const TextSelection(baseOffset: 1, extentOffset: 2),
      ));
      expect(cupertinoTextSelectionControls.canSelectAll(key.currentState), false);
    });

    testWidgets('should return false when there is text and full selection', (WidgetTester tester) async {
      final GlobalKey<EditableTextState> key = GlobalKey();
      await tester.pumpWidget(createEditableText(
        key: key,
        text: '123',
        selection: const TextSelection(baseOffset: 0, extentOffset: 3),
      ));
      expect(cupertinoTextSelectionControls.canSelectAll(key.currentState), false);
    });
  });
}
