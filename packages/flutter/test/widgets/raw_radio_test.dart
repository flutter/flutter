// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  testWidgets('RawRadio control test', (WidgetTester tester) async {
    final FocusNode node = FocusNode();
    addTearDown(node.dispose);
    int? actualValue;
    ToggleableStateMixin? actualState;

    Widget buildWidget() {
      return RawRadio<int>(
        value: 0,
        groupValue: actualValue,
        onChanged: (int? value) {
          actualValue = value;
        },
        mouseCursor: WidgetStateProperty.all<MouseCursor>(SystemMouseCursors.click),
        toggleable: true,
        focusNode: node,
        autofocus: false,
        builder: (BuildContext context, ToggleableStateMixin state) {
          actualState = state;
          return CustomPaint(size: const Size(40, 40), painter: TestPainter());
        },
      );
    }

    await tester.pumpWidget(buildWidget());
    expect(actualState!.tristate, isTrue);
    expect(actualState!.value, isFalse);

    await tester.tap(find.byType(RawRadio<int>));
    // Rebuilds with new group value
    await tester.pumpWidget(buildWidget());

    expect(actualValue, 0);
    expect(actualState!.value, isTrue);
  });

  testWidgets('Radio can be selected with space and enter keys', (WidgetTester tester) async {
    int? groupValue = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: [
              TextField(),
              Radio<int>(
                value: 1,
                groupValue: groupValue,
                onChanged: (int? value) {
                  groupValue = value;
                },
              ),
            ],
          ),
        ),
      ),
    );

    // Focus the TextField first, then tab to the Radio.
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    // Now the Radio should be focused. Press space.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(groupValue, 1);

    // Reset and try with enter key.
    groupValue = 0;
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(groupValue, 1);
  });
}

class TestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
