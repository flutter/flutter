// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

void main() {
  group('canSelectAll', () {
    Widget createEditableText({
      Key key,
      String text,
      TextSelection selection,
    }) {
      final TextEditingController controller = TextEditingController(text: text)
        ..selection = selection ?? const TextSelection.collapsed(offset: -1);
      return MaterialApp(
        home: EditableText(
          key: key,
          controller: controller,
          focusNode: FocusNode(),
          style: const TextStyle(),
          cursorColor: Colors.black,
          backgroundCursorColor: Colors.black,
        ),
      );
    }

    testWidgets('should return false when there is no text', (WidgetTester tester) async {
      final GlobalKey<EditableTextState> key = GlobalKey();
      await tester.pumpWidget(createEditableText(key: key));
      expect(materialTextSelectionControls.canSelectAll(key.currentState), false);
    });

    testWidgets('should return true when there is text and collapsed selection', (WidgetTester tester) async {
      final GlobalKey<EditableTextState> key = GlobalKey();
      await tester.pumpWidget(createEditableText(
        key: key,
        text: '123',
      ));
      expect(materialTextSelectionControls.canSelectAll(key.currentState), true);
    });

    testWidgets('should return true when there is text and partial uncollapsed selection', (WidgetTester tester) async {
      final GlobalKey<EditableTextState> key = GlobalKey();
      await tester.pumpWidget(createEditableText(
        key: key,
        text: '123',
        selection: const TextSelection(baseOffset: 1, extentOffset: 2),
      ));
      expect(materialTextSelectionControls.canSelectAll(key.currentState), true);
    });

    testWidgets('should return false when there is text and full selection', (WidgetTester tester) async {
      final GlobalKey<EditableTextState> key = GlobalKey();
      await tester.pumpWidget(createEditableText(
        key: key,
        text: '123',
        selection: const TextSelection(baseOffset: 0, extentOffset: 3),
      ));
      expect(materialTextSelectionControls.canSelectAll(key.currentState), false);
    });
  });

  group('material handles', () {
    testWidgets('draws transparent handle correctly', (WidgetTester tester) async {
      await tester.pumpWidget(RepaintBoundary(
        child: Theme(
          data: ThemeData(
            textSelectionHandleColor: const Color(0x550000AA),
          ),
          isMaterialAppTheme: true,
          child: Builder(
            builder: (BuildContext context) {
              return Container(
                color: Colors.white,
                height: 800,
                width: 800,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 250),
                  child: FittedBox(
                    child: materialTextSelectionControls.buildHandle(
                      context, TextSelectionHandleType.right, 10.0,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ));

      await expectLater(
        find.byType(RepaintBoundary),
        matchesGoldenFile('transparent_handle.png'),
      );
    });
  });
}
