// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late IntegerChangeNotifier changeNotifier;
  late Widget textBuilderUnderTest;

  Widget builderForChangeNotifier({
    required IntegerChangeNotifier changeNotifier,
    bool Function()? listenCondition,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ChangeNotifierBuilder(
        changeNotifier: changeNotifier,
        listenCondition: listenCondition,
        builder: (BuildContext context, Widget? child) {
          if (changeNotifier.value == 0)
            return const Placeholder();
          return Text('${changeNotifier.value}');
        },
      ),
    );
  }

  setUp(() {
    changeNotifier = IntegerChangeNotifier();
    textBuilderUnderTest = builderForChangeNotifier(
      changeNotifier: changeNotifier,
    );
  });

  testWidgets('Widget builds with initial value', (WidgetTester tester) async {
    final IntegerChangeNotifier notifier = IntegerChangeNotifier(10);

    await tester.pumpWidget(builderForChangeNotifier(
      changeNotifier: notifier,
    ));

    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('Widget updates when value changes', (WidgetTester tester) async {
    await tester.pumpWidget(textBuilderUnderTest);

    changeNotifier.value = 1;
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    changeNotifier.value = 35;
    await tester.pump();
    expect(find.text('1'), findsNothing);
    expect(find.text('35'), findsOneWidget);
  });

  testWidgets('Widget does not update if condition forbids it', (WidgetTester tester) async {
    await tester.pumpWidget(builderForChangeNotifier(
      changeNotifier: changeNotifier,
      listenCondition: () => changeNotifier.value <= 10,
    ));

    changeNotifier.value = 1;
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    changeNotifier.value = 5;
    await tester.pump();
    expect(find.text('1'), findsNothing);
    expect(find.text('5'), findsOneWidget);

    // The condition is NOT satisfied do the builder is not called
    changeNotifier.value = 20;
    await tester.pump();
    expect(find.text('1'), findsNothing);
    expect(find.text('20'), findsNothing);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('Can change the notifier', (WidgetTester tester) async {
    await tester.pumpWidget(textBuilderUnderTest);

    changeNotifier.value = 1;
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    final IntegerChangeNotifier newNotifier = IntegerChangeNotifier(7);

    await tester.pumpWidget(builderForChangeNotifier(
      changeNotifier: newNotifier,
    ));

    expect(find.text('1'), findsNothing);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('Stops listening to old listenable after changing listenable', (WidgetTester tester) async {
    await tester.pumpWidget(textBuilderUnderTest);

    changeNotifier.value = 1;
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    final IntegerChangeNotifier newNotifier = IntegerChangeNotifier(7);

    await tester.pumpWidget(builderForChangeNotifier(
      changeNotifier: newNotifier,
    ));

    expect(find.text('1'), findsNothing);
    expect(find.text('7'), findsOneWidget);

    // Change value of the (now) disconnected listenable.
    changeNotifier.value = 8;
    expect(find.text('8'), findsNothing);
  });

  testWidgets('Self-cleans when removed', (WidgetTester tester) async {
    await tester.pumpWidget(textBuilderUnderTest);

    changeNotifier.value = 1;
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    await tester.pumpWidget(const Placeholder());

    expect(find.text('1'), findsNothing);
    expect(changeNotifier.hasListeners, false);
  });
}

class IntegerChangeNotifier extends ChangeNotifier {
  IntegerChangeNotifier([int value = 0]) : _value = value;

  int _value;

  int get value => _value;
  set value(int newValue) {
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
  }

  /// Override for test visibility only.
  @override
  bool get hasListeners => super.hasListeners;
}
