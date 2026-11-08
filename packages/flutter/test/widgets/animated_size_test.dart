// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestPaintingContext implements PaintingContext {
  final List<Invocation> invocations = <Invocation>[];

  @override
  void noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}

void main() {
  group('AnimatedSize', () {
    testWidgets('animates forwards then backwards with stable-sized children', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const Center(
          child: AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      );

      RenderBox box = tester.renderObject(find.byType(AnimatedSize));
      expect(box.size.width, equals(100.0));
      expect(box.size.height, equals(100.0));

      await tester.pumpWidget(
        const Center(
          child: AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: SizedBox(width: 200.0, height: 200.0),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      box = tester.renderObject(find.byType(AnimatedSize));
      expect(box.size.width, equals(150.0));
      expect(box.size.height, equals(150.0));

      var context = TestPaintingContext();
      box.paint(context, Offset.zero);
      expect(context.invocations.first.memberName, equals(#pushClipRect));

      await tester.pump(const Duration(milliseconds: 100));
      box = tester.renderObject(find.byType(AnimatedSize));
      expect(box.size.width, equals(200.0));
      expect(box.size.height, equals(200.0));

      await tester.pumpWidget(
        const Center(
          child: AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      box = tester.renderObject(find.byType(AnimatedSize));
      expect(box.size.width, equals(150.0));
      expect(box.size.height, equals(150.0));

      context = TestPaintingContext();
      box.paint(context, Offset.zero);
      expect(context.invocations.first.memberName, equals(#paintChild));

      await tester.pump(const Duration(milliseconds: 100));
      box = tester.renderObject(find.byType(AnimatedSize));
      expect(box.size.width, equals(100.0));
      expect(box.size.height, equals(100.0));
    });

    testWidgets('calls onEnd when animation is completed', (WidgetTester tester) async {
      var callCount = 0;
      void handleEnd() {
        callCount++;
      }

      await tester.pumpWidget(
        Center(
          child: AnimatedSize(
            onEnd: handleEnd,
            duration: const Duration(milliseconds: 200),
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      );

      expect(callCount, equals(0));

      await tester.pumpWidget(
        Center(
          child: AnimatedSize(
            onEnd: handleEnd,
            duration: const Duration(milliseconds: 200),
            child: const SizedBox(width: 200.0, height: 200.0),
          ),
        ),
      );

      expect(callCount, equals(0));
      await tester.pumpAndSettle();
      expect(callCount, equals(1));

      await tester.pumpWidget(
        Center(
          child: AnimatedSize(
            onEnd: handleEnd,
            duration: const Duration(milliseconds: 200),
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(callCount, equals(2));
    });

    testWidgets('clamps animated size to constraints', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Center(
          child: SizedBox.square(
            dimension: 100.0,
            child: AnimatedSize(
              duration: Duration(milliseconds: 200),
              child: SizedBox.square(dimension: 100.0),
            ),
          ),
        ),
      );

      RenderBox box = tester.renderObject(find.byType(AnimatedSize));
      expect(box.size.width, equals(100.0));
      expect(box.size.height, equals(100.0));

      // Attempt to animate beyond the outer SizedBox.
      await tester.pumpWidget(
        const Center(
          child: SizedBox.square(
            dimension: 100.0,
            child: AnimatedSize(
              duration: Duration(milliseconds: 200),
              child: SizedBox.square(dimension: 200.0),
            ),
          ),
        ),
      );

      // Verify that animated size is the same as the outer SizedBox.
      await tester.pump(const Duration(milliseconds: 100));
      box = tester.renderObject(find.byType(AnimatedSize));
      expect(box.size.width, equals(100.0));
      expect(box.size.height, equals(100.0));
    });

    testWidgets('tracks unstable child, then resumes animation when child stabilizes', (
      WidgetTester tester,
    ) async {
      Future<void> pumpMillis(int millis) async {
        await tester.pump(Duration(milliseconds: millis));
      }

      void verify({double? size, RenderAnimatedSizeState? state}) {
        assert(size != null || state != null);
        final RenderAnimatedSize box = tester.renderObject(find.byType(AnimatedSize));
        if (size != null) {
          expect(box.size.width, size);
          expect(box.size.height, size);
        }
        if (state != null) {
          expect(box.state, state);
        }
      }

      await tester.pumpWidget(
        Center(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      verify(size: 100.0, state: RenderAnimatedSizeState.stable);

      // Animate child size from 100 to 200 slowly (100ms).
      await tester.pumpWidget(
        Center(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 200.0,
              height: 200.0,
            ),
          ),
        ),
      );

      // Make sure animation proceeds at child's pace, with AnimatedSize
      // tightly tracking the child's size.
      verify(state: RenderAnimatedSizeState.stable);
      await pumpMillis(1); // register change
      verify(state: RenderAnimatedSizeState.changed);
      await pumpMillis(49);
      verify(size: 150.0, state: RenderAnimatedSizeState.unstable);
      await pumpMillis(50);
      verify(size: 200.0, state: RenderAnimatedSizeState.unstable);

      // Stabilize size
      await pumpMillis(50);
      verify(size: 200.0, state: RenderAnimatedSizeState.stable);

      // Quickly (in 1ms) change size back to 100
      await tester.pumpWidget(
        Center(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1),
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      verify(size: 200.0, state: RenderAnimatedSizeState.stable);
      await pumpMillis(1); // register change
      verify(state: RenderAnimatedSizeState.changed);
      await pumpMillis(100);
      verify(size: 150.0, state: RenderAnimatedSizeState.stable);
      await pumpMillis(100);
      verify(size: 100.0, state: RenderAnimatedSizeState.stable);
    });

    testWidgets('resyncs its animation controller', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Center(
          child: AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      );

      await tester.pumpWidget(
        const Center(
          child: AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: SizedBox(width: 200.0, height: 100.0),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final RenderBox box = tester.renderObject(find.byType(AnimatedSize));
      expect(box.size.width, equals(150.0));
    });

    testWidgets('does not run animation unnecessarily', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Center(
          child: AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      );

      for (var i = 0; i < 20; i++) {
        final RenderAnimatedSize box = tester.renderObject(find.byType(AnimatedSize));
        expect(box.size.width, 100.0);
        expect(box.size.height, 100.0);
        expect(box.state, RenderAnimatedSizeState.stable);
        expect(box.isAnimating, false);
        await tester.pump(const Duration(milliseconds: 10));
      }
    });

    testWidgets('can set and update clipBehavior', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Center(
          child: AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      );

      // By default, clipBehavior should be Clip.hardEdge
      final RenderAnimatedSize renderObject = tester.renderObject(find.byType(AnimatedSize));
      expect(renderObject.clipBehavior, equals(Clip.hardEdge));

      for (final Clip clip in Clip.values) {
        await tester.pumpWidget(
          Center(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              clipBehavior: clip,
              child: const SizedBox(width: 100.0, height: 100.0),
            ),
          ),
        );
        expect(renderObject.clipBehavior, clip);
      }
    });

    testWidgets('works wrapped in IntrinsicHeight and Wrap', (WidgetTester tester) async {
      Future<void> pumpWidget(Size size, [Duration? duration]) async {
        return tester.pumpWidget(
          Center(
            child: IntrinsicHeight(
              child: Wrap(
                textDirection: TextDirection.ltr,
                children: <Widget>[
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutBack,
                    child: SizedBox(width: size.width, height: size.height),
                  ),
                ],
              ),
            ),
          ),
          duration: duration,
        );
      }

      await pumpWidget(const Size(100, 100));
      expect(
        tester.renderObject<RenderBox>(find.byType(IntrinsicHeight)).size,
        const Size(100, 100),
      );

      await pumpWidget(const Size(150, 200));
      expect(
        tester.renderObject<RenderBox>(find.byType(IntrinsicHeight)).size,
        const Size(100, 100),
      );

      // Each pump triggers verification of dry layout.
      for (var total = 0; total < 200; total += 10) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(
        tester.renderObject<RenderBox>(find.byType(IntrinsicHeight)).size,
        const Size(150, 200),
      );

      // Change every pump
      await pumpWidget(const Size(100, 100));
      expect(
        tester.renderObject<RenderBox>(find.byType(IntrinsicHeight)).size,
        const Size(150, 200),
      );

      await pumpWidget(const Size(111, 111), const Duration(milliseconds: 10));
      expect(
        tester.renderObject<RenderBox>(find.byType(IntrinsicHeight)).size,
        const Size(111, 111),
      );

      await pumpWidget(const Size(222, 222), const Duration(milliseconds: 10));
      expect(
        tester.renderObject<RenderBox>(find.byType(IntrinsicHeight)).size,
        const Size(222, 222),
      );
    });

    testWidgets('re-attach with interrupted animation', (WidgetTester tester) async {
      const Key key1 = ValueKey<String>('key1');
      const Key key2 = ValueKey<String>('key2');
      late StateSetter setState;
      var childSize = const Size.square(100);
      final Widget animatedSize = Center(
        key: GlobalKey(debugLabel: 'animated size'),
        // This SizedBox creates a relayout boundary so _cleanRelayoutBoundary
        // does not mark the descendant render objects below the relayout boundary
        // dirty.
        child: SizedBox.fromSize(
          size: const Size.square(200),
          child: Center(
            child: AnimatedSize(
              duration: const Duration(seconds: 1),
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter stateSetter) {
                  setState = stateSetter;
                  return SizedBox.fromSize(size: childSize);
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: <Widget>[
              SizedBox(key: key1, height: 200, child: animatedSize),
              const SizedBox(key: key2, height: 200),
            ],
          ),
        ),
      );

      setState(() {
        childSize = const Size.square(150);
      });
      // Kick off the resizing animation.
      await tester.pump();

      // Immediately reparent the AnimatedSize subtree to a different parent
      // with the same incoming constraints.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: <Widget>[
              const SizedBox(key: key1, height: 200),
              SizedBox(key: key2, height: 200, child: animatedSize),
            ],
          ),
        ),
      );

      expect(
        tester.renderObject<RenderBox>(find.byType(AnimatedSize)).size,
        const Size.square(100),
      );
      await tester.pumpAndSettle();
      // The animatedSize widget animates to the right size.
      expect(
        tester.renderObject<RenderBox>(find.byType(AnimatedSize)).size,
        const Size.square(150),
      );
    });

    testWidgets('disposes animation and controller', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Center(
          child: AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      );

      final RenderAnimatedSize box = tester.renderObject(find.byType(AnimatedSize));

      await tester.pumpWidget(const Center());

      expect(box.debugAnimation, isNotNull);
      expect(box.debugAnimation!.isDisposed, isTrue);
      expect(box.debugController, isNotNull);
      expect(
        () => box.debugController!.dispose(),
        throwsA(
          isA<AssertionError>().having(
            (AssertionError error) => error.message,
            'message',
            equalsIgnoringHashCodes(
              'AnimationController.dispose() called more than once.\n'
              'A given AnimationController cannot be disposed more than once.\n'
              'The following AnimationController object was disposed multiple times:\n'
              '  AnimationController#00000(⏮ 0.000; paused; DISPOSED)',
            ),
          ),
        ),
      );
    });

    // Regression test for https://github.com/flutter/flutter/issues/71227
    testWidgets('with zero duration does not throw when the child size changes', (
      WidgetTester tester,
    ) async {
      Widget build(double size) {
        return Center(
          child: AnimatedSize(
            duration: Duration.zero,
            child: SizedBox.square(dimension: size),
          ),
        );
      }

      await tester.pumpWidget(build(100.0));
      expect(tester.getSize(find.byType(AnimatedSize)), const Size.square(100.0));

      final RenderAnimatedSize box = tester.renderObject(find.byType(AnimatedSize));
      await tester.pumpWidget(build(200.0));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AnimatedSize)), const Size.square(200.0));
      expect(box.state, RenderAnimatedSizeState.stable);

      await tester.pumpWidget(build(50.0));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AnimatedSize)), const Size.square(50.0));
      expect(box.state, RenderAnimatedSizeState.stable);
    });

    // Regression test for https://github.com/flutter/flutter/issues/71227
    testWidgets('with zero duration does not throw when re-laid out with the same child size', (
      WidgetTester tester,
    ) async {
      Widget build(double maxWidth) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: const AnimatedSize(
              duration: Duration.zero,
              child: SizedBox.square(dimension: 100.0),
            ),
          ),
        );
      }

      await tester.pumpWidget(build(300.0));
      final RenderAnimatedSize box = tester.renderObject(find.byType(AnimatedSize));
      expect(box.state, RenderAnimatedSizeState.stable);
      expect(box.debugController!.value, 0.0);

      // New constraints trigger a relayout, but the child is still 100x100, so
      // the render object resumes (and synchronously completes) the animation.
      await tester.pumpWidget(build(400.0));
      expect(tester.takeException(), isNull);
      expect(box.debugController!.value, 1.0);
      expect(tester.getSize(find.byType(AnimatedSize)), const Size.square(100.0));
    });

    testWidgets('with zero duration, dry layout matches layout when the child size changes', (
      WidgetTester tester,
    ) async {
      Widget build(double maxWidth) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: const AnimatedSize(
              duration: Duration.zero,
              child: SizedBox(width: double.infinity, height: 50.0),
            ),
          ),
        );
      }

      await tester.pumpWidget(build(100.0));
      final RenderBox box = tester.renderObject(find.byType(AnimatedSize));
      expect(box.size, const Size(100.0, 50.0));

      // With a zero duration, the size changes to the new child size at once.
      const newConstraints = BoxConstraints(maxWidth: 200.0, maxHeight: 600.0);
      expect(box.getDryLayout(newConstraints), const Size(200.0, 50.0));

      await tester.pumpWidget(build(200.0));
      expect(box.constraints, newConstraints);
      expect(box.size, const Size(200.0, 50.0));
    });

    testWidgets('animates a size change that follows a zero duration size change', (
      WidgetTester tester,
    ) async {
      var onEndCount = 0;
      Widget build(Duration duration, double size) {
        return Center(
          child: AnimatedSize(
            duration: duration,
            onEnd: () => onEndCount += 1,
            child: SizedBox.square(dimension: size),
          ),
        );
      }

      await tester.pumpWidget(build(Duration.zero, 100.0));
      await tester.pumpWidget(build(Duration.zero, 200.0));
      expect(tester.getSize(find.byType(AnimatedSize)), const Size.square(200.0));

      onEndCount = 0;
      await tester.pumpWidget(build(const Duration(milliseconds: 200), 300.0));
      expect(tester.getSize(find.byType(AnimatedSize)), const Size.square(200.0));

      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getSize(find.byType(AnimatedSize)), const Size.square(250.0));
      expect(onEndCount, 0);

      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AnimatedSize)), const Size.square(300.0));
      expect(onEndCount, 1);
    });

    testWidgets('with zero duration, calls onEnd after layout', (WidgetTester tester) async {
      var dimension = 100.0;
      final sizesAtEnd = <Size?>[];
      late StateSetter setOuterState;
      await tester.pumpWidget(
        Center(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              setOuterState = setState;
              return AnimatedSize(
                duration: Duration.zero,
                onEnd: () {
                  setState(() {});
                  sizesAtEnd.add(context.size);
                },
                child: SizedBox.square(dimension: dimension),
              );
            },
          ),
        ),
      );
      expect(sizesAtEnd, isEmpty);

      setOuterState(() => dimension = 200.0);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(sizesAtEnd, <Size>[const Size.square(200.0)]);
      expect(tester.getSize(find.byType(AnimatedSize)), const Size.square(200.0));
    });

    testWidgets('works wrapped in IntrinsicHeight and Wrap with zero duration', (
      WidgetTester tester,
    ) async {
      Widget build(Size size) {
        return Center(
          child: IntrinsicHeight(
            child: Wrap(
              textDirection: TextDirection.ltr,
              children: <Widget>[
                AnimatedSize(
                  duration: Duration.zero,
                  child: SizedBox.fromSize(size: size),
                ),
              ],
            ),
          ),
        );
      }

      await tester.pumpWidget(build(const Size(100.0, 100.0)));
      expect(tester.getSize(find.byType(IntrinsicHeight)), const Size(100.0, 100.0));

      await tester.pumpWidget(build(const Size(150.0, 200.0)));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(IntrinsicHeight)), const Size(150.0, 200.0));
    });

    for (final state in <RenderAnimatedSizeState>[
      RenderAnimatedSizeState.changed,
      RenderAnimatedSizeState.stable,
    ]) {
      testWidgets('dry layout matches layout when a stopped animation resumes with zero '
          'duration in the ${state.name} state', (WidgetTester tester) async {
        final GlobalKey key = GlobalKey();
        Widget build({required bool wrapped, required Duration duration, required double size}) {
          final Widget animatedSize = AnimatedSize(
            key: key,
            duration: duration,
            child: SizedBox.square(dimension: size),
          );
          // IntrinsicHeight reads the dry layout of AnimatedSize before
          // AnimatedSize lays out.
          return Center(
            child: wrapped
                ? IntrinsicHeight(
                    child: Wrap(textDirection: TextDirection.ltr, children: <Widget>[animatedSize]),
                  )
                : animatedSize,
          );
        }

        const duration = Duration(milliseconds: 200);
        await tester.pumpWidget(build(wrapped: false, duration: duration, size: 100.0));
        await tester.pumpWidget(build(wrapped: false, duration: duration, size: 200.0));
        if (state == RenderAnimatedSizeState.stable) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final RenderAnimatedSize box = tester.renderObject(find.byType(AnimatedSize));
        expect(box.state, state);
        expect(box.isAnimating, isTrue);

        // The move to a new parent detaches and attaches the render object,
        // which stops the animation. The next layout resumes it with a zero
        // duration.
        await tester.pumpWidget(build(wrapped: true, duration: Duration.zero, size: 200.0));
        expect(tester.renderObject(find.byType(AnimatedSize)), same(box));
        expect(tester.takeException(), isNull);
        expect(box.size, const Size.square(200.0));
        expect(tester.getSize(find.byType(IntrinsicHeight)), const Size.square(200.0));
      });
    }

    group('with zero duration, onEnd after a layout outside a frame', () {
      late int onEndCount;
      late RenderAnimatedSize box;
      late RenderConstrainedBox parent;

      Future<void> setUpTree(WidgetTester tester) async {
        onEndCount = 0;
        await tester.pumpWidget(
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(),
              child: AnimatedSize(
                duration: Duration.zero,
                onEnd: () => onEndCount += 1,
                child: const SizedBox.square(dimension: 100.0),
              ),
            ),
          ),
        );
        box = tester.renderObject(find.byType(AnimatedSize));
        parent = tester.renderObject(find.byType(ConstrainedBox));
      }

      // The layout completes the animation and waits for the next frame to
      // call onEnd.
      void layOutWithChildSize(double dimension) {
        (box.child! as RenderConstrainedBox).additionalConstraints = BoxConstraints.tight(
          Size.square(dimension),
        );
        box.owner!.flushLayout();
      }

      testWidgets('is called once for two layouts', (WidgetTester tester) async {
        await setUpTree(tester);
        layOutWithChildSize(200.0);
        layOutWithChildSize(300.0);
        expect(onEndCount, 0);
        await tester.pump();
        expect(onEndCount, 1);
      });

      testWidgets('is not called after a detach', (WidgetTester tester) async {
        await setUpTree(tester);
        layOutWithChildSize(200.0);
        await tester.pumpWidget(const SizedBox());
        expect(onEndCount, 0);
      });

      testWidgets('is not called after a layout with tight constraints', (
        WidgetTester tester,
      ) async {
        await setUpTree(tester);
        layOutWithChildSize(200.0);
        parent.additionalConstraints = BoxConstraints.tight(const Size.square(50.0));
        box.owner!.flushLayout();
        await tester.pump();
        expect(onEndCount, 0);
      });
    });
  });

  testWidgets('AnimatedSize does not crash at zero size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.shrink(
            child: AnimatedSize(duration: Duration(milliseconds: 300), child: Text('X')),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(AnimatedSize)), Size.zero);
  });
}
