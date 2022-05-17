// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

late GestureVelocityTrackerBuilder lastCreatedBuilder;
class TestScrollBehavior extends ScrollBehavior {
  const TestScrollBehavior(this.flag);

  final bool flag;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return flag
      ? const ClampingScrollPhysics()
      : const BouncingScrollPhysics();
  }

  @override
  bool shouldNotify(TestScrollBehavior old) => flag != old.flag;

  @override
  GestureVelocityTrackerBuilder velocityTrackerBuilder(BuildContext context) {
      lastCreatedBuilder = flag
        ? (PointerEvent ev) => VelocityTracker.withKind(ev.kind)
        : (PointerEvent ev) => IOSScrollViewFlingVelocityTracker(ev.kind);
      return lastCreatedBuilder;
  }
}

void main() {
  testWidgets('Inherited ScrollConfiguration changed', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey(debugLabel: 'scrollable');
    TestScrollBehavior? behavior;
    late ScrollPositionWithSingleContext position;

    final Widget scrollView = SingleChildScrollView(
      key: key,
      child: Builder(
        builder: (BuildContext context) {
          behavior = ScrollConfiguration.of(context) as TestScrollBehavior;
          position = Scrollable.of(context)!.position as ScrollPositionWithSingleContext;
          return Container(height: 1000.0);
        },
      ),
    );

    await tester.pumpWidget(
      ScrollConfiguration(
        behavior: const TestScrollBehavior(true),
        child: scrollView,
      ),
    );

    expect(behavior, isNotNull);
    expect(behavior!.flag, isTrue);
    expect(position.physics, isA<ClampingScrollPhysics>());
    expect(lastCreatedBuilder(const PointerDownEvent()), isA<VelocityTracker>());
    ScrollMetrics metrics = position.copyWith();
    expect(metrics.extentAfter, equals(400.0));
    expect(metrics.viewportDimension, equals(600.0));

    // Same Scrollable, different ScrollConfiguration
    await tester.pumpWidget(
      ScrollConfiguration(
        behavior: const TestScrollBehavior(false),
        child: scrollView,
      ),
    );

    expect(behavior, isNotNull);
    expect(behavior!.flag, isFalse);
    expect(position.physics, isA<BouncingScrollPhysics>());
    expect(lastCreatedBuilder(const PointerDownEvent()), isA<IOSScrollViewFlingVelocityTracker>());
    // Regression test for https://github.com/flutter/flutter/issues/5856
    metrics = position.copyWith();
    expect(metrics.extentAfter, equals(400.0));
    expect(metrics.viewportDimension, equals(600.0));
  });

  testWidgets('ScrollBehavior default android overscroll indicator', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: ScrollConfiguration(
          behavior: const ScrollBehavior(),
          child: ListView(
            children: const <Widget>[
              SizedBox(
                height: 1000.0,
                width: 1000.0,
                child: Text('Test'),
              )
            ]
          )
        ),
    ));

    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(find.byType(GlowingOverscrollIndicator), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('ScrollBehavior stretch android overscroll indicator', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800, 600)),
        child: ScrollConfiguration(
            behavior: const ScrollBehavior(androidOverscrollIndicator: AndroidOverscrollIndicator.stretch),
            child: ListView(
                children: const <Widget>[
                  SizedBox(
                    height: 1000.0,
                    width: 1000.0,
                    child: Text('Test'),
                  )
                ]
            )
        ),
      ),
    ));

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  group('ScrollBehavior configuration is maintained over multiple copies', () {
    testWidgets('dragDevices', (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/91673
      const ScrollBehavior defaultBehavior = ScrollBehavior();
      expect(defaultBehavior.dragDevices, <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      });

      // Use copyWith to modify drag devices
      final ScrollBehavior onceCopiedBehavior = defaultBehavior.copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
      );
      expect(onceCopiedBehavior.dragDevices, PointerDeviceKind.values.toSet());

      // Copy again. The previously modified drag devices should carry over.
      final ScrollBehavior twiceCopiedBehavior = onceCopiedBehavior.copyWith();
      expect(twiceCopiedBehavior.dragDevices, PointerDeviceKind.values.toSet());
    });

    testWidgets('androidOverscrollIndicator', (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/91673
      const ScrollBehavior defaultBehavior = ScrollBehavior();
      expect(defaultBehavior.androidOverscrollIndicator, AndroidOverscrollIndicator.glow);

      // Use copyWith to modify androidOverscrollIndicator
      final ScrollBehavior onceCopiedBehavior = defaultBehavior.copyWith(
        androidOverscrollIndicator: AndroidOverscrollIndicator.stretch,
      );
      expect(onceCopiedBehavior.androidOverscrollIndicator, AndroidOverscrollIndicator.stretch);

      // Copy again. The previously modified value should carry over.
      final ScrollBehavior twiceCopiedBehavior = onceCopiedBehavior.copyWith();
      expect(twiceCopiedBehavior.androidOverscrollIndicator, AndroidOverscrollIndicator.stretch);
    });

    testWidgets('physics', (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/91673
      late ScrollPhysics defaultPhysics;
      late ScrollPhysics onceCopiedPhysics;
      late ScrollPhysics twiceCopiedPhysics;

      await tester.pumpWidget(ScrollConfiguration(
        // Default ScrollBehavior
        behavior: const ScrollBehavior(),
        child: Builder(
          builder: (BuildContext context) {
            final ScrollBehavior defaultBehavior = ScrollConfiguration.of(context);
            // Copy once to change physics
            defaultPhysics = defaultBehavior.getScrollPhysics(context);
            return ScrollConfiguration(
              behavior: defaultBehavior.copyWith(physics: const BouncingScrollPhysics()),
              child: Builder(
                builder: (BuildContext context) {
                  final ScrollBehavior onceCopiedBehavior = ScrollConfiguration.of(context);
                  onceCopiedPhysics = onceCopiedBehavior.getScrollPhysics(context);
                  return ScrollConfiguration(
                    // Copy again, physics should follow
                    behavior: onceCopiedBehavior.copyWith(),
                    child: Builder(
                      builder: (BuildContext context) {
                        twiceCopiedPhysics = ScrollConfiguration.of(context).getScrollPhysics(context);
                        return SingleChildScrollView(child: Container(height: 1000));
                      }
                    )
                  );
                }
              )
            );
          }
        ),
      ));

      expect(defaultPhysics, const ClampingScrollPhysics(parent: RangeMaintainingScrollPhysics()));
      expect(onceCopiedPhysics, const BouncingScrollPhysics());
      expect(twiceCopiedPhysics, const BouncingScrollPhysics());
    });

    testWidgets('platform', (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/91673
      late TargetPlatform defaultPlatform;
      late TargetPlatform onceCopiedPlatform;
      late TargetPlatform twiceCopiedPlatform;

      await tester.pumpWidget(ScrollConfiguration(
        // Default ScrollBehavior
        behavior: const ScrollBehavior(),
        child: Builder(
            builder: (BuildContext context) {
              final ScrollBehavior defaultBehavior = ScrollConfiguration.of(context);
              // Copy once to change physics
              defaultPlatform = defaultBehavior.getPlatform(context);
              return ScrollConfiguration(
                  behavior: defaultBehavior.copyWith(platform: TargetPlatform.fuchsia),
                  child: Builder(
                      builder: (BuildContext context) {
                        final ScrollBehavior onceCopiedBehavior = ScrollConfiguration.of(context);
                        onceCopiedPlatform = onceCopiedBehavior.getPlatform(context);
                        return ScrollConfiguration(
                          // Copy again, physics should follow
                            behavior: onceCopiedBehavior.copyWith(),
                            child: Builder(
                                builder: (BuildContext context) {
                                  twiceCopiedPlatform = ScrollConfiguration.of(context).getPlatform(context);
                                  return SingleChildScrollView(child: Container(height: 1000));
                                }
                            )
                        );
                      }
                  )
              );
            }
        ),
      ));

      expect(defaultPlatform, TargetPlatform.android);
      expect(onceCopiedPlatform, TargetPlatform.fuchsia);
      expect(twiceCopiedPlatform, TargetPlatform.fuchsia);
    });

    Widget wrap(ScrollBehavior behavior) {
      return Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(500, 500)),
            child: ScrollConfiguration(
                behavior: behavior,
                child: Builder(
                    builder: (BuildContext context) => SingleChildScrollView(child: Container(height: 1000))
                )
            ),
          )
      );
    }

    testWidgets('scrollbar', (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/91673
      const  ScrollBehavior defaultBehavior = ScrollBehavior();
      await tester.pumpWidget(wrap(defaultBehavior));
      // Default adds a scrollbar
      expect(find.byType(RawScrollbar), findsOneWidget);
      final ScrollBehavior onceCopiedBehavior = defaultBehavior.copyWith(scrollbars: false);

      await tester.pumpWidget(wrap(onceCopiedBehavior));
      // Copy does not add scrollbar
      expect(find.byType(RawScrollbar), findsNothing);
      final ScrollBehavior twiceCopiedBehavior = onceCopiedBehavior.copyWith();

      await tester.pumpWidget(wrap(twiceCopiedBehavior));
      // Second copy maintains scrollbar setting
      expect(find.byType(RawScrollbar), findsNothing);

      // For default scrollbars
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('overscroll', (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/91673
      const  ScrollBehavior defaultBehavior = ScrollBehavior();
      await tester.pumpWidget(wrap(defaultBehavior));
      // Default adds a glowing overscroll indicator
      expect(find.byType(GlowingOverscrollIndicator), findsOneWidget);
      final ScrollBehavior onceCopiedBehavior = defaultBehavior.copyWith(overscroll: false);

      await tester.pumpWidget(wrap(onceCopiedBehavior));
      // Copy does not add indicator
      expect(find.byType(GlowingOverscrollIndicator), findsNothing);
      final ScrollBehavior twiceCopiedBehavior = onceCopiedBehavior.copyWith();

      await tester.pumpWidget(wrap(twiceCopiedBehavior));
      // Second copy maintains overscroll setting
      expect(find.byType(GlowingOverscrollIndicator), findsNothing);

      // For default glowing indicator
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });
}
