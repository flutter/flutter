// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pointer scrolled floating', () {
    Widget buildTest(Widget sliver) {
      return MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            sliver,
            SliverFixedExtentList(
              itemExtent: 50.0,
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => Text('Item $index'),
                childCount: 30,
              ),
            ),
          ],
        ),
      );
    }

    void verifyGeometry({
      required GlobalKey key,
      required bool visible,
      required double paintExtent,
    }) {
      final target = key.currentContext!.findRenderObject()! as RenderSliver;
      final SliverGeometry geometry = target.geometry!;
      expect(geometry.visible, visible);
      expect(geometry.paintExtent, paintExtent);
    }

    testWidgets('SliverAppBar', (WidgetTester tester) async {
      final GlobalKey appBarKey = GlobalKey();
      await tester.pumpWidget(
        buildTest(SliverAppBar(key: appBarKey, floating: true, title: const Text('Test Title'))),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 5'), findsOneWidget);
      expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 56.0);
      verifyGeometry(key: appBarKey, visible: true, paintExtent: 56.0);

      // Pointer scroll the app bar away, we will scroll back less to validate the
      // app bar floats back in.
      final Offset point1 = tester.getCenter(find.text('Item 5'));
      final testPointer = TestPointer(1, ui.PointerDeviceKind.mouse);
      testPointer.hover(point1);
      await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, 300.0)));
      await tester.pump();
      expect(find.text('Test Title'), findsNothing);
      expect(find.text('Item 1'), findsNothing);
      expect(find.text('Item 5'), findsOneWidget);
      verifyGeometry(key: appBarKey, paintExtent: 0.0, visible: false);

      // Scroll back to float in appbar
      await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, -50.0)));
      await tester.pump();
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Item 1'), findsNothing);
      expect(find.text('Item 5'), findsOneWidget);
      expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 56.0);
      verifyGeometry(key: appBarKey, paintExtent: 50.0, visible: true);

      // Float the rest of the way in.
      await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, -250.0)));
      await tester.pump();
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 5'), findsOneWidget);
      expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 56.0);
      verifyGeometry(key: appBarKey, paintExtent: 56.0, visible: true);
    });

    testWidgets('SliverPersistentHeader', (WidgetTester tester) async {
      final GlobalKey headerKey = GlobalKey();
      await tester.pumpWidget(
        buildTest(
          SliverPersistentHeader(key: headerKey, floating: true, delegate: HeaderDelegate()),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 5'), findsOneWidget);
      verifyGeometry(key: headerKey, visible: true, paintExtent: 56.0);

      // Pointer scroll the app bar away, we will scroll back less to validate the
      // app bar floats back in.
      final Offset point1 = tester.getCenter(find.text('Item 5'));
      final testPointer = TestPointer(1, ui.PointerDeviceKind.mouse);
      testPointer.hover(point1);
      await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, 300.0)));
      await tester.pump();
      expect(find.text('Test Title'), findsNothing);
      expect(find.text('Item 1'), findsNothing);
      expect(find.text('Item 5'), findsOneWidget);
      verifyGeometry(key: headerKey, paintExtent: 0.0, visible: false);

      // Scroll back to float in appbar
      await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, -50.0)));
      await tester.pump();
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Item 1'), findsNothing);
      expect(find.text('Item 5'), findsOneWidget);
      verifyGeometry(key: headerKey, paintExtent: 50.0, visible: true);

      // Float the rest of the way in.
      await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, -250.0)));
      await tester.pump();
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 5'), findsOneWidget);
      verifyGeometry(key: headerKey, paintExtent: 56.0, visible: true);
    });

    testWidgets('and snapping SliverAppBar', (WidgetTester tester) async {
      final GlobalKey appBarKey = GlobalKey();
      await tester.pumpWidget(
        buildTest(
          SliverAppBar(key: appBarKey, floating: true, snap: true, title: const Text('Test Title')),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 5'), findsOneWidget);
      expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 56.0);
      verifyGeometry(key: appBarKey, visible: true, paintExtent: 56.0);

      // Pointer scroll the app bar away, we will scroll back less to validate the
      // app bar floats back in and then snaps to full size.
      final Offset point1 = tester.getCenter(find.text('Item 5'));
      final testPointer = TestPointer(1, ui.PointerDeviceKind.mouse);
      testPointer.hover(point1);
      await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, 300.0)));
      await tester.pump();
      expect(find.text('Test Title'), findsNothing);
      expect(find.text('Item 1'), findsNothing);
      expect(find.text('Item 5'), findsOneWidget);
      verifyGeometry(key: appBarKey, paintExtent: 0.0, visible: false);

      // Scroll back to float in appbar
      await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, -30.0)));
      await tester.pump();
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Item 1'), findsNothing);
      expect(find.text('Item 5'), findsOneWidget);
      expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 56.0);
      verifyGeometry(key: appBarKey, paintExtent: 30.0, visible: true);
      await tester.pumpAndSettle();
      // The snap animation should have completed and the app bar should be
      // fully expanded.
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Item 1'), findsNothing);
      expect(find.text('Item 5'), findsOneWidget);
      expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 56.0);
      verifyGeometry(key: appBarKey, paintExtent: 56.0, visible: true);

      // Float back out a bit and trigger snap close animation.
      await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, 50.0)));
      await tester.pump();
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Item 1'), findsNothing);
      expect(find.text('Item 5'), findsOneWidget);
      expect(tester.renderObject<RenderBox>(find.byType(AppBar)).size.height, 56.0);
      verifyGeometry(key: appBarKey, paintExtent: 6.0, visible: true);
      await tester.pumpAndSettle();
      // The snap animation should have completed and the app bar should no
      // longer be visible.
      expect(find.text('Test Title'), findsNothing);
      expect(find.text('Item 1'), findsNothing);
      expect(find.text('Item 5'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      verifyGeometry(key: appBarKey, paintExtent: 0.0, visible: false);
    });
  });
}
