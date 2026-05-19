// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RepeatingAnimationBuilder', () {
    testWidgets('Repeats animation continuously', (WidgetTester tester) async {
      final values = <double>[];
      const duration = Duration(milliseconds: 100);

      await tester.pumpWidget(
        RepeatingAnimationBuilder<double>(
          duration: duration,
          animatable: Tween<double>(begin: 0.0, end: 1.0),
          builder: (BuildContext context, double value, Widget? child) {
            values.add(value);
            return const Placeholder();
          },
        ),
      );

      // Initial value should be 0.0.
      expect(values.last, 0.0);

      // Pump to a frame just before the end of the first cycle.
      await tester.pump(const Duration(milliseconds: 99));
      expect(values.last, moreOrLessEquals(0.99));

      // Pump past the cycle boundary (1ms to complete the cycle + 50ms into the next cycle).
      await tester.pump(const Duration(milliseconds: 51));
      expect(values.last, moreOrLessEquals(0.5));
    });

    testWidgets('Reverses animation when repeatMode is reverse', (WidgetTester tester) async {
      final values = <double>[];

      await tester.pumpWidget(
        RepeatingAnimationBuilder<double>(
          duration: const Duration(milliseconds: 100),
          animatable: Tween<double>(begin: 0, end: 1),
          repeatMode: RepeatMode.reverse,
          builder: (BuildContext context, double value, Widget? child) {
            values.add(value);
            return const Placeholder();
          },
        ),
      );

      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      expect(values.first, 0.0);
      expect(values.any((double v) => v == 1.0), isTrue, reason: 'Should reach max');

      var foundReverse = false;
      for (var i = 1; i < values.length; i++) {
        if (values[i] < values[i - 1] && values[i - 1] > 0.5 && values[i] < 0.9) {
          foundReverse = true;
          break;
        }
      }
      expect(foundReverse, isTrue, reason: 'Should have reversing motion');
    });

    testWidgets('Handles pause and unpause correctly', (WidgetTester tester) async {
      final values = <int>[];
      Widget buildWidget({required bool paused}) {
        return RepeatingAnimationBuilder<int>(
          duration: const Duration(seconds: 1),
          animatable: IntTween(begin: 0, end: 100),
          paused: paused,
          builder: (BuildContext context, int value, Widget? child) {
            values.add(value);
            return const Placeholder();
          },
        );
      }

      await tester.pumpWidget(buildWidget(paused: false));
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[0, 50]);

      await tester.pumpWidget(buildWidget(paused: true));
      final int pausedValue = values.last;
      await tester.pump(const Duration(seconds: 2));
      expect(values.last, pausedValue);

      await tester.pumpWidget(buildWidget(paused: false));
      await tester.pump(const Duration(milliseconds: 400));
      expect(values.last, greaterThan(pausedValue));
    });

    testWidgets('Animates even when begin equals end', (WidgetTester tester) async {
      final values = <int>[];
      await tester.pumpWidget(
        RepeatingAnimationBuilder<int>(
          duration: const Duration(seconds: 1),
          animatable: IntTween(begin: 100, end: 100),
          builder: (BuildContext context, int value, Widget? child) {
            values.add(value);
            return const Placeholder();
          },
        ),
      );
      expect(values.last, 100);

      await tester.pump(const Duration(milliseconds: 16));
      expect(values.length, greaterThan(1));
      expect(values.every((int value) => value == 100), isTrue);
    });

    testWidgets('Animates when endpoints match but intermediate values change', (
      WidgetTester tester,
    ) async {
      final values = <double>[];

      await tester.pumpWidget(
        RepeatingAnimationBuilder<double>(
          duration: const Duration(milliseconds: 120),
          animatable: TweenSequence<double>(<TweenSequenceItem<double>>[
            TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 1),
            TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 1),
          ]),
          builder: (BuildContext context, double value, Widget? child) {
            values.add(value);
            return const Placeholder();
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 40));
      expect(values.last, greaterThan(0.0));

      await tester.pump(const Duration(milliseconds: 40));
      expect(values.last, greaterThan(0.5));

      await tester.pump(const Duration(milliseconds: 40));
      expect(values.last, lessThan(0.6));
    });

    testWidgets('Passes child to builder correctly', (WidgetTester tester) async {
      const Widget childWidget = Text('Child');
      Widget? receivedChild;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepeatingAnimationBuilder<double>(
            duration: const Duration(seconds: 1),
            animatable: Tween<double>(begin: 0.0, end: 1.0),
            builder: (BuildContext context, double value, Widget? child) {
              receivedChild = child;
              return child ?? const Placeholder();
            },
            child: childWidget,
          ),
        ),
      );

      expect(receivedChild, childWidget);
      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('Supports animatables without explicit begin/end', (WidgetTester tester) async {
      final values = <double>[];

      await tester.pumpWidget(
        RepeatingAnimationBuilder<double>(
          duration: const Duration(milliseconds: 100),
          animatable: CurveTween(curve: Curves.easeIn),
          builder: (BuildContext context, double value, Widget? child) {
            values.add(value);
            return const Placeholder();
          },
        ),
      );

      expect(values, isNotEmpty);
      expect(values.first, 0.0);

      await tester.pump(const Duration(milliseconds: 50));
      expect(values.last, greaterThan(0.0));

      await tester.pump(const Duration(milliseconds: 49));
      expect(values.last, greaterThan(0.9));

      await tester.pump(const Duration(milliseconds: 10));
      expect(values.last, lessThan(0.2));
    });
  });
}
