// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('SliverFillRemaining - no siblings', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          controller: controller,
          slivers: <Widget>[
            SliverFillRemaining(child: Container()),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(600.0));

    controller.jumpTo(50.0);
    await tester.pump();
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(600.0));

    controller.jumpTo(-100.0);
    await tester.pump();
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(600.0));

    controller.jumpTo(0.0);
    await tester.pump();
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(600.0));
  });

  testWidgets('SliverFillRemaining - one sibling', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          controller: controller,
          slivers: <Widget>[
            const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
            SliverFillRemaining(child: Container()),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(500.0));

    controller.jumpTo(50.0);
    await tester.pump();
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(550.0));

    controller.jumpTo(-100.0);
    await tester.pump();
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(400.0)); // (!)

    controller.jumpTo(0.0);
    await tester.pump();
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(500.0));
  });

  group('SliverFillRemaining - hasScrollBody', () {
    final Widget sliverBox = SliverToBoxAdapter(
      child: Container(
        color: Colors.amber,
        height: 150.0,
      ),
    );
    Widget boilerplate(List<Widget> slivers, {ScrollController controller}) {
      return MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: slivers,
            controller: controller,
          ),
        ),
      );
    }

    testWidgets('does not extend past viewport when false', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      final List<Widget> slivers = <Widget>[
        sliverBox,
        SliverFillRemaining(
          child: Container(color: Colors.white),
          hasScrollBody: false,
        ),
      ];
      await tester.pumpWidget(boilerplate(slivers, controller: controller));
      expect(controller.offset, 0.0);
      expect(find.byType(Container), findsNWidgets(2));
      controller.jumpTo(150.0);
      await tester.pumpAndSettle();
      expect(controller.offset, 0.0);
      expect(find.byType(Container), findsNWidgets(2));
    });

    testWidgets('scrolls beyond viewport by default', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      final List<Widget> slivers = <Widget>[
              sliverBox,
              SliverFillRemaining(
                child: Container(color: Colors.white),
              ),
            ];
      await tester.pumpWidget(boilerplate(slivers, controller: controller));
      expect(controller.offset, 0.0);
      expect(find.byType(Container), findsNWidgets(2));
      controller.jumpTo(150.0);
      await tester.pumpAndSettle();
      expect(controller.offset, 150.0);
      expect(find.byType(Container), findsOneWidget);
    });

    // SliverFillRemaining considers child size when hasScrollBody: false
    testWidgets('child without size is sized by extent when false', (WidgetTester tester) async {
      final List<Widget> slivers = <Widget>[
        sliverBox,
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(color: Colors.blue),
        ),
      ];
      await tester.pumpWidget(boilerplate(slivers));
      final RenderBox box = tester.renderObject<RenderBox>(find.byType(Container).last);
      expect(box.size.height, equals(450));
    });

    testWidgets('child with size is sized by extent when false', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final List<Widget> slivers = <Widget>[
        sliverBox,
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            key: key,
            color: Colors.blue,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: RaisedButton(
                child: const Text('bottomCenter button'),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ];
      await tester.pumpWidget(boilerplate(slivers));
      expect(tester.renderObject<RenderBox>(find.byKey(key)).size.height, equals(450));

      // Also check that the button alignment is true to expectations
      final Finder button = find.byType(RaisedButton);
      expect(tester.getBottomLeft(button).dy, equals(600.0));
      expect(tester.getCenter(button).dx, equals(400.0));
    });

    testWidgets('extent is overridden by child with larger size when false', (WidgetTester tester) async {
      final List<Widget> slivers = <Widget>[
        sliverBox,
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            color: Colors.blue,
            height: 600,
          ),
        ),
      ];
      await tester.pumpWidget(boilerplate(slivers));
      final RenderBox box = tester.renderObject<RenderBox>(find.byType(Container).last);
      expect(box.size.height, equals(600));
    });

    testWidgets('extent is overridden by child size if precedingScrollExtent > viewportMainAxisExtent when false', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final List<Widget> slivers = <Widget>[
        SliverFixedExtentList(
          itemExtent: 150,
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => Container(color: Colors.amber),
            childCount: 5,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            key: key,
            color: Colors.blue[300],
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: RaisedButton(
                  child: const Text('center button'),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ];
      await tester.pumpWidget(boilerplate(slivers));
      await tester.drag(find.byType(Scrollable), const Offset(0.0, -750.0));
      await tester.pump();
      expect(tester.renderObject<RenderBox>(find.byKey(key)).size.height, equals(148.0));

      // Also check that the button alignment is true to expectations
      final Finder button = find.byType(RaisedButton);
      expect(tester.getBottomLeft(button).dy, equals(550.0));
      expect(tester.getCenter(button).dx, equals(400.0));
    });

    // iOS/Similar scroll physics when hasScrollBody: false & fillOverscroll: true behavior
    testWidgets('child without size is sized by extent and overscroll', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final List<Widget> slivers = <Widget>[
        sliverBox,
        SliverFillRemaining(
          hasScrollBody: false,
          fillOverscroll: true,
          child: Container(color: Colors.blue),
        ),
      ];
      await tester.pumpWidget(boilerplate(slivers));
      final RenderBox box1 = tester.renderObject<RenderBox>(find.byType(Container).last);
      expect(box1.size.height, equals(450));

      await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
      await tester.pump();
      final RenderBox box2 = tester.renderObject<RenderBox>(find.byType(Container).last);
      expect(box2.size.height, greaterThan(450));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('child with size is overridden and sized by extent and overscroll', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final GlobalKey key = GlobalKey();
      final List<Widget> slivers = <Widget>[
        sliverBox,
        SliverFillRemaining(
          hasScrollBody: false,
          fillOverscroll: true,
          child: Container(
            key: key,
            color: Colors.blue,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: RaisedButton(
                child: const Text('bottomCenter button'),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ];
      await tester.pumpWidget(boilerplate(slivers));
      expect(tester.renderObject<RenderBox>(find.byKey(key)).size.height, equals(450));

      await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
      await tester.pump();
      expect(tester.renderObject<RenderBox>(find.byKey(key)).size.height, greaterThan(450));

      // Also check that the button alignment is true to expectations, even with
      // child stretching to fill overscroll
      final Finder button = find.byType(RaisedButton);
      expect(tester.getBottomLeft(button).dy, equals(600.0));
      expect(tester.getCenter(button).dx, equals(400.0));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('extent is overridden by child size and overscroll if precedingScrollExtent > viewportMainAxisExtent', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final GlobalKey key = GlobalKey();
      final ScrollController controller = ScrollController();
      final List<Widget> slivers = <Widget>[
        SliverFixedExtentList(
          itemExtent: 150,
          delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) => Container(color: Colors.amber),
            childCount: 5,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          fillOverscroll: true,
          child: Container(
            key: key,
            color: Colors.blue[300],
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: RaisedButton(
                  child: const Text('center button'),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ];
      await tester.pumpWidget(boilerplate(slivers, controller: controller));
      // Scroll to the end
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      expect(tester.renderObject<RenderBox>(find.byKey(key)).size.height, equals(148.0));
      // Check that the button alignment is true to expectations
      final Finder button = find.byType(RaisedButton);
      expect(tester.getBottomLeft(button).dy, equals(550.0));
      expect(tester.getCenter(button).dx, equals(400.0));
      debugDefaultTargetPlatformOverride = null;

      // Drag for overscroll
      await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
      await tester.pump();
      expect(tester.renderObject<RenderBox>(find.byKey(key)).size.height, greaterThan(148.0));

      // Check that the button alignment is still centered in stretched child
      expect(tester.getBottomLeft(button).dy, lessThan(550.0));
      expect(tester.getCenter(button).dx, equals(400.0));
      debugDefaultTargetPlatformOverride = null;
    });

    // Android/Other scroll physics when hasScrollBody: false, ignores fillOverscroll: true
    testWidgets('child without size is sized by extent, fillOverscroll is ignored', (WidgetTester tester) async {
      final List<Widget> slivers = <Widget>[
        sliverBox,
        SliverFillRemaining(
          hasScrollBody: false,
          fillOverscroll: true,
          child: Container(color: Colors.blue),
        ),
      ];
      await tester.pumpWidget(boilerplate(slivers));
      final RenderBox box1 = tester.renderObject<RenderBox>(find.byType(Container).last);
      expect(box1.size.height, equals(450));

      await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
      await tester.pump();
      final RenderBox box2 = tester.renderObject<RenderBox>(find.byType(Container).last);
      expect(box2.size.height, equals(450));
    });

    testWidgets('child with size is overridden and sized by extent, fillOverscroll is ignored', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final List<Widget> slivers = <Widget>[
        sliverBox,
        SliverFillRemaining(
          hasScrollBody: false,
          fillOverscroll: true,
          child: Container(
            key: key,
            color: Colors.blue,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: RaisedButton(
                child: const Text('bottomCenter button'),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ];
      await tester.pumpWidget(boilerplate(slivers));
      expect(tester.renderObject<RenderBox>(find.byKey(key)).size.height, equals(450));

      await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
      await tester.pump();
      expect(tester.renderObject<RenderBox>(find.byKey(key)).size.height, equals(450));

      // Also check that the button alignment is true to expectations
      final Finder button = find.byType(RaisedButton);
      expect(tester.getBottomLeft(button).dy, equals(600.0));
      expect(tester.getCenter(button).dx, equals(400.0));
    });

    testWidgets('extent is overridden by child size if precedingScrollExtent > viewportMainAxisExtent, fillOverscroll is ignored', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final ScrollController controller = ScrollController();
      final List<Widget> slivers = <Widget>[
        SliverFixedExtentList(
          itemExtent: 150,
          delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) => Container(color: Colors.amber),
            childCount: 5,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          fillOverscroll: true,
          child: Container(
            key: key,
            color: Colors.blue[300],
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: RaisedButton(
                  child: const Text('center button'),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ];
      await tester.pumpWidget(boilerplate(slivers, controller: controller));
      // Scroll to the end
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      expect(tester.renderObject<RenderBox>(find.byKey(key)).size.height, equals(148.0));
      // Check that the button alignment is true to expectations
      final Finder button = find.byType(RaisedButton);
      expect(tester.getBottomLeft(button).dy, equals(550.0));
      expect(tester.getCenter(button).dx, equals(400.0));
      debugDefaultTargetPlatformOverride = null;

      await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
      await tester.pump();
      expect(tester.renderObject<RenderBox>(find.byKey(key)).size.height, equals(148.0));

      // Check that the button alignment is still centered in stretched child
      expect(tester.getBottomLeft(button).dy, equals(550.0));
      expect(tester.getCenter(button).dx, equals(400.0));
    });
  });
}
