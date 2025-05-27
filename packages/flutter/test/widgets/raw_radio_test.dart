// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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
}

class TestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
