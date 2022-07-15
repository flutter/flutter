// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockAnimationController extends AnimationController {
  _MockAnimationController()
      : super(duration: const Duration(minutes: 1), vsync: const TestVSync());
  int forwardCalls = 0;
  int reverseCalls = 0;

  @override
  TickerFuture forward({double? from}) {
    forwardCalls++;
    return super.forward(from: from);
  }

  @override
  TickerFuture reverse({double? from}) {
    reverseCalls++;
    return super.reverse(from: from);
  }
}

void main() {
  Future<T> runFakeAsync<T>(Future<T> Function(FakeAsync time) f) async {
    return FakeAsync().run((FakeAsync time) async {
      bool pump = true;
      final Future<T> future = f(time).whenComplete(() => pump = false);
      while (pump) {
        time.flushMicrotasks();
      }
      return future;
    });
  }

  group('Raw Loupe', () {
    testWidgets('should render with correct focal point and decoration',
        (WidgetTester tester) async {
      final Key appKey = UniqueKey();
      const Size loupeSize = Size(100, 100);
      const Offset loupeFocalPoint = Offset(50, 50);
      const Offset loupePosition = Offset(200, 200);
      const double magnificationScale = 2;

      await tester.pumpWidget(MaterialApp(
          home: Container(
        key: appKey,
        color: Colors.orange,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: <Widget>[
            Positioned(
              // Positioned so that it is right in the center of the loupe
              // focal point.
              left: loupePosition.dx - loupeFocalPoint.dx,
              top: loupePosition.dy - loupeFocalPoint.dy,
              child: Container(
                color: Colors.pink,
                // Since it is the size of the loupe but over it's
                // magnificationScale, it should take up the whole loupe
                width: (loupeSize.width * 1.5) / magnificationScale,
                height: (loupeSize.height * 1.5) / magnificationScale,
              ),
            ),
            Positioned(
              left: loupePosition.dx,
              top: loupePosition.dy,
              child: const RawLoupe(
                size: loupeSize,
                focalPoint: loupeFocalPoint,
                magnificationScale: magnificationScale,
                decoration:
                     LoupeDecoration(opacity: 0.75, shadows: <BoxShadow>[
                  BoxShadow(
                      spreadRadius: 10,
                      blurRadius: 10,
                      color: Colors.green,
                      offset: Offset(5, 5))
                ]),
              ),
            ),
          ],
        ),
      )));

      await tester.pumpAndSettle();

      // Should look like an orange screen, with two pink boxes.
      // One pink box is in the loupe (so has a green shadow) and is double
      // size (from magnification). Also, the loupe should be slightly orange
      // since it has opacity.
      await expectLater(
        find.byKey(appKey),
        matchesGoldenFile('widgets.loupe.styled.png'),
      );
    });

    group('transition states', () {
      final AnimationController animationController = AnimationController(
          vsync: const TestVSync(), duration: const Duration(minutes: 2));
      final LoupeController loupeController = LoupeController();

      tearDown(() {
        animationController.value = 0;
        loupeController.hide();

        if (loupeController.overlayEntry != null) {
          loupeController.overlayEntry!.remove();
          loupeController.overlayEntry = null;
        }
      });

      testWidgets(
          'should immediately remove from overlay on no animation controller',
          (WidgetTester tester) async {
        await runFakeAsync((FakeAsync async) async {
          const RawLoupe testLoupe = RawLoupe(
            size: Size(100, 100),
          );

          await tester.pumpWidget(const MaterialApp(
            home: Placeholder(),
          ));

          final BuildContext context =
              tester.firstElement(find.byType(Placeholder));

          loupeController.show(
            context: context,
            builder: (BuildContext context) => testLoupe,
          );

          WidgetsBinding.instance.scheduleFrame();
          await tester.pump();

          expect(loupeController.overlayEntry, isNot(isNull));

          loupeController.hide();
          WidgetsBinding.instance.scheduleFrame();
          await tester.pump();

          expect(loupeController.overlayEntry, isNull);
        });
      });

      testWidgets(
          'should update shown based on animation status',
          (WidgetTester tester) async {
        await runFakeAsync((FakeAsync async) async {
          const RawLoupe testLoupe = RawLoupe(


            size: Size(100, 100),
          );

          await tester.pumpWidget(const MaterialApp(
            home: Placeholder(),
          ));

          final BuildContext context =
              tester.firstElement(find.byType(Placeholder));

          loupeController.show(
            context: context,
            builder: (BuildContext context) => testLoupe,
          );

          WidgetsBinding.instance.scheduleFrame();
          await tester.pump();

          // No time has passed, so the animation controller has not completed.
          expect(loupeController.animationController?.status, AnimationStatus.forward);
          expect(loupeController.shown, true);

          async.elapse(animationController.duration!);
          await tester.pumpAndSettle();

          expect(loupeController.animationController?.status, AnimationStatus.completed);
          expect(loupeController.shown, true);

          loupeController.hide();

          WidgetsBinding.instance.scheduleFrame();
          await tester.pump();

          expect(loupeController.animationController?.status, AnimationStatus.reverse);
          expect(loupeController.shown, true);

          async.elapse(animationController.duration!);
          await tester.pumpAndSettle();

          expect(loupeController.animationController?.status, AnimationStatus.dismissed);
          expect(loupeController.shown, false);
        });
      });
    });
  });

  group('loupe controller', () {
    final LoupeController loupeController = LoupeController();

    tearDown(() {
      loupeController.overlayEntry?.remove();
      loupeController.animationController = null;
      loupeController.overlayEntry = null;
    });

    group('show', () {
      testWidgets('should insert below below widget',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(
          home: Text('text'),
        ));

        final BuildContext context =
            tester.firstElement(find.byType(Text));

        final Widget fakeLoupe = Placeholder(key: UniqueKey());
        final Widget fakeBefore = Placeholder(key: UniqueKey());

        final OverlayEntry fakeBeforeOverlayEntry =
            OverlayEntry(builder: (_) => fakeBefore);

        Overlay.of(context)!.insert(fakeBeforeOverlayEntry);
        loupeController.show(
            context: context,
            builder: (_) => fakeLoupe,
            below: fakeBeforeOverlayEntry);

        WidgetsBinding.instance.scheduleFrame();
        await tester.pumpAndSettle();

        final Iterable<Element> allOverlayChildren = find
            .descendant(
                of: find.byType(Overlay), matching: find.byType(Placeholder))
            .evaluate();

        // Expect the loupe to be the first child, even though it was inserted
        // after the fakeBefore.
        expect(allOverlayChildren.last.widget.key, fakeBefore.key);
        expect(allOverlayChildren.first.widget.key, fakeLoupe.key);
      });

      testWidgets('should re-insert without animating if loupe already shown',
          (WidgetTester tester) async {
        await runFakeAsync((FakeAsync async) async {
          final _MockAnimationController animationController =
              _MockAnimationController();

          const  RawLoupe testLoupe = RawLoupe(


            size: Size(100, 100),
          );

          await tester.pumpWidget(const MaterialApp(
            home: Placeholder(),
          ));

          final BuildContext context =
              tester.firstElement(find.byType(Placeholder));

          loupeController.show(
            context: context,
            builder: (BuildContext context) => testLoupe,
          );

          WidgetsBinding.instance.scheduleFrame();
          await tester.pump();

          async.elapse(animationController.duration!);
          await tester.pumpAndSettle();

          loupeController.show(context: context, builder: (_) => testLoupe);

          WidgetsBinding.instance.scheduleFrame();
          await tester.pump();

          expect(animationController.reverseCalls, 0,
              reason:
                  'should not have called reverse on animation controller due to force remove');
        });
      });
    });

    group('shift within bounds', () {
      final List<Rect> boundsRects = <Rect>[
        const Rect.fromLTRB(0, 0, 100, 100),
        const Rect.fromLTRB(0, 0, 100, 100),
        const Rect.fromLTRB(0, 0, 100, 100),
        const Rect.fromLTRB(0, 0, 100, 100),
      ];
      final List<Rect> inputRects = <Rect>[
        const Rect.fromLTRB(-100, -100, -80, -80),
        const Rect.fromLTRB(0, 0, 20, 20),
        const Rect.fromLTRB(110, 0, 120, 10),
        const Rect.fromLTRB(110, 110, 120, 120)
      ];
      final List<Rect> outputRects = <Rect>[
        const Rect.fromLTRB(0, 0, 20, 20),
        const Rect.fromLTRB(0, 0, 20, 20),
        const Rect.fromLTRB(90, 0, 100, 10),
        const Rect.fromLTRB(90, 90, 100, 100)
      ];

      for (int i = 0; i < boundsRects.length; i++) {
        test(
            'should shift ${inputRects[i]} to ${outputRects[i]} for bounds ${boundsRects[i]}',
            () {
          final Rect outputRect = LoupeController.shiftWithinBounds(
              bounds: boundsRects[i], rect: inputRects[i]);
          expect(outputRect, outputRects[i]);
        });
      }
    });
  });
}
