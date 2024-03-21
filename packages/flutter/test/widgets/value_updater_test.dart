// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sets initial value and then value', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueUpdater<int>.once(
          initialValue: 0,
          value: 1,
          builder: (BuildContext context, int value) {
            return Text('$value');
          },
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });
  testWidgets('Sets initial value and then listens to valueNotifier', (WidgetTester tester) async {
    final ValueNotifier<int> valueNotifier = ValueNotifier<int>(1);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueUpdater<int>(
          initialValue: 0,
          valueNotifier: valueNotifier,
          builder: (BuildContext context, int value) {
            return Text('$value');
          },
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    valueNotifier.value = 2;
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    valueNotifier.value = 3;
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('Can handle switch between valueNotifier and a set value', (WidgetTester tester) async {
    final ValueNotifier<int> valueNotifier = ValueNotifier<int>(1);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueUpdater<int>(
          initialValue: 0,
          valueNotifier: valueNotifier,
          builder: (BuildContext context, int value) {
            return Text('$value');
          },
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    valueNotifier.value = 2;
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueUpdater<int>.once(
          initialValue: 1,
          value: 3,
          builder: (BuildContext context, int value) {
            return Text('$value');
          },
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);
    valueNotifier.value = 4;
    await tester.pump();
    expect(find.text('3'), findsOneWidget);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueUpdater<int>(
          initialValue: 2,
          valueNotifier: valueNotifier,
          builder: (BuildContext context, int value) {
            return Text('$value');
          },
        ),
      ),
    );
    expect(find.text('4'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('4'), findsOneWidget);
  });
}
