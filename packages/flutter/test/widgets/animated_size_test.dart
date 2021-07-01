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
    testWidgets('animates forwards then backwards with stable-sized children', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Center(
          child: AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: SizedBox(
              width: 100.0,
              height: 100.0,
            ),
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
            child: SizedBox(
              width: 200.0,
              height: 200.0,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      box = tester.renderObject(find.byType(AnimatedSize));
      expect(box.size.width, equals(150.0));
      expect(box.size.height, equals(150.0));

      TestPaintingContext context = TestPaintingContext();
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
            child: SizedBox(
              width: 100.0,
              height: 100.0,
            ),
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

    testWidgets('clamps animated size to constraints', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Center(
          child: SizedBox (
            width: 100.0,
            height: 100.0,
            child: AnimatedSize(
              duration: Duration(milliseconds: 200),
              child: SizedBox(
                width: 100.0,
                height: 100.0,
              ),
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
          child: SizedBox (
            width: 100.0,
            height: 100.0,
            child: AnimatedSize(
              duration: Duration(milliseconds: 200),
              child: SizedBox(
                width: 200.0,
                height: 200.0,
              ),
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

    testWidgets('tracks unstable child, then resumes animation when child stabilizes', (WidgetTester tester) async {
      Future<void> pumpMillis(int millis) async {
        await tester.pump(Duration(milliseconds: millis));
      }

      void verify({ double? size, RenderAnimatedSizeState? state }) {
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
            child: SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        const Center(
          child: AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: SizedBox(
              width: 200.0,
              height: 100.0,
            ),
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
            child: SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      for (int i = 0; i < 20; i++) {
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
            child: SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      // By default, clipBehavior should be Clip.hardEdge
      final RenderAnimatedSize renderObject = tester.renderObject(find.byType(AnimatedSize));
      expect(renderObject.clipBehavior, equals(Clip.hardEdge));

      for(final Clip clip in Clip.values) {
        await tester.pumpWidget(
          Center(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              clipBehavior: clip,
              child: const SizedBox(
                width: 100.0,
                height: 100.0,
              ),
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
                    child: SizedBox(
                      width: size.width,
                      height: size.height,
                    ),
                  ),
                ],
              ),
            ),
          ),
          duration,
        );
      }

      await pumpWidget(const Size(100, 100));
      expect(tester.renderObject<RenderBox>(find.byType(IntrinsicHeight)).size, const Size(100, 100));

      await pumpWidget(const Size(150, 200));
      expect(tester.renderObject<RenderBox>(find.byType(IntrinsicHeight)).size, const Size(100, 100));

      // Each pump triggers verification of dry layout.
      for (int total = 0; total < 200; total += 10) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(tester.renderObject<RenderBox>(find.byType(IntrinsicHeight)).size, const Size(150, 200));

      // Change every pump
      await pumpWidget(const Size(100, 100));
      expect(tester.renderObject<RenderBox>(find.byType(IntrinsicHeight)).size, const Size(150, 200));

      await pumpWidget(const Size(111, 111), const Duration(milliseconds: 10));
      expect(tester.renderObject<RenderBox>(find.byType(IntrinsicHeight)).size, const Size(111, 111));

      await pumpWidget(const Size(222, 222), const Duration(milliseconds: 10));
      expect(tester.renderObject<RenderBox>(find.byType(IntrinsicHeight)).size, const Size(222, 222));
    });
  });
}
