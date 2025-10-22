// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Animates forward when built', (WidgetTester tester) async {
    final List<int> values = <int>[];
    int endCount = 0;
    await tester.pumpWidget(
      TweenAnimationBuilder<int>(
        duration: const Duration(seconds: 1),
        tween: IntTween(begin: 10, end: 110),
        builder: (BuildContext context, int i, Widget? child) {
          values.add(i);
          return const Placeholder();
        },
        onEnd: () {
          endCount++;
        },
      ),
    );
    expect(endCount, 0);
    expect(values, <int>[10]);

    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[10, 60]);

    await tester.pump(const Duration(milliseconds: 501));
    expect(endCount, 1);
    expect(values, <int>[10, 60, 110]);

    await tester.pump(const Duration(milliseconds: 500));
    expect(endCount, 1);
    expect(values, <int>[10, 60, 110]);
  });

  testWidgets('No initial animation when begin=null', (WidgetTester tester) async {
    final List<int> values = <int>[];
    int endCount = 0;
    await tester.pumpWidget(
      TweenAnimationBuilder<int>(
        duration: const Duration(seconds: 1),
        tween: IntTween(end: 100),
        builder: (BuildContext context, int i, Widget? child) {
          values.add(i);
          return const Placeholder();
        },
        onEnd: () {
          endCount++;
        },
      ),
    );
    expect(endCount, 0);
    expect(values, <int>[100]);
    await tester.pump(const Duration(seconds: 2));
    expect(endCount, 0);
    expect(values, <int>[100]);
  });

  testWidgets('No initial animation when begin=end', (WidgetTester tester) async {
    final List<int> values = <int>[];
    int endCount = 0;
    await tester.pumpWidget(
      TweenAnimationBuilder<int>(
        duration: const Duration(seconds: 1),
        tween: IntTween(begin: 100, end: 100),
        builder: (BuildContext context, int i, Widget? child) {
          values.add(i);
          return const Placeholder();
        },
        onEnd: () {
          endCount++;
        },
      ),
    );
    expect(endCount, 0);
    expect(values, <int>[100]);
    await tester.pump(const Duration(seconds: 2));
    expect(endCount, 0);
    expect(values, <int>[100]);
  });

  testWidgets('Replace tween animates new tween', (WidgetTester tester) async {
    final List<int> values = <int>[];
    Widget buildWidget({required IntTween tween}) {
      return TweenAnimationBuilder<int>(
        duration: const Duration(seconds: 1),
        tween: tween,
        builder: (BuildContext context, int i, Widget? child) {
          values.add(i);
          return const Placeholder();
        },
      );
    }

    await tester.pumpWidget(buildWidget(tween: IntTween(begin: 0, end: 100)));
    expect(values, <int>[0]);
    await tester.pump(const Duration(seconds: 2)); // finish first animation.
    expect(values, <int>[0, 100]);

    await tester.pumpWidget(buildWidget(tween: IntTween(begin: 100, end: 200)));
    expect(values, <int>[0, 100, 100]);

    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[0, 100, 100, 150]);

    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[0, 100, 100, 150, 200]);
  });

  testWidgets('Curve is respected', (WidgetTester tester) async {
    final List<int> values = <int>[];
    Widget buildWidget({required IntTween tween, required Curve curve}) {
      return TweenAnimationBuilder<int>(
        duration: const Duration(seconds: 1),
        tween: tween,
        curve: curve,
        builder: (BuildContext context, int i, Widget? child) {
          values.add(i);
          return const Placeholder();
        },
      );
    }

    await tester.pumpWidget(
      buildWidget(tween: IntTween(begin: 0, end: 100), curve: Curves.easeInExpo),
    );
    expect(values, <int>[0]);
    await tester.pump(const Duration(milliseconds: 500));
    expect(values.last, lessThan(50));
    expect(values.last, greaterThan(0));

    await tester.pump(const Duration(seconds: 2)); // finish animation.

    values.clear();
    // Update curve (and tween to re-trigger animation).
    await tester.pumpWidget(
      buildWidget(tween: IntTween(begin: 100, end: 200), curve: Curves.linear),
    );
    expect(values, <int>[100]);
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[100, 150]);
  });

  testWidgets('Duration is respected', (WidgetTester tester) async {
    final List<int> values = <int>[];
    Widget buildWidget({required IntTween tween, required Duration duration}) {
      return TweenAnimationBuilder<int>(
        tween: tween,
        duration: duration,
        builder: (BuildContext context, int i, Widget? child) {
          values.add(i);
          return const Placeholder();
        },
      );
    }

    await tester.pumpWidget(
      buildWidget(tween: IntTween(begin: 0, end: 100), duration: const Duration(seconds: 1)),
    );
    expect(values, <int>[0]);
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[0, 50]);

    await tester.pump(const Duration(seconds: 2)); // finish animation.

    values.clear();
    // Update duration (and tween to re-trigger animation).
    await tester.pumpWidget(
      buildWidget(tween: IntTween(begin: 100, end: 200), duration: const Duration(seconds: 2)),
    );
    expect(values, <int>[100]);
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[100, 125]);
  });

  testWidgets('Child is integrated into tree', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: 100),
          duration: const Duration(seconds: 1),
          builder: (BuildContext context, int i, Widget? child) {
            return child!;
          },
          child: const Text('Hello World'),
        ),
      ),
    );

    expect(find.text('Hello World'), findsOneWidget);
  });

  group('Change tween gapless while', () {
    testWidgets('running forward', (WidgetTester tester) async {
      final List<int> values = <int>[];
      Widget buildWidget({required IntTween tween}) {
        return TweenAnimationBuilder<int>(
          tween: tween,
          duration: const Duration(seconds: 1),
          builder: (BuildContext context, int i, Widget? child) {
            values.add(i);
            return const Placeholder();
          },
        );
      }

      await tester.pumpWidget(buildWidget(tween: IntTween(begin: 0, end: 100)));
      expect(values, <int>[0]);
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[0, 50]);

      // Change tween
      await tester.pumpWidget(buildWidget(tween: IntTween(begin: 200, end: 300)));
      expect(values, <int>[0, 50, 50]); // gapless: animation continues where it left off.

      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[0, 50, 50, 175]); // 175 = halfway between 50 and new target 300.

      // Run animation to end
      await tester.pump(const Duration(seconds: 2));
      expect(values, <int>[0, 50, 50, 175, 300]);
      values.clear();
    });

    testWidgets('running forward and then reverse with same tween instance', (
      WidgetTester tester,
    ) async {
      final List<int> values = <int>[];
      Widget buildWidget({required IntTween tween}) {
        return TweenAnimationBuilder<int>(
          tween: tween,
          duration: const Duration(seconds: 1),
          builder: (BuildContext context, int i, Widget? child) {
            values.add(i);
            return const Placeholder();
          },
        );
      }

      final IntTween tween1 = IntTween(begin: 0, end: 100);
      final IntTween tween2 = IntTween(begin: 200, end: 300);

      await tester.pumpWidget(buildWidget(tween: tween1));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(buildWidget(tween: tween2));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));
      expect(values, <int>[0, 50, 50, 175, 300]);
      values.clear();
    });
  });

  testWidgets('Changing tween while gapless tween change is in progress', (
    WidgetTester tester,
  ) async {
    final List<int> values = <int>[];
    Widget buildWidget({required IntTween tween}) {
      return TweenAnimationBuilder<int>(
        tween: tween,
        duration: const Duration(seconds: 1),
        builder: (BuildContext context, int i, Widget? child) {
          values.add(i);
          return const Placeholder();
        },
      );
    }

    final IntTween tween1 = IntTween(begin: 0, end: 100);
    final IntTween tween2 = IntTween(begin: 200, end: 300);
    final IntTween tween3 = IntTween(begin: 400, end: 501);

    await tester.pumpWidget(buildWidget(tween: tween1));
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[0, 50]);
    values.clear();

    // Change tween
    await tester.pumpWidget(buildWidget(tween: tween2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[50, 175]);
    values.clear();

    await tester.pumpWidget(buildWidget(tween: tween3));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[175, 338, 501]);
  });

  testWidgets('Changing curve while no animation is running does not trigger animation', (
    WidgetTester tester,
  ) async {
    final List<int> values = <int>[];
    Widget buildWidget({required Curve curve}) {
      return TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: 100),
        curve: curve,
        duration: const Duration(seconds: 1),
        builder: (BuildContext context, int i, Widget? child) {
          values.add(i);
          return const Placeholder();
        },
      );
    }

    await tester.pumpWidget(buildWidget(curve: Curves.linear));
    await tester.pump(const Duration(seconds: 2));
    expect(values, <int>[0, 100]);
    values.clear();

    await tester.pumpWidget(buildWidget(curve: Curves.easeInExpo));
    expect(values, <int>[100]);
    await tester.pump(const Duration(seconds: 2));
    expect(values, <int>[100]);
  });

  testWidgets('Setting same tween and direction does not trigger animation', (
    WidgetTester tester,
  ) async {
    final List<int> values = <int>[];
    Widget buildWidget({required IntTween tween}) {
      return TweenAnimationBuilder<int>(
        tween: tween,
        duration: const Duration(seconds: 1),
        builder: (BuildContext context, int i, Widget? child) {
          values.add(i);
          return const Placeholder();
        },
      );
    }

    await tester.pumpWidget(buildWidget(tween: IntTween(begin: 0, end: 100)));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[0, 50, 100]);
    values.clear();

    await tester.pumpWidget(buildWidget(tween: IntTween(begin: 0, end: 100)));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, everyElement(100));
  });

  testWidgets('Setting same tween and direction while gapless animation is in progress works', (
    WidgetTester tester,
  ) async {
    final List<int> values = <int>[];
    Widget buildWidget({required IntTween tween}) {
      return TweenAnimationBuilder<int>(
        tween: tween,
        duration: const Duration(seconds: 1),
        builder: (BuildContext context, int i, Widget? child) {
          values.add(i);
          return const Placeholder();
        },
      );
    }

    await tester.pumpWidget(buildWidget(tween: IntTween(begin: 0, end: 100)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[0, 50]);
    await tester.pumpWidget(buildWidget(tween: IntTween(begin: 200, end: 300)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[0, 50, 50, 175]);

    await tester.pumpWidget(buildWidget(tween: IntTween(begin: 200, end: 300)));
    expect(values, <int>[0, 50, 50, 175, 175]);
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[0, 50, 50, 175, 175, 300]);

    values.clear();
    await tester.pump(const Duration(seconds: 2));
    expect(values, everyElement(300));
  });

  testWidgets('Works with nullable tweens', (WidgetTester tester) async {
    final List<Size?> values = <Size?>[];
    await tester.pumpWidget(
      TweenAnimationBuilder<Size?>(
        duration: const Duration(seconds: 1),
        tween: SizeTween(end: const Size(10, 10)),
        builder: (BuildContext context, Size? s, Widget? child) {
          values.add(s);
          return const Placeholder();
        },
      ),
    );
    expect(values, <Size>[const Size(10, 10)]);
    await tester.pump(const Duration(seconds: 2));
    expect(values, <Size>[const Size(10, 10)]);
  });

  group('RepeatingTweenAnimationBuilder', () {
    testWidgets('Repeats animation continuously', (WidgetTester tester) async {
      final List<double> values = <double>[];
      const Duration duration = Duration(milliseconds: 100);

      await tester.pumpWidget(
        RepeatingTweenAnimationBuilder<double>(
          duration: duration,
          tween: Tween<double>(begin: 0.0, end: 1.0),
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
      // The value should be very close to 1.0.
      expect(values.last, moreOrLessEquals(0.99));

      // Pump past the cycle boundary (1ms to complete the cycle + 50ms into the next cycle).
      await tester.pump(const Duration(milliseconds: 51));
      // The animation should have wrapped around and be at the halfway point of the next cycle.
      expect(values.last, moreOrLessEquals(0.5));
    });

    testWidgets('Reverses animation when reverse is true', (WidgetTester tester) async {
      final List<double> values = <double>[];

      await tester.pumpWidget(
        RepeatingTweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 100),
          tween: Tween<double>(begin: 0, end: 1),
          reverse: true,
          builder: (BuildContext context, double value, Widget? child) {
            values.add(value);
            return const Placeholder();
          },
        ),
      );

      // Let it run long enough to reverse.
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      // Should have both increasing and decreasing values.
      expect(values.first, 0.0);
      expect(values.any((double v) => v == 1.0), isTrue, reason: 'Should reach max');

      // Check for reversing pattern - values should decrease after reaching 1.
      bool foundReverse = false;
      for (int i = 1; i < values.length; i++) {
        if (values[i] < values[i - 1] && values[i - 1] > 0.5 && values[i] < 0.9) {
          foundReverse = true;
          break;
        }
      }
      expect(foundReverse, isTrue, reason: 'Should have reversing motion');
    });

    testWidgets('Handles pause and unpause correctly', (WidgetTester tester) async {
      final List<int> values = <int>[];
      Widget buildWidget({required bool paused}) {
        return RepeatingTweenAnimationBuilder<int>(
          duration: const Duration(seconds: 1),
          tween: IntTween(begin: 0, end: 100),
          paused: paused,
          builder: (BuildContext context, int value, Widget? child) {
            values.add(value);
            return const Placeholder();
          },
        );
      }

      // Start animated.
      await tester.pumpWidget(buildWidget(paused: false));
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[0, 50]);
      // Pause mid-animation.
      await tester.pumpWidget(buildWidget(paused: true));
      final int pausedValue = values.last;
      await tester.pump(const Duration(seconds: 2));
      expect(values.last, pausedValue); // Should stay paused.
      // Resume animation.
      await tester.pumpWidget(buildWidget(paused: false));
      await tester.pump(const Duration(milliseconds: 400));
      expect(values.last, greaterThan(pausedValue)); // Should resume from where it paused.
    });

    testWidgets('Does not animate when begin equals end', (WidgetTester tester) async {
      final List<int> values = <int>[];
      await tester.pumpWidget(
        RepeatingTweenAnimationBuilder<int>(
          duration: const Duration(seconds: 1),
          tween: IntTween(begin: 100, end: 100),
          builder: (BuildContext context, int value, Widget? child) {
            values.add(value);
            return const Placeholder();
          },
        ),
      );
      expect(values, <int>[100]);

      await tester.pump(const Duration(seconds: 2));
      expect(values, <int>[100]); // Should not repeat when there's no animation.
    });

    testWidgets('Passes child to builder correctly', (WidgetTester tester) async {
      const Widget childWidget = Text('Child');
      Widget? receivedChild;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepeatingTweenAnimationBuilder<double>(
            duration: const Duration(seconds: 1),
            tween: Tween<double>(begin: 0.0, end: 1.0),
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

    testWidgets('RepeatingTweenAnimationBuilder validates non-null begin and end values', (
      WidgetTester tester,
    ) async {
      // Test with null begin value - should throw assertion error.
      expect(
        () => RepeatingTweenAnimationBuilder<double>(
          duration: const Duration(seconds: 1),
          tween: Tween<double>(end: 1.0), // begin is null.
          builder: (BuildContext context, double value, Widget? child) {
            return const Placeholder();
          },
        ),
        throwsAssertionError,
      );

      // Test with null end value - should throw assertion error.
      expect(
        () => RepeatingTweenAnimationBuilder<double>(
          duration: const Duration(seconds: 1),
          tween: Tween<double>(begin: 0.0), // end is null.
          builder: (BuildContext context, double value, Widget? child) {
            return const Placeholder();
          },
        ),
        throwsAssertionError,
      );

      // Test with both null - should also throw assertion error
      expect(
        () => RepeatingTweenAnimationBuilder<double>(
          duration: const Duration(seconds: 1),
          tween: Tween<double>(), // Both begin and end are null.
          builder: (BuildContext context, double value, Widget? child) {
            return const Placeholder();
          },
        ),
        throwsAssertionError,
      );

      // Test with both begin and end non-null - should work fine.
      await tester.pumpWidget(
        RepeatingTweenAnimationBuilder<double>(
          duration: const Duration(seconds: 1),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (BuildContext context, double value, Widget? child) {
            return const Placeholder();
          },
        ),
      );

      // Should build without errors.
      expect(find.byType(Placeholder), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
