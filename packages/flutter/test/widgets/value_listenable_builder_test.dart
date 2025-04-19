// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SpyStringValueNotifier valueListenable;
  late Widget textBuilderUnderTest;

  Widget builderForValueListenable(ValueListenable<String?> valueListenable) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<String?>(
        valueListenable: valueListenable,
        builder: (BuildContext context, String? value, Widget? child) {
          if (value == null) {
            return const Placeholder();
          }
          return Text(value);
        },
      ),
    );
  }

  setUp(() {
    valueListenable = SpyStringValueNotifier(null);
    textBuilderUnderTest = builderForValueListenable(valueListenable);
  });

  tearDown(() {
    valueListenable.dispose();
  });

  testWidgets('Null value is ok', (WidgetTester tester) async {
    await tester.pumpWidget(textBuilderUnderTest);

    expect(find.byType(Placeholder), findsOneWidget);
  });

  testWidgets('Widget builds with initial value', (WidgetTester tester) async {
    final SpyStringValueNotifier valueListenable = SpyStringValueNotifier('Bachman');
    addTearDown(valueListenable.dispose);

    await tester.pumpWidget(builderForValueListenable(valueListenable));

    expect(find.text('Bachman'), findsOneWidget);
  });

  testWidgets('Widget updates when value changes', (WidgetTester tester) async {
    await tester.pumpWidget(textBuilderUnderTest);

    valueListenable.value = 'Gilfoyle';
    await tester.pump();
    expect(find.text('Gilfoyle'), findsOneWidget);

    valueListenable.value = 'Dinesh';
    await tester.pump();
    expect(find.text('Gilfoyle'), findsNothing);
    expect(find.text('Dinesh'), findsOneWidget);
  });

  testWidgets('Can change listenable', (WidgetTester tester) async {
    await tester.pumpWidget(textBuilderUnderTest);

    valueListenable.value = 'Gilfoyle';
    await tester.pump();
    expect(find.text('Gilfoyle'), findsOneWidget);

    final SpyStringValueNotifier differentListenable = SpyStringValueNotifier('Hendricks');
    addTearDown(differentListenable.dispose);

    await tester.pumpWidget(builderForValueListenable(differentListenable));

    expect(find.text('Gilfoyle'), findsNothing);
    expect(find.text('Hendricks'), findsOneWidget);
  });

  testWidgets('Stops listening to old listenable after changing listenable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(textBuilderUnderTest);

    valueListenable.value = 'Gilfoyle';
    await tester.pump();
    expect(find.text('Gilfoyle'), findsOneWidget);

    final SpyStringValueNotifier differentListenable = SpyStringValueNotifier('Hendricks');
    addTearDown(differentListenable.dispose);

    await tester.pumpWidget(builderForValueListenable(differentListenable));

    expect(find.text('Gilfoyle'), findsNothing);
    expect(find.text('Hendricks'), findsOneWidget);

    // Change value of the (now) disconnected listenable.
    valueListenable.value = 'Big Head';

    expect(find.text('Gilfoyle'), findsNothing);
    expect(find.text('Big Head'), findsNothing);
    expect(find.text('Hendricks'), findsOneWidget);
  });

  testWidgets('Self-cleans when removed', (WidgetTester tester) async {
    await tester.pumpWidget(textBuilderUnderTest);

    valueListenable.value = 'Gilfoyle';
    await tester.pump();
    expect(find.text('Gilfoyle'), findsOneWidget);

    await tester.pumpWidget(const Placeholder());

    expect(find.text('Gilfoyle'), findsNothing);
    expect(valueListenable.hasListeners, false);
  });

  group('rebuildOnlyOnValueChange', () {
    late ValueNotifier<int> parentNotifier;
    late ValueNotifier<int> notifier;

    setUp(() {
      parentNotifier = ValueNotifier<int>(0);
      notifier = ValueNotifier<int>(0);
    });

    tearDown(() {
      parentNotifier.dispose();
      notifier.dispose();
    });

    testWidgets('calls builder only on value changes when true', (WidgetTester tester) async {
      int buildCount = 0;

      Widget builder(BuildContext context, int value, Widget? child) {
        buildCount++;
        return Text('$value');
      }

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ValueListenableBuilder<int>(
            valueListenable: parentNotifier,
            builder: (BuildContext context, int value, Widget? child) {
              return ValueListenableBuilder<int>(
                valueListenable: notifier,
                rebuildOnlyOnValueChange: true,
                builder: builder,
              );
            }
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(buildCount, 1);

      parentNotifier.value = 1;
      await tester.pump();
      expect(find.text('0'), findsOneWidget);
      expect(buildCount, 1);

      notifier.value = 1;
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(buildCount, 2);

      parentNotifier.value = 2;
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(buildCount, 2);

    });

    testWidgets('calls builder on every build when false', (WidgetTester tester) async {
      int buildCount = 0;

      Widget builder(BuildContext context, int value, Widget? child) {
        buildCount++;
        return Text('$value');
      }

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ValueListenableBuilder<int>(
              valueListenable: parentNotifier,
              builder: (BuildContext context, int value, Widget? child) {
              return ValueListenableBuilder<int>(
                valueListenable: notifier,
                builder: builder,
              );
            }
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(buildCount, 1);

      parentNotifier.value = 3;
      await tester.pump();
      expect(find.text('0'), findsOneWidget);
      expect(buildCount, 2);

      notifier.value = 1;
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(buildCount, 3);

      parentNotifier.value = 4;
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(buildCount, 4);

    });
  });
}

class SpyStringValueNotifier extends ValueNotifier<String?> {
  SpyStringValueNotifier(super.initialValue);

  /// Override for test visibility only.
  @override
  bool get hasListeners => super.hasListeners;
}
