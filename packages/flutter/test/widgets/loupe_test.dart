import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrapWithApp({required Widget child}) {
    return MaterialApp(
        home: Scaffold(
      body: Builder(builder: (BuildContext context) => child),
    ));
  }

  group('Raw Loupe', () {
    testWidgets('should respond to decoration', (WidgetTester tester) async {
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
      group('show', () {});
      // SHOW + HIDE should auto respond to transition messages when no controller
      // SHOW + HIDE should forward animation controller when controller
    });

    // Should show what is in the focal point
    // Should be able to magnify what is in the focal point
  });

  group('loupe controller', () {
    group('show', () {
      // should insert below when asked
      // should insert into overlay
      // if loupe is already shown, should hide without animating
    });

    group('signalShow', () {
      // should wait for animation to complete for future to complete
      // should do nothing if loupe already shown
    });

    group('hide', () {
      // should wait for animation to complete for future to complete
      // should do nothing if loupe already hidden
    });

    // SHIFT WITHIN BOUNDS JUST TEST A BUNCH
  });
}
