// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'checkbox_tester.dart';

void main() {
  testWidgets('TestCheckbox renders and can be tapped', (WidgetTester tester) async {
    bool? value = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return TestCheckbox(
                value: value,
                onChanged: (bool? newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    expect(value, isFalse);
    await tester.tap(find.byType(TestCheckbox));
    await tester.pump();
    expect(value, isTrue);
    await tester.tap(find.byType(TestCheckbox));
    await tester.pump();
    expect(value, isFalse);
  });

  testWidgets('TestCheckbox disabled does not respond to taps', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: TestCheckbox(value: false, onChanged: null)),
      ),
    );

    expect(
      tester.getSemantics(find.byType(Semantics).last),
      isSemantics(isChecked: false, isEnabled: false),
    );
  });

  testWidgets('TestCheckbox provides correct semantics', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: TestCheckbox(value: true, onChanged: (bool? _) {})),
      ),
    );

    expect(
      tester.getSemantics(find.byType(Semantics).last),
      isSemantics(isChecked: true, isEnabled: true),
    );
  });

  testWidgets('TestCheckbox tristate cycles through true, null, false', (
    WidgetTester tester,
  ) async {
    bool? value = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return TestCheckbox(
                value: value,
                tristate: true,
                onChanged: (bool? newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    expect(value, isFalse);
    await tester.tap(find.byType(TestCheckbox));
    await tester.pump();
    expect(value, isTrue);
    await tester.tap(find.byType(TestCheckbox));
    await tester.pump();
    expect(value, isNull);
    await tester.tap(find.byType(TestCheckbox));
    await tester.pump();
    expect(value, isFalse);
  });

  testWidgets('TestCheckbox has correct size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: TestCheckbox(value: false, onChanged: null)),
      ),
    );

    final Size size = tester.getSize(find.byType(SizedBox).last);
    expect(size, const Size(18.0, 18.0));
  });
}
