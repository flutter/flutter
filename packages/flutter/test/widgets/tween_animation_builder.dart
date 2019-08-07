// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Animates forward when built', (WidgetTester tester) async {
    final List<int> values = <int>[];
    final List<AnimationStatus> statuses = <AnimationStatus>[];
    await tester.pumpWidget(
      TweenAnimationBuilder<int>(
        duration: const Duration(seconds: 1),
        tween: IntTween(begin: 10, end: 110),
        builder: (BuildContext context, int i, Widget child) {
          values.add(i);
          return const Placeholder();
        },
        animationStatusListener: (AnimationStatus status) {
          statuses.add(status);
        },
      ),
    );
    expect(statuses, <AnimationStatus>[AnimationStatus.forward]);
    expect(values, <int>[10]);

    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[10, 60]);

    await tester.pump(const Duration(milliseconds: 501));
    expect(statuses, <AnimationStatus>[AnimationStatus.forward, AnimationStatus.completed]);
    expect(values, <int>[10, 60, 110]);

    await tester.pump(const Duration(milliseconds: 500));
    expect(statuses, <AnimationStatus>[AnimationStatus.forward, AnimationStatus.completed]);
    expect(values, <int>[10, 60, 110]);
  });

  testWidgets('Animates backwards when built', (WidgetTester tester) async {
    final List<int> values = <int>[];
    final List<AnimationStatus> statuses = <AnimationStatus>[];
    await tester.pumpWidget(
      TweenAnimationBuilder<int>(
        duration: const Duration(seconds: 1),
        direction: PlaybackDirection.reverse,
        tween: IntTween(begin: 10, end: 110),
        builder: (BuildContext context, int i, Widget child) {
          values.add(i);
          return const Placeholder();
        },
        animationStatusListener: (AnimationStatus status) {
          statuses.add(status);
        },
      ),
    );
    expect(statuses, <AnimationStatus>[AnimationStatus.completed, AnimationStatus.reverse]);
    expect(values, <int>[110]);

    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[110, 60]);

    await tester.pump(const Duration(milliseconds: 501));
    expect(statuses, <AnimationStatus>[AnimationStatus.completed, AnimationStatus.reverse, AnimationStatus.dismissed]);
    expect(values, <int>[110, 60, 10]);

    await tester.pump(const Duration(milliseconds: 500));
    expect(statuses, <AnimationStatus>[AnimationStatus.completed, AnimationStatus.reverse, AnimationStatus.dismissed]);
    expect(values, <int>[110, 60, 10]);
  });

  testWidgets('Repeats animation', (WidgetTester tester) async {
    final List<int> values = <int>[];
    final List<AnimationStatus> statuses = <AnimationStatus>[];
    await tester.pumpWidget(
      TweenAnimationBuilder<int>(
        duration: const Duration(seconds: 1),
        direction: PlaybackDirection.repeat,
        tween: IntTween(begin: 10, end: 110),
        builder: (BuildContext context, int i, Widget child) {
          values.add(i);
          return const Placeholder();
        },
        animationStatusListener: (AnimationStatus status) {
          statuses.add(status);
        },
      ),
    );
    expect(statuses, <AnimationStatus>[AnimationStatus.forward]);
    expect(values, <int>[10]);

    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[10, 60]);

    await tester.pump(const Duration(milliseconds: 499));
    expect(values, <int>[10, 60, 110]);

    await tester.pump(const Duration(milliseconds: 1));
    expect(values, <int>[10, 60, 110, 10]);

    await tester.pump(const Duration(milliseconds: 500));
    expect(statuses, <AnimationStatus>[AnimationStatus.forward]);
    expect(values, <int>[10, 60, 110, 10, 60]);
  });

  testWidgets('Repeats animation reversed', (WidgetTester tester) async {
    final List<int> values = <int>[];
    final List<AnimationStatus> statuses = <AnimationStatus>[];
    await tester.pumpWidget(
      TweenAnimationBuilder<int>(
        duration: const Duration(seconds: 1),
        direction: PlaybackDirection.repeatReverse,
        tween: IntTween(begin: 10, end: 110),
        builder: (BuildContext context, int i, Widget child) {
          values.add(i);
          return const Placeholder();
        },
        animationStatusListener: (AnimationStatus status) {
          statuses.add(status);
        },
      ),
    );
    expect(statuses, <AnimationStatus>[AnimationStatus.forward]);
    expect(values, <int>[10]);

    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[10, 60]);

    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[10, 60, 110]);

    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[10, 60, 110, 60]);

    await tester.pump(const Duration(milliseconds: 500));
    expect(statuses, <AnimationStatus>[AnimationStatus.forward]);
    expect(values, <int>[10, 60, 110, 60, 10]);
  });

  testWidgets('Replace tween animates new tween', (WidgetTester tester) async {
    final List<int> values = <int>[];
    Widget buildWidget({IntTween tween}) {
      return TweenAnimationBuilder<int>(
        duration: const Duration(seconds: 1),
        tween: tween,
        builder: (BuildContext context, int i, Widget child) {
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
    Widget buildWidget({IntTween tween, Curve curve}) {
      return TweenAnimationBuilder<int>(
        duration: const Duration(seconds: 1),
        tween: tween,
        curve: curve,
        builder: (BuildContext context, int i, Widget child) {
          values.add(i);
          return const Placeholder();
        },
      );
    }

    await tester.pumpWidget(buildWidget(tween: IntTween(begin: 0, end: 100), curve: Curves.easeInExpo));
    expect(values, <int>[0]);
    await tester.pump(const Duration(milliseconds: 500));
    expect(values.last, lessThan(50));
    expect(values.last, greaterThan(0));

    await tester.pump(const Duration(seconds: 2)); // finish animation.

    values.clear();
    // Update curve (and tween to re-trigger animation).
    await tester.pumpWidget(buildWidget(tween: IntTween(begin: 100, end: 200), curve: Curves.linear));
    expect(values, <int>[100]);
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[100, 150]);
  });

  testWidgets('Duration is respected', (WidgetTester tester) async {
    final List<int> values = <int>[];
    Widget buildWidget({IntTween tween, Duration duration}) {
      return TweenAnimationBuilder<int>(
        tween: tween,
        duration: duration,
        builder: (BuildContext context, int i, Widget child) {
          values.add(i);
          return const Placeholder();
        },
      );
    }

    await tester.pumpWidget(buildWidget(tween: IntTween(begin: 0, end: 100), duration: const Duration(seconds: 1)));
    expect(values, <int>[0]);
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[0, 50]);

    await tester.pump(const Duration(seconds: 2)); // finish animation.

    values.clear();
    // Update duration (and tween to re-trigger animation).
    await tester.pumpWidget(buildWidget(tween: IntTween(begin: 100, end: 200), duration: const Duration(seconds: 2)));
    expect(values, <int>[100]);
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[100, 125]);
  });

  testWidgets('Direction changes trigger animation', (WidgetTester tester) async {
    final List<int> values = <int>[];
    Widget buildWidget({PlaybackDirection direction}) {
      return TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: 100),
        direction: direction,
        duration: const Duration(seconds: 1),
        builder: (BuildContext context, int i, Widget child) {
          values.add(i);
          return const Placeholder();
        },
      );
    }

    await tester.pumpWidget(buildWidget(direction: PlaybackDirection.forward));
    await tester.pump(const Duration(seconds: 2)); // finish animation.
    expect(values, <int>[0, 100]);

    values.clear();
    // Update duration (and tween to re-trigger animation).
    await tester.pumpWidget(buildWidget(direction: PlaybackDirection.reverse));
    await tester.pump(const Duration(seconds: 2)); // finish animation.
    expect(values, <int>[100, 0]);
  });

  testWidgets('animationStatusListener can be changed', (WidgetTester tester) async {
    Widget buildWidget({PlaybackDirection direction, AnimationStatusListener listener}) {
      return TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: 100),
        direction: direction,
        duration: const Duration(seconds: 1),
        animationStatusListener: listener,
        builder: (BuildContext context, int i, Widget child) {
          return const Placeholder();
        },
      );
    }

    final List<AnimationStatus> listener1 = <AnimationStatus>[];
    final List<AnimationStatus> listener2 = <AnimationStatus>[];
    await tester.pumpWidget(buildWidget(direction: PlaybackDirection.forward, listener: (AnimationStatus s) {
      listener1.add(s);
    }));
    await tester.pump(const Duration(seconds: 2)); // finish animation.
    expect(listener1, <AnimationStatus>[AnimationStatus.forward, AnimationStatus.completed]);
    expect(listener2, isEmpty);

    listener1.clear();
    await tester.pumpWidget(buildWidget(direction: PlaybackDirection.reverse, listener: (AnimationStatus s) {
      listener2.add(s);
    }));
    await tester.pump(const Duration(seconds: 2)); // finish animation.
    expect(listener1, isEmpty);
    expect(listener2, <AnimationStatus>[AnimationStatus.reverse, AnimationStatus.dismissed]);
  });

  testWidgets('Child is integrated into tree', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: 100),
          duration: const Duration(seconds: 1),
          builder: (BuildContext context, int i, Widget child) {
            return child;
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
      Widget buildWidget({IntTween tween, PlaybackDirection direction}) {
        return TweenAnimationBuilder<int>(
          tween: tween,
          direction: direction ?? PlaybackDirection.forward,
          duration: const Duration(seconds: 1),
          builder: (BuildContext context, int i, Widget child) {
            values.add(i);
            return const Placeholder();
          },
        );
      }

      await tester.pumpWidget(buildWidget(
        tween: IntTween(begin: 0, end: 100),
      ));
      expect(values, <int>[0]);
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[0, 50]);

      // Change tween
      await tester.pumpWidget(buildWidget(
        tween: IntTween(begin: 200, end: 300),
      ));
      expect(values, <int>[0, 50, 50]); // gapless: animation continues where it left off.

      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[0, 50, 50, 175]); // 175 = halfway between 50 and new target 300.

      // Run animation to end
      await tester.pump(const Duration(seconds: 2));
      expect(values, <int>[0, 50, 50, 175, 300]);
      values.clear();

      // Run animation back to beginning
      await tester.pumpWidget(buildWidget(
        tween: IntTween(begin: 200, end: 300),
        direction: PlaybackDirection.reverse,
      ));
      expect(values, <int>[300]);
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[300, 250]);
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[300, 250, 200]);
    });

    testWidgets('running forward and then reverse with same tween instance', (WidgetTester tester) async {
      final List<int> values = <int>[];
      Widget buildWidget({IntTween tween, PlaybackDirection direction}) {
        return TweenAnimationBuilder<int>(
          tween: tween,
          direction: direction ?? PlaybackDirection.forward,
          duration: const Duration(seconds: 1),
          builder: (BuildContext context, int i, Widget child) {
            values.add(i);
            return const Placeholder();
          },
        );
      }

      final IntTween tween1 = IntTween(begin: 0, end: 100);
      final IntTween tween2 = IntTween(begin: 200, end: 300);

      await tester.pumpWidget(buildWidget(
        tween: tween1,
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(buildWidget(
        tween: tween2,
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));
      expect(values, <int>[0, 50, 50, 175, 300]);
      values.clear();

      // Run animation back to beginning
      await tester.pumpWidget(buildWidget(
        tween: tween2,
        direction: PlaybackDirection.reverse,
      ));
      expect(values, <int>[300]);
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[300, 250]);
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[300, 250, 200]);
    });

    testWidgets('running reverse', (WidgetTester tester) async {
      final List<int> values = <int>[];
      Widget buildWidget({IntTween tween, PlaybackDirection direction}) {
        return TweenAnimationBuilder<int>(
          tween: tween,
          direction: direction ?? PlaybackDirection.reverse,
          duration: const Duration(seconds: 1),
          builder: (BuildContext context, int i, Widget child) {
            values.add(i);
            return const Placeholder();
          },
        );
      }

      await tester.pumpWidget(buildWidget(
        tween: IntTween(begin: 0, end: 100),
      ));
      expect(values, <int>[100]);
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[100, 50]);

      // Change tween
      await tester.pumpWidget(buildWidget(
        tween: IntTween(begin: 200, end: 300),
      ));
      expect(values, <int>[100, 50, 50]); // gapless: animation continues where it left off.

      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[100, 50, 50, 125]); // 175 = halfway between 50 and new target 200.

      // Run animation to end
      await tester.pump(const Duration(seconds: 2));
      expect(values, <int>[100, 50, 50, 125, 200]);
      values.clear();

      // Run animation forward to end
      await tester.pumpWidget(buildWidget(
        tween: IntTween(begin: 200, end: 300),
        direction: PlaybackDirection.forward,
      ));
      expect(values, <int>[200]);
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[200, 250]);
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[200, 250, 300]);
    });

    testWidgets('running reverse and then forward with same tween instance', (WidgetTester tester) async {
      final List<int> values = <int>[];
      Widget buildWidget({IntTween tween, PlaybackDirection direction}) {
        return TweenAnimationBuilder<int>(
          tween: tween,
          direction: direction ?? PlaybackDirection.reverse,
          duration: const Duration(seconds: 1),
          builder: (BuildContext context, int i, Widget child) {
            values.add(i);
            return const Placeholder();
          },
        );
      }

      final IntTween tween1 = IntTween(begin: 0, end: 100);
      final IntTween tween2 = IntTween(begin: 200, end: 300);

      await tester.pumpWidget(buildWidget(
        tween: tween1,
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(buildWidget(
        tween: tween2,
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));
      expect(values, <int>[100, 50, 50, 125, 200]);
      values.clear();

      // Run animation back to beginning
      await tester.pumpWidget(buildWidget(
        tween: tween2,
        direction: PlaybackDirection.forward,
      ));
      expect(values, <int>[200]);
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[200, 250]);
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[200, 250, 300]);
    });

    testWidgets('running repeat', (WidgetTester tester) async {
      final List<int> values = <int>[];
      Widget buildWidget({IntTween tween}) {
        return TweenAnimationBuilder<int>(
          tween: tween,
          direction: PlaybackDirection.repeat,
          duration: const Duration(seconds: 1),
          builder: (BuildContext context, int i, Widget child) {
            values.add(i);
            return const Placeholder();
          },
        );
      }

      await tester.pumpWidget(buildWidget(
        tween: IntTween(begin: 0, end: 100),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 499));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 999));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[0, 50, 100, 0, 100, 0, 50]);
      values.clear();

      // Change tween
      await tester.pumpWidget(buildWidget(
        tween: IntTween(begin: 200, end: 300),
      ));
      expect(values, <int>[50]); // gapless: animation continues where it left off.
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[50, 175]); // 175 = halfway between 50 and new target 200.
      await tester.pump(const Duration(milliseconds: 499));
      expect(values, <int>[50, 175, 300]);
      values.clear();

      await tester.pump(const Duration(milliseconds: 1));
      expect(values, <int>[200]);
      await tester.pump(const Duration(milliseconds: 999));
      expect(values, <int>[200, 300]);
    });

    testWidgets('running repeatReverse (replaced while runnign forward)', (WidgetTester tester) async {
      final List<int> values = <int>[];
      Widget buildWidget({IntTween tween}) {
        return TweenAnimationBuilder<int>(
          tween: tween,
          direction: PlaybackDirection.repeatReverse,
          duration: const Duration(seconds: 1),
          builder: (BuildContext context, int i, Widget child) {
            values.add(i);
            return const Placeholder();
          },
        );
      }

      await tester.pumpWidget(buildWidget(
        tween: IntTween(begin: 0, end: 100),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[0, 50, 100, 50, 0, 50]);
      values.clear();

      // Change tween
      await tester.pumpWidget(buildWidget(
        tween: IntTween(begin: 200, end: 300),
      ));
      expect(values, <int>[50]); // gapless: animation continues where it left off.
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[50, 175]); // 175 = halfway between 50 and new target 200.
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[50, 175, 300]);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[50, 175, 300, 250, 200]);
    });

    testWidgets('running repeatReverse (replaced while runnign reverse)', (WidgetTester tester) async {
      final List<int> values = <int>[];
      Widget buildWidget({IntTween tween}) {
        return TweenAnimationBuilder<int>(
          tween: tween,
          direction: PlaybackDirection.repeatReverse,
          duration: const Duration(seconds: 1),
          builder: (BuildContext context, int i, Widget child) {
            values.add(i);
            return const Placeholder();
          },
          animationStatusListener: (AnimationStatus s) {
            print(s);
          },
        );
      }

      await tester.pumpWidget(buildWidget(
        tween: IntTween(begin: 0, end: 100),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[0, 50, 100, 50]);
      values.clear();

      // Change tween
      await tester.pumpWidget(buildWidget(
        tween: IntTween(begin: 200, end: 300),
      ));
      expect(values, <int>[50]); // gapless: animation continues where it left off.
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[50, 175]); // 125 = halfway between 50 and new target 300.
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[50, 175, 300]);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(values, <int>[50, 175, 300, 250, 200]);
    });
  });

  testWidgets('Changing direction while gapless tween change is in progress', (WidgetTester tester) async {
    final List<int> values = <int>[];
    Widget buildWidget({IntTween tween, PlaybackDirection direction}) {
      return TweenAnimationBuilder<int>(
        tween: tween,
        direction: direction,
        duration: const Duration(seconds: 1),
        builder: (BuildContext context, int i, Widget child) {
          values.add(i);
          return const Placeholder();
        },
      );
    }

    final IntTween tween1 = IntTween(begin: 0, end: 100);
    final IntTween tween2 = IntTween(begin: 200, end: 300);

    await tester.pumpWidget(buildWidget(
      tween: tween1,
      direction: PlaybackDirection.forward,
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[0, 50]);
    values.clear();

    // Change tween
    await tester.pumpWidget(buildWidget(
      tween: tween2,
      direction: PlaybackDirection.forward,
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[50, 175]);
    values.clear();

    await tester.pumpWidget(buildWidget(
      tween: tween2,
      direction: PlaybackDirection.reverse,
    ));
    await tester.pump(const Duration(seconds: 2));
    expect(values, <int>[175, 200]);
  });

  testWidgets('Changing direction while gapless tween change is in progress (reverse)', (WidgetTester tester) async {
    final List<int> values = <int>[];
    Widget buildWidget({IntTween tween, PlaybackDirection direction}) {
      return TweenAnimationBuilder<int>(
        tween: tween,
        direction: direction,
        duration: const Duration(seconds: 1),
        builder: (BuildContext context, int i, Widget child) {
          values.add(i);
          return const Placeholder();
        },
      );
    }

    final IntTween tween1 = IntTween(begin: 0, end: 100);
    final IntTween tween2 = IntTween(begin: 200, end: 300);

    await tester.pumpWidget(buildWidget(
      tween: tween1,
      direction: PlaybackDirection.reverse,
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[100, 50]);
    values.clear();

    // Change tween
    await tester.pumpWidget(buildWidget(
      tween: tween2,
      direction: PlaybackDirection.reverse,
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[50, 125]);
    values.clear();

    await tester.pumpWidget(buildWidget(
      tween: tween2,
      direction: PlaybackDirection.forward,
    ));
    await tester.pump(const Duration(seconds: 2));
    expect(values, <int>[125, 300]);
  });

  testWidgets('Changing curve while no animation is running does not trigger animation', (WidgetTester tester) async {
    final List<int> values = <int>[];
    Widget buildWidget({Curve curve}) {
      return TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: 100),
        curve: curve,
        duration: const Duration(seconds: 1),
        builder: (BuildContext context, int i, Widget child) {
          values.add(i);
          return const Placeholder();
        },
      );
    }

    await tester.pumpWidget(buildWidget(
      curve: Curves.linear,
    ));
    await tester.pump(const Duration(seconds: 2));
    expect(values, <int>[0, 100]);
    values.clear();

    await tester.pumpWidget(buildWidget(
      curve: Curves.easeInExpo,
    ));
    expect(values, <int>[100]);
    await tester.pump(const Duration(seconds: 2));
    expect(values, <int>[100]);
  });

  testWidgets('Changed curve while animating gaplessly is respected', (WidgetTester tester) async {
    final List<int> values = <int>[];
    Widget buildWidget({Curve curve}) {
      return TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: 100),
        curve: curve,
        duration: const Duration(seconds: 1),
        builder: (BuildContext context, int i, Widget child) {
          values.add(i);
          return const Placeholder();
        },
      );
    }

    await tester.pumpWidget(buildWidget(
      curve: Curves.linear,
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, <int>[0, 50]);
    values.clear();

    await tester.pumpWidget(buildWidget(
      curve: Curves.easeInExpo,
    ));
    expect(values, <int>[50]);
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, hasLength(2));
    expect(values.last, greaterThan(50));
    expect(values.last, lessThan(75));
    await tester.pump(const Duration(milliseconds: 500));
    expect(values, hasLength(3));
    expect(values.last, 100);
  });
}
