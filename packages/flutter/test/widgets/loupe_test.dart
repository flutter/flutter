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

  Future<BuildContext> contextTrap(WidgetTester tester,
      {Widget Function(Widget child)? wrapper}) async {
    late BuildContext outerContext;

    Widget identity(Widget child) {
      return child;
    }

    await tester.pumpWidget(
        (wrapper ?? identity)(Builder(builder: (BuildContext context) {
      outerContext = context;
      return Container();
    })));

    return outerContext;
  }

  Widget wrapWithApp({required Widget child}) {
    return MaterialApp(
        home: Scaffold(
      body: Builder(builder: (BuildContext context) => child),
    ));
  }

  group('Raw Loupe', () {
    testWidgets('should render with correct focal point and decoration',
        (WidgetTester tester) async {
      final Key appKey = UniqueKey();
      const Size loupeSize = Size(100, 100);
      const Offset loupeFocalPoint = Offset(50, 50);
      const Offset loupePosition = Offset(200, 200);
      const double magnificationScale = 2;

      await tester.pumpWidget(wrapWithApp(
          child: Container(
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
              child: RawLoupe(
                controller: LoupeController(),
                size: loupeSize,
                focalPoint: loupeFocalPoint,
                magnificationScale: magnificationScale,
                decoration:
                    const LoupeDecoration(opacity: 0.75, shadows: <BoxShadow>[
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
          'should auto respond to transition messages when no animation controller',
          (WidgetTester tester) async {
        await runFakeAsync((FakeAsync async) async {
          final RawLoupe testLoupe = RawLoupe(
            controller: loupeController,
            size: const Size(100, 100),
          );

          final BuildContext context = await contextTrap(tester,
              wrapper: (Widget child) => wrapWithApp(child: child));

          loupeController.show(
            context: context,
            builder: (BuildContext context) => testLoupe,
          );

          WidgetsBinding.instance.scheduleFrame();
          await tester.pump();

          expect(loupeController.status.value, AnimationStatus.completed);

          loupeController.hide();
          WidgetsBinding.instance.scheduleFrame();
          await tester.pump();

          expect(loupeController.status.value, AnimationStatus.dismissed);
        });
      });

      testWidgets(
          'should only signal complete when animation controller complete',
          (WidgetTester tester) async {
        await runFakeAsync((FakeAsync async) async {
          final RawLoupe testLoupe = RawLoupe(
            controller: loupeController,
            transitionAnimationController: animationController,
            size: const Size(100, 100),
          );

          final BuildContext context = await contextTrap(tester,
              wrapper: (Widget child) => wrapWithApp(child: child));

          loupeController.show(
            context: context,
            builder: (BuildContext context) => testLoupe,
          );

          WidgetsBinding.instance.scheduleFrame();
          await tester.pump();

          // No time has passed, so the animation controller has not completed.
          expect(loupeController.status.value, AnimationStatus.forward);

          async.elapse(animationController.duration!);
          await tester.pumpAndSettle();

          expect(loupeController.status.value, AnimationStatus.completed);

          loupeController.hide();

          WidgetsBinding.instance.scheduleFrame();
          await tester.pump();

          expect(loupeController.status.value, AnimationStatus.reverse);

          async.elapse(animationController.duration!);
          await tester.pumpAndSettle();

          expect(loupeController.status.value, AnimationStatus.dismissed);
        });
      });
    });
  });

  group('loupe controller', () {
    final LoupeController loupeController = LoupeController();

    tearDown(() {
      loupeController.overlayEntry?.remove();
      loupeController.status.value = AnimationStatus.dismissed;
      loupeController.overlayEntry = null;
    });

    group('show', () {
      testWidgets('should insert below below widget',
          (WidgetTester tester) async {
        final BuildContext context = await contextTrap(tester,
            wrapper: (Widget child) => wrapWithApp(child: child));

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

          final RawLoupe testLoupe = RawLoupe(
            controller: loupeController,
            transitionAnimationController: animationController,
            size: const Size(100, 100),
          );

          final BuildContext context = await contextTrap(tester,
              wrapper: (Widget child) => wrapWithApp(child: child));

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

    group('signalShow', () {
      testWidgets('Should do nothing if loupe already shown',
          (WidgetTester tester) async {
        await runFakeAsync((FakeAsync async) async {
          final _MockAnimationController animationController =
              _MockAnimationController();

          final RawLoupe testLoupe = RawLoupe(
            controller: loupeController,
            transitionAnimationController: animationController,
            size: const Size(100, 100),
          );

          final BuildContext context = await contextTrap(tester,
              wrapper: (Widget child) => wrapWithApp(child: child));

          loupeController.show(
            context: context,
            builder: (BuildContext context) => testLoupe,
          );

          WidgetsBinding.instance.scheduleFrame();
          await tester.pump();

          async.elapse(animationController.duration!);
          await tester.pumpAndSettle();

          loupeController.signalShow();
          WidgetsBinding.instance.scheduleFrame();
          await tester.pump();

          expect(animationController.forwardCalls, 1,
              reason: 'should have only called forward for the inital show');
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
