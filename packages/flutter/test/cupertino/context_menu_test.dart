// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  const double kOpenScale = 1.1;

  Widget getChild() {
    return Container(
      width: 300.0,
      height: 100.0,
      color: CupertinoColors.activeOrange,
    );
  }

  Widget getContextMenu({
    Alignment alignment = Alignment.center,
    Size screenSize = const Size(800.0, 600.0),
    Widget? child,
  }) {
    return CupertinoApp(
      home: CupertinoPageScaffold(
        child: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: Align(
            alignment: alignment,
            child: CupertinoContextMenu(
              actions: <CupertinoContextMenuAction>[
                CupertinoContextMenuAction(
                  child: Text('CupertinoContextMenuAction $alignment'),
                ),
              ],
              child: child ?? getChild(),
            ),
          ),
        ),
      ),
    );
  }

  // Finds the child widget that is rendered inside of _DecoyChild.
  Finder findDecoyChild(Widget child) {
    return find.descendant(
      of: find.byType(ShaderMask),
      matching: find.byWidget(child),
    );
  }

  // Finds the child widget rendered inside of _ContextMenuRouteStatic.
  Finder findStatic() {
    return find.descendant(
      of: find.byType(CupertinoApp),
      matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_ContextMenuRouteStatic'),
    );
  }

  Finder findStaticChild(Widget child) {
    return find.descendant(
      of: findStatic(),
      matching: find.byWidget(child),
    );
  }

  Finder findStaticChildDecoration(WidgetTester tester) {
    return find.descendant(
      of: findStatic(),
      matching: find.byType(DecoratedBox),
    );
  }

  group('CupertinoContextMenu before and during opening', () {
    testWidgets('An unopened CupertinoContextMenu renders child in the same place as without', (WidgetTester tester) async {
      // Measure the child in the scene with no CupertinoContextMenu.
      final Widget child = getChild();
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: child,
            ),
          ),
        ),
      );
      final Rect childRect = tester.getRect(find.byWidget(child));

      // When wrapped in a CupertinoContextMenu, the child is rendered in the same Rect.
      await tester.pumpWidget(getContextMenu(child: child));
      expect(find.byWidget(child), findsOneWidget);
      expect(tester.getRect(find.byWidget(child)), childRect);
    });

    testWidgets('Can open CupertinoContextMenu by tap and hold', (WidgetTester tester) async {
      final Widget child = getChild();
      await tester.pumpWidget(getContextMenu(child: child));
      expect(find.byWidget(child), findsOneWidget);
      final Rect childRect = tester.getRect(find.byWidget(child));
      expect(find.byType(ShaderMask), findsNothing);

      // Start a press on the child.
      final TestGesture gesture = await tester.startGesture(childRect.center);
      await tester.pump();

      // The _DecoyChild is showing directly on top of the child.
      expect(findDecoyChild(child), findsOneWidget);
      Rect decoyChildRect = tester.getRect(findDecoyChild(child));
      expect(childRect, equals(decoyChildRect));

      expect(find.byType(ShaderMask), findsOneWidget);

      // After a small delay, the _DecoyChild has begun to animate.
      await tester.pump(const Duration(milliseconds: 100));
      decoyChildRect = tester.getRect(findDecoyChild(child));
      expect(childRect, isNot(equals(decoyChildRect)));

      // Eventually the decoy fully scales by _kOpenSize.
      await tester.pump(const Duration(milliseconds: 500));
      decoyChildRect = tester.getRect(findDecoyChild(child));
      expect(childRect, isNot(equals(decoyChildRect)));
      expect(decoyChildRect.width, childRect.width * kOpenScale);

      // Then the CupertinoContextMenu opens.
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(findStatic(), findsOneWidget);
    });

    testWidgets('CupertinoContextMenu is in the correct position when within a nested navigator', (WidgetTester tester) async {
      final Widget child = getChild();
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: Align(
              alignment: Alignment.bottomRight,
              child: SizedBox(
                width: 700,
                height: 500,
                child: Navigator(
                  onGenerateRoute: (RouteSettings settings) {
                    return CupertinoPageRoute<void>(
                      builder: (BuildContext context) => Align(
                        child: CupertinoContextMenu(
                          actions: const <CupertinoContextMenuAction>[
                            CupertinoContextMenuAction(
                              child: Text('CupertinoContextMenuAction'),
                            ),
                          ],
                          child: child
                        ),
                      )
                    );
                  }
                )
              )
            )
          )
        )
      ));
      expect(find.byWidget(child), findsOneWidget);
      final Rect childRect = tester.getRect(find.byWidget(child));
      expect(find.byType(ShaderMask), findsNothing);

      // Start a press on the child.
      final TestGesture gesture = await tester.startGesture(childRect.center);
      await tester.pump();

      // The _DecoyChild is showing directly on top of the child.
      expect(findDecoyChild(child), findsOneWidget);
      Rect decoyChildRect = tester.getRect(findDecoyChild(child));
      expect(childRect, equals(decoyChildRect));

      expect(find.byType(ShaderMask), findsOneWidget);

      // After a small delay, the _DecoyChild has begun to animate.
      await tester.pump(const Duration(milliseconds: 100));
      decoyChildRect = tester.getRect(findDecoyChild(child));
      expect(childRect, isNot(equals(decoyChildRect)));

      // Eventually the decoy fully scales by _kOpenSize.
      await tester.pump(const Duration(milliseconds: 500));
      decoyChildRect = tester.getRect(findDecoyChild(child));
      expect(childRect, isNot(equals(decoyChildRect)));
      expect(decoyChildRect.width, childRect.width * kOpenScale);

      // Then the CupertinoContextMenu opens.
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(findStatic(), findsOneWidget);
    });

    testWidgets('Hovering over Cupertino context menu updates cursor to clickable on Web', (WidgetTester tester) async {
      final Widget child  = getChild();
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: CupertinoContextMenu(
              actions: const <CupertinoContextMenuAction>[
                CupertinoContextMenuAction(
                  child: Text('CupertinoContextMenuAction One'),
                ),
              ],
              child: child,
            ),
          ),
        ),
      ));

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
      await gesture.addPointer(location: const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);

      final Offset contextMenu = tester.getCenter(find.byWidget(child));
      await gesture.moveTo(contextMenu);
      await tester.pumpAndSettle();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        kIsWeb ? SystemMouseCursors.click : SystemMouseCursors.basic,
      );
    });

    testWidgets('CupertinoContextMenu is in the correct position when within a Transform.scale', (WidgetTester tester) async {
      final Widget child = getChild();
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: Transform.scale(
              scale: 0.5,
              child: Align(
                //alignment: Alignment.bottomRight,
                child: CupertinoContextMenu(
                  actions: const <CupertinoContextMenuAction>[
                    CupertinoContextMenuAction(
                      child: Text('CupertinoContextMenuAction'),
                    ),
                  ],
                  child: child
                ),
              )
            )
          )
        )
      ));
      expect(find.byWidget(child), findsOneWidget);
      final Rect childRect = tester.getRect(find.byWidget(child));
      expect(find.byType(ShaderMask), findsNothing);

      // Start a press on the child.
      final TestGesture gesture = await tester.startGesture(childRect.center);
      await tester.pump();

      // The _DecoyChild is showing directly on top of the child.
      expect(findDecoyChild(child), findsOneWidget);
      Rect decoyChildRect = tester.getRect(findDecoyChild(child));
      expect(childRect, equals(decoyChildRect));

      expect(find.byType(ShaderMask), findsOneWidget);

      // After a small delay, the _DecoyChild has begun to animate.
      await tester.pump(const Duration(milliseconds: 100));
      decoyChildRect = tester.getRect(findDecoyChild(child));
      expect(childRect, isNot(equals(decoyChildRect)));

      // Eventually the decoy fully scales by _kOpenSize.
      await tester.pump(const Duration(milliseconds: 500));
      decoyChildRect = tester.getRect(findDecoyChild(child));
      expect(childRect, isNot(equals(decoyChildRect)));
      expect(decoyChildRect.width, childRect.width * kOpenScale);

      // Then the CupertinoContextMenu opens.
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(findStatic(), findsOneWidget);
    });
  });

  group('CupertinoContextMenu when open', () {
    testWidgets('Last action does not have border', (WidgetTester tester) async {
      final Widget child  = getChild();
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: CupertinoContextMenu(
              actions: const <CupertinoContextMenuAction>[
                CupertinoContextMenuAction(
                  child: Text('CupertinoContextMenuAction One'),
                ),
              ],
              child: child,
            ),
          ),
        ),
      ));

      // Open the CupertinoContextMenu
      final TestGesture firstGesture = await tester.startGesture(tester.getCenter(find.byWidget(child)));
      await tester.pumpAndSettle();
      await firstGesture.up();
      await tester.pumpAndSettle();
      expect(findStatic(), findsOneWidget);

      expect(findStaticChildDecoration(tester), findsNWidgets(1));

      // Close the CupertinoContextMenu.
      await tester.tapAt(const Offset(1.0, 1.0));
      await tester.pumpAndSettle();
      expect(findStatic(), findsNothing);

      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: CupertinoContextMenu(
              actions: const <CupertinoContextMenuAction>[
                CupertinoContextMenuAction(
                  child: Text('CupertinoContextMenuAction One'),
                ),
                CupertinoContextMenuAction(
                  child: Text('CupertinoContextMenuAction Two'),
                ),
              ],
              child: child,
            ),
          ),
        ),
      ));

      // Open the CupertinoContextMenu
      final TestGesture secondGesture = await tester.startGesture(tester.getCenter(find.byWidget(child)));
      await tester.pumpAndSettle();
      await secondGesture.up();
      await tester.pumpAndSettle();
      expect(findStatic(), findsOneWidget);

      expect(findStaticChildDecoration(tester), findsNWidgets(3));
    });

    testWidgets('Can close CupertinoContextMenu by background tap', (WidgetTester tester) async {
      final Widget child = getChild();
      await tester.pumpWidget(getContextMenu(child: child));

      // Open the CupertinoContextMenu
      final Rect childRect = tester.getRect(find.byWidget(child));
      final TestGesture gesture = await tester.startGesture(childRect.center);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(findStatic(), findsOneWidget);

      // Tap and ensure that the CupertinoContextMenu is closed.
      await tester.tapAt(const Offset(1.0, 1.0));
      await tester.pumpAndSettle();
      expect(findStatic(), findsNothing);
    });

    testWidgets('Can close CupertinoContextMenu by dragging down', (WidgetTester tester) async {
      final Widget child = getChild();
      await tester.pumpWidget(getContextMenu(child: child));

      // Open the CupertinoContextMenu
      final Rect childRect = tester.getRect(find.byWidget(child));
      final TestGesture gesture = await tester.startGesture(childRect.center);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(findStatic(), findsOneWidget);

      // Drag down not far enough and it bounces back and doesn't close.
      expect(findStaticChild(child), findsOneWidget);
      Offset staticChildCenter = tester.getCenter(findStaticChild(child));
      TestGesture swipeGesture = await tester.startGesture(staticChildCenter);
      await swipeGesture.moveBy(
        const Offset(0.0, 100.0),
        timeStamp: const Duration(milliseconds: 100),
      );
      await tester.pump();
      await swipeGesture.up();
      await tester.pump();
      expect(tester.getCenter(findStaticChild(child)).dy, greaterThan(staticChildCenter.dy));
      await tester.pumpAndSettle();
      expect(tester.getCenter(findStaticChild(child)), equals(staticChildCenter));
      expect(findStatic(), findsOneWidget);

      // Drag down far enough and it does close.
      expect(findStaticChild(child), findsOneWidget);
      staticChildCenter = tester.getCenter(findStaticChild(child));
      swipeGesture = await tester.startGesture(staticChildCenter);
      await swipeGesture.moveBy(
        const Offset(0.0, 200.0),
        timeStamp: const Duration(milliseconds: 100),
      );
      await tester.pump();
      await swipeGesture.up();
      await tester.pumpAndSettle();
      expect(findStatic(), findsNothing);
    });

    testWidgets('Can close CupertinoContextMenu by flinging down', (WidgetTester tester) async {
      final Widget child = getChild();
      await tester.pumpWidget(getContextMenu(child: child));

      // Open the CupertinoContextMenu
      final Rect childRect = tester.getRect(find.byWidget(child));
      final TestGesture gesture = await tester.startGesture(childRect.center);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(findStatic(), findsOneWidget);

      // Fling up and nothing happens.
      expect(findStaticChild(child), findsOneWidget);
      await tester.fling(findStaticChild(child), const Offset(0.0, -100.0), 1000.0);
      await tester.pumpAndSettle();
      expect(findStaticChild(child), findsOneWidget);

      // Fling down to close the menu.
      expect(findStaticChild(child), findsOneWidget);
      await tester.fling(findStaticChild(child), const Offset(0.0, 100.0), 1000.0);
      await tester.pumpAndSettle();
      expect(findStatic(), findsNothing);
    });

    testWidgets("Backdrop is added using ModalRoute's filter parameter", (WidgetTester tester) async {
      final Widget child = getChild();
      await tester.pumpWidget(getContextMenu(child: child));
      expect(find.byType(BackdropFilter), findsNothing);

      // Open the CupertinoContextMenu
      final Rect childRect = tester.getRect(find.byWidget(child));
      final TestGesture gesture = await tester.startGesture(childRect.center);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(findStatic(), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });
  });

  group("Open layout differs depending on child's position on screen", () {
    testWidgets('Portrait', (WidgetTester tester) async {
      const Size portraitScreenSize = Size(600.0, 800.0);
      await binding.setSurfaceSize(portraitScreenSize);

      // Pump a CupertinoContextMenu in the center of the screen and open it.
      final Widget child = getChild();
      await tester.pumpWidget(getContextMenu(
        screenSize: portraitScreenSize,
        child: child,
      ));
      expect(find.byType(CupertinoContextMenuAction), findsNothing);
      Rect childRect = tester.getRect(find.byWidget(child));
      TestGesture gesture = await tester.startGesture(childRect.center);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      // The position of the action is in the center of the screen.
      expect(find.byType(CupertinoContextMenuAction), findsOneWidget);
      final Offset center = tester.getTopLeft(find.byType(CupertinoContextMenuAction));

      // Close the CupertinoContextMenu.
      await tester.tapAt(const Offset(1.0, 1.0));
      await tester.pumpAndSettle();
      expect(findStatic(), findsNothing);

      // Pump a CupertinoContextMenu on the left of the screen and open it.
      await tester.pumpWidget(getContextMenu(
        alignment: Alignment.centerLeft,
        screenSize: portraitScreenSize,
        child: child,
      ));
      expect(find.byType(CupertinoContextMenuAction), findsNothing);
      await tester.pumpAndSettle();
      childRect = tester.getRect(find.byWidget(child));
      gesture = await tester.startGesture(childRect.center);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      // The position of the action is on the left of the screen.
      expect(find.byType(CupertinoContextMenuAction), findsOneWidget);
      final Offset left = tester.getTopLeft(find.byType(CupertinoContextMenuAction));
      expect(left.dx, lessThan(center.dx));

      // Close the CupertinoContextMenu.
      await tester.tapAt(const Offset(1.0, 1.0));
      await tester.pumpAndSettle();
      expect(findStatic(), findsNothing);

      // Pump a CupertinoContextMenu on the right of the screen and open it.
      await tester.pumpWidget(getContextMenu(
        alignment: Alignment.centerRight,
        screenSize: portraitScreenSize,
        child: child,
      ));
      expect(find.byType(CupertinoContextMenuAction), findsNothing);
      childRect = tester.getRect(find.byWidget(child));
      gesture = await tester.startGesture(childRect.center);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      // The position of the action is on the right of the screen.
      expect(find.byType(CupertinoContextMenuAction), findsOneWidget);
      final Offset right = tester.getTopLeft(find.byType(CupertinoContextMenuAction));
      expect(right.dx, greaterThan(center.dx));

      // Set the screen back to its normal size.
      await binding.setSurfaceSize(const Size(800.0, 600.0));
    });

    testWidgets('Landscape', (WidgetTester tester) async {
      // Pump a CupertinoContextMenu in the center of the screen and open it.
      final Widget child = getChild();
      await tester.pumpWidget(getContextMenu(
        child: child,
      ));
      expect(find.byType(CupertinoContextMenuAction), findsNothing);
      Rect childRect = tester.getRect(find.byWidget(child));
      TestGesture gesture = await tester.startGesture(childRect.center);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      // Landscape doesn't support a centered action list, so the action is on
      // the left side of the screen.
      expect(find.byType(CupertinoContextMenuAction), findsOneWidget);
      final Offset center = tester.getTopLeft(find.byType(CupertinoContextMenuAction));

      // Close the CupertinoContextMenu.
      await tester.tapAt(const Offset(1.0, 1.0));
      await tester.pumpAndSettle();
      expect(findStatic(), findsNothing);

      // Pump a CupertinoContextMenu on the left of the screen and open it.
      await tester.pumpWidget(getContextMenu(
        alignment: Alignment.centerLeft,
        child: child,
      ));
      expect(find.byType(CupertinoContextMenuAction), findsNothing);
      childRect = tester.getRect(find.byWidget(child));
      gesture = await tester.startGesture(childRect.center);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      // The position of the action is on the right of the screen, which is the
      // same as for center aligned children in landscape.
      expect(find.byType(CupertinoContextMenuAction), findsOneWidget);
      final Offset left = tester.getTopLeft(find.byType(CupertinoContextMenuAction));
      expect(left.dx, equals(center.dx));

      // Close the CupertinoContextMenu.
      await tester.tapAt(const Offset(1.0, 1.0));
      await tester.pumpAndSettle();
      expect(findStatic(), findsNothing);

      // Pump a CupertinoContextMenu on the right of the screen and open it.
      await tester.pumpWidget(getContextMenu(
        alignment: Alignment.centerRight,
        child: child,
      ));
      expect(find.byType(CupertinoContextMenuAction), findsNothing);
      childRect = tester.getRect(find.byWidget(child));
      gesture = await tester.startGesture(childRect.center);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      // The position of the action is on the left of the screen.
      expect(find.byType(CupertinoContextMenuAction), findsOneWidget);
      final Offset right = tester.getTopLeft(find.byType(CupertinoContextMenuAction));
      expect(right.dx, lessThan(left.dx));
    });
  });
}
