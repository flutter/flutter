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
  testWidgets('RadioBase control test', (WidgetTester tester) async {
    final FocusNode node = FocusNode();
    addTearDown(node.dispose);
    int? actualValue;
    ToggleableStateMixin? actualState;
    await tester.pumpWidget(
      RadioBase<int>(
        value: 0,
        groupValue: 1,
        onChanged: (int? value) {
          actualValue = value;
        },
        mouseCursor: WidgetStateProperty.all<MouseCursor>(SystemMouseCursors.click),
        toggleable: true,
        focusNode: node,
        autofocus: false,
        builder: (ToggleableStateMixin state) {
          actualState = state;
          return CustomPaint(size: const Size(40, 40), painter: TestPainter());
        },
      ),
    );
    expect(actualState!.tristate, isTrue);
    expect(actualState!.value, isFalse);

    await tester.tap(find.byType(RadioBase<int>));
    await tester.pump();

    expect(actualValue, 0);
  });
}

class TestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
