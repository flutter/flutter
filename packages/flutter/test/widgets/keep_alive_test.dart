// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class Leaf extends StatefulWidget {
  const Leaf({
    Key? key,
    required this.child,
  }) : super(key: key);
  final Widget child;
  @override
  State<Leaf> createState() => _LeafState();
}

class _LeafState extends State<Leaf> {
  bool _keepAlive = false;

  void setKeepAlive(bool value) {
    setState(() { _keepAlive = value; });
  }

  @override
  Widget build(BuildContext context) {
    return KeepAlive(
      keepAlive: _keepAlive,
      child: widget.child,
    );
  }
}

List<Widget> generateList(Widget child) {
  return List<Widget>.generate(
    100,
    (int index) => Leaf(
      key: GlobalObjectKey<_LeafState>(index),
      child: child,
    ),
    growable: false,
  );
}

class _CustomPainter extends CustomPainter {
  int paintCount = 0;
  @override
  void paint(Canvas canvas, Size size) {
    paintCount += 1;
  }

  @override
  bool shouldRepaint(_CustomPainter oldDelegate) => true;
}

void main() {
  testWidgets('KeepAlive with ListView with itemExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          cacheExtent: 0.0,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          addSemanticIndexes: false,
          itemExtent: 12.3, // about 50 widgets visible
          children: generateList(const Placeholder()),
        ),
      ),
    );
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0.0, -300.0)); // about 25 widgets' worth
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState!.setKeepAlive(true);
    await tester.drag(find.byType(ListView), const Offset(0.0, 300.0)); // back to top
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState!.setKeepAlive(false);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
  });

  group('Nested ListViews with KeepAlives', () {
    final ScrollController outerScrollController = ScrollController();
    final ScrollController innerScrollController = ScrollController();
    final List<Widget> filler = List<Widget>.generate(500, (int i) => const SizedBox(height: 12.3));
    final Widget nestedListViews = Directionality(
      textDirection: TextDirection.ltr,
      child: ListView(
        controller: outerScrollController,
        cacheExtent: 0.0,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        addSemanticIndexes: false,
        children: <Widget>[
          Leaf(
            key: const GlobalObjectKey<_LeafState>('outer'),
            child: SizedBox(
              height: 800,
              child: ListView(
                controller: innerScrollController,
                cacheExtent: 0.0,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                addSemanticIndexes: false,
                itemExtent: 12.3, // about 50 widgets visible
                children: <Widget>[
                  const Leaf(key: GlobalObjectKey<_LeafState>('inner'), child: SizedBox()),
                  ...filler,
                ],
              ),
            ),
          ),
          ...filler,
        ],
      ),
    );

    testWidgets('Scroll out of viewport simultaneously', (WidgetTester tester) async {
      await tester.pumpWidget(nestedListViews);

      Future<void> setKeepAlive({ bool? innerKeepAlive, bool? outerKeepAlive }) async {
        outerScrollController.jumpTo(0);
        // Pump once to allow the inner controller to attach.
        await tester.pump();
        innerScrollController.jumpTo(0);
        await tester.pump();

        if (innerKeepAlive != null)
          const GlobalObjectKey<_LeafState>('inner').currentState!.setKeepAlive(innerKeepAlive);
        if (outerKeepAlive != null)
          const GlobalObjectKey<_LeafState>('outer').currentState!.setKeepAlive(outerKeepAlive);

        innerScrollController.jumpTo(3000);
        outerScrollController.jumpTo(3000);
        await tester.pump();
      }

      // Both have keepAlive = false.
      await setKeepAlive(innerKeepAlive: false, outerKeepAlive: false);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('outer'), skipOffstage: false), findsNothing);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('inner'), skipOffstage: false), findsNothing);

      await setKeepAlive(innerKeepAlive: true, outerKeepAlive: false);
      // Neither widget is kept alive since the outer widget isn't.
      expect(find.byKey(const GlobalObjectKey<_LeafState>('outer'), skipOffstage: false), findsNothing);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('inner'), skipOffstage: false), findsNothing);

      // Edge case: Since the outer list jumped to 3000, the inner list was
      // never laid out and thus its effective scroll offset is still 0.
      await setKeepAlive(innerKeepAlive: false, outerKeepAlive: true);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('outer'), skipOffstage: false), findsOneWidget);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('inner'), skipOffstage: false), findsOneWidget);

      await setKeepAlive(innerKeepAlive: true, outerKeepAlive: true);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('outer'), skipOffstage: false), findsOneWidget);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('inner'), skipOffstage: false), findsOneWidget);
    });

    testWidgets('Inner scrolls out of viewport, and then outer', (WidgetTester tester) async {
      await tester.pumpWidget(nestedListViews);

      Future<void> setKeepAlive({ bool? innerKeepAlive, bool? outerKeepAlive }) async {
        outerScrollController.jumpTo(0);
        // Pump once to allow the inner controller to attach.
        await tester.pump();
        innerScrollController.jumpTo(0);
        await tester.pump();

        if (innerKeepAlive != null)
          const GlobalObjectKey<_LeafState>('inner').currentState!.setKeepAlive(innerKeepAlive);
        if (outerKeepAlive != null)
          const GlobalObjectKey<_LeafState>('outer').currentState!.setKeepAlive(outerKeepAlive);

        // Scroll the inner keep alive out of the cache extent, then the outer.
        innerScrollController.jumpTo(3000);
        await tester.pump();
        outerScrollController.jumpTo(3000);
        await tester.pump();
      }

      // Both have keepAlive = false.
      await setKeepAlive(innerKeepAlive: false, outerKeepAlive: false);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('outer'), skipOffstage: false), findsNothing);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('inner'), skipOffstage: false), findsNothing);

      await setKeepAlive(innerKeepAlive: true, outerKeepAlive: false);
      // Neither widget is kept alive since the outer widget isn't.
      expect(find.byKey(const GlobalObjectKey<_LeafState>('outer'), skipOffstage: false), findsNothing);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('inner'), skipOffstage: false), findsNothing);

      await setKeepAlive(innerKeepAlive: false, outerKeepAlive: true);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('outer'), skipOffstage: false), findsOneWidget);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('inner'), skipOffstage: false), findsNothing);

      await setKeepAlive(innerKeepAlive: true, outerKeepAlive: true);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('outer'), skipOffstage: false), findsOneWidget);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('inner'), skipOffstage: false), findsOneWidget);

      // Turn KeepAlive off when a widget is currently kept alive.
      // Inner:
      await setKeepAlive(innerKeepAlive: true, outerKeepAlive: true);
      // The inner widget is kept alive. Turning keep alive should unmount it.
      const GlobalObjectKey<_LeafState>('inner').currentState!.setKeepAlive(false);
      await tester.pump();
      expect(find.byKey(const GlobalObjectKey<_LeafState>('outer'), skipOffstage: false), findsOneWidget);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('inner'), skipOffstage: false), findsNothing);

      // Outer:
      await setKeepAlive(innerKeepAlive: true, outerKeepAlive: true);
      const GlobalObjectKey<_LeafState>('outer').currentState!.setKeepAlive(false);
      await tester.pump();
      expect(find.byKey(const GlobalObjectKey<_LeafState>('outer'), skipOffstage: false), findsNothing);
      expect(find.byKey(const GlobalObjectKey<_LeafState>('inner'), skipOffstage: false), findsNothing);
    });
  });

  group('Global Key Reparenting', () {
    final ScrollController outerScrollController = ScrollController();
    final ScrollController innerScrollController = ScrollController();
    final List<Widget> filler = List<Widget>.generate(50, (int i) => const SizedBox(height: 123));
    final GlobalKey key = GlobalKey(debugLabel: 'Directionality');
    const GlobalObjectKey<_LeafState> innerKey = GlobalObjectKey<_LeafState>('inner');
    const GlobalObjectKey<_LeafState> outerKey = GlobalObjectKey<_LeafState>('outer');

    Widget buildNestedListViews({ Widget child = const SizedBox() }) {
      return Directionality(
        key: key,
        textDirection: TextDirection.ltr,
        child: ListView(
          controller: outerScrollController,
          cacheExtent: 0.0,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          addSemanticIndexes: false,
          children: <Widget>[
            Leaf(
              key: outerKey,
              child: SizedBox(
                height: 800,
                child: ListView(
                  controller: innerScrollController,
                  cacheExtent: 0.0,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  addSemanticIndexes: false,
                  itemExtent: 123,
                  children: <Widget>[
                    Leaf(key: innerKey, child: child),
                    ...filler,
                  ],
                ),
              ),
            ),
            ...filler,
          ],
        ),
      );
    }

    testWidgets('basic tests', (WidgetTester tester) async {
      await tester.pumpWidget(buildNestedListViews());

      // Keep both Leaf widgets alive.
      innerKey.currentState!.setKeepAlive(true);
      outerKey.currentState!.setKeepAlive(true);
      await tester.pump();

      innerScrollController.jumpTo(3000);
      await tester.pump();
      outerScrollController.jumpTo(3000);
      await tester.pump();

      // Reparent both
      final _CustomPainter painter = _CustomPainter();

      await tester.pumpWidget(
        SizedBox(
          child: buildNestedListViews(
            child: RepaintBoundary(
              child: CustomPaint(painter: painter),
            ),
          ),
        ),
      );

      expect(tester.renderObject(find.byKey(innerKey, skipOffstage: false)).hasStaleLayout, isTrue);
      expect(tester.renderObject(find.byKey(outerKey, skipOffstage: false)).hasStaleLayout, isTrue);
      expect(painter.paintCount, 0);
    });

    testWidgets('reparenting keptalive', (WidgetTester tester) async {
    });
  });

  testWidgets('KeepAlive with ListView without itemExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          cacheExtent: 0.0,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          addSemanticIndexes: false,
          children: generateList(const SizedBox(height: 12.3, child: Placeholder())), // about 50 widgets visible
        ),
      ),
    );
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0.0, -300.0)); // about 25 widgets' worth
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState!.setKeepAlive(true);
    await tester.drag(find.byType(ListView), const Offset(0.0, 300.0)); // back to top
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState!.setKeepAlive(false);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
  });

  testWidgets('KeepAlive with GridView', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.count(
          cacheExtent: 0.0,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          addSemanticIndexes: false,
          crossAxisCount: 2,
          childAspectRatio: 400.0 / 24.6, // about 50 widgets visible
          children: generateList(const Placeholder()),
        ),
      ),
    );
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    await tester.drag(find.byType(GridView), const Offset(0.0, -300.0)); // about 25 widgets' worth
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState!.setKeepAlive(true);
    await tester.drag(find.byType(GridView), const Offset(0.0, 300.0)); // back to top
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState!.setKeepAlive(false);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
  });

  testWidgets('KeepAlive render tree description', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          addSemanticIndexes: false,
          itemExtent: 400.0, // 2 visible children
          children: generateList(const Placeholder()),
        ),
      ),
    );
    // The important lines below are the ones marked with "<----"
    expect(tester.binding.renderView.toStringDeep(minLevel: DiagnosticLevel.info), equalsIgnoringHashCodes(
      'RenderView#00000\n'
      ' │ debug mode enabled - ${Platform.operatingSystem}\n'
      ' │ window size: Size(2400.0, 1800.0) (in physical pixels)\n'
      ' │ device pixel ratio: 3.0 (physical pixels per logical pixel)\n'
      ' │ configuration: Size(800.0, 600.0) at 3.0x (in logical pixels)\n'
      ' │\n'
      ' └─child: RenderRepaintBoundary#00000\n'
      '   │ needs compositing\n'
      '   │ parentData: <none>\n'
      '   │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '   │ layer: OffsetLayer#00000\n'
      '   │ size: Size(800.0, 600.0)\n'
      '   │ metrics: 0.0% useful (1 bad vs 0 good)\n'
      '   │ diagnosis: insufficient data to draw conclusion (less than five\n'
      '   │   repaints)\n'
      '   │\n'
      '   └─child: RenderCustomPaint#00000\n'
      '     │ needs compositing\n'
      '     │ parentData: <none> (can use size)\n'
      '     │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '     │ size: Size(800.0, 600.0)\n'
      '     │\n'
      '     └─child: RenderRepaintBoundary#00000\n'
      '       │ needs compositing\n'
      '       │ parentData: <none> (can use size)\n'
      '       │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '       │ layer: OffsetLayer#00000\n'
      '       │ size: Size(800.0, 600.0)\n'
      '       │ metrics: 0.0% useful (1 bad vs 0 good)\n'
      '       │ diagnosis: insufficient data to draw conclusion (less than five\n'
      '       │   repaints)\n'
      '       │\n'
      '       └─child: _RenderScrollSemantics#00000\n'
      '         │ needs compositing\n'
      '         │ parentData: <none> (can use size)\n'
      '         │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '         │ semantics node: SemanticsNode#1\n'
      '         │ semantic boundary\n'
      '         │ size: Size(800.0, 600.0)\n'
      '         │\n'
      '         └─child: RenderPointerListener#00000\n'
      '           │ needs compositing\n'
      '           │ parentData: <none> (can use size)\n'
      '           │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '           │ size: Size(800.0, 600.0)\n'
      '           │ behavior: deferToChild\n'
      '           │ listeners: signal\n'
      '           │\n'
      '           └─child: RenderSemanticsGestureHandler#00000\n'
      '             │ needs compositing\n'
      '             │ parentData: <none> (can use size)\n'
      '             │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '             │ size: Size(800.0, 600.0)\n'
      '             │ behavior: opaque\n'
      '             │ gestures: vertical scroll\n'
      '             │\n'
      '             └─child: RenderPointerListener#00000\n'
      '               │ needs compositing\n'
      '               │ parentData: <none> (can use size)\n'
      '               │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '               │ size: Size(800.0, 600.0)\n'
      '               │ behavior: opaque\n'
      '               │ listeners: down\n'
      '               │\n'
      '               └─child: RenderSemanticsAnnotations#00000\n'
      '                 │ needs compositing\n'
      '                 │ parentData: <none> (can use size)\n'
      '                 │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '                 │ size: Size(800.0, 600.0)\n'
      '                 │\n'
      '                 └─child: RenderIgnorePointer#00000\n'
      '                   │ needs compositing\n'
      '                   │ parentData: <none> (can use size)\n'
      '                   │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '                   │ size: Size(800.0, 600.0)\n'
      '                   │ ignoring: false\n'
      '                   │ ignoringSemantics: false\n'
      '                   │\n'
      '                   └─child: RenderViewport#00000\n'
      '                     │ needs compositing\n'
      '                     │ parentData: <none> (can use size)\n'
      '                     │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '                     │ layer: OffsetLayer#00000\n'
      '                     │ size: Size(800.0, 600.0)\n'
      '                     │ axisDirection: down\n'
      '                     │ crossAxisDirection: right\n'
      '                     │ offset: ScrollPositionWithSingleContext#00000(offset: 0.0, range:\n'
      '                     │   0.0..39400.0, viewport: 600.0, ScrollableState,\n'
      '                     │   AlwaysScrollableScrollPhysics -> ClampingScrollPhysics ->\n'
      '                     │   RangeMaintainingScrollPhysics, IdleScrollActivity#00000,\n'
      '                     │   ScrollDirection.idle)\n'
      '                     │ anchor: 0.0\n'
      '                     │\n'
      '                     └─center child: RenderSliverFixedExtentList#00000 relayoutBoundary=up1\n'
      '                       │ parentData: paintOffset=Offset(0.0, 0.0) (can use size)\n'
      '                       │ constraints: SliverConstraints(AxisDirection.down,\n'
      '                       │   GrowthDirection.forward, ScrollDirection.idle, scrollOffset:\n'
      '                       │   0.0, remainingPaintExtent: 600.0, crossAxisExtent: 800.0,\n'
      '                       │   crossAxisDirection: AxisDirection.right,\n'
      '                       │   viewportMainAxisExtent: 600.0, remainingCacheExtent: 850.0,\n'
      '                       │   cacheOrigin: 0.0)\n'
      '                       │ geometry: SliverGeometry(scrollExtent: 40000.0, paintExtent:\n'
      '                       │   600.0, maxPaintExtent: 40000.0, hasVisualOverflow: true,\n'
      '                       │   cacheExtent: 850.0)\n'
      '                       │ currently live children: 0 to 2\n'
      '                       │\n'
      '                       ├─child with index 0: RenderLimitedBox#00000\n'
      '                       │ │ parentData: index=0; layoutOffset=0.0\n'
      '                       │ │ constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                       │ │ size: Size(800.0, 400.0)\n'
      '                       │ │ maxWidth: 400.0\n'
      '                       │ │ maxHeight: 400.0\n'
      '                       │ │\n'
      '                       │ └─child: RenderCustomPaint#00000\n'
      '                       │     parentData: <none> (can use size)\n'
      '                       │     constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                       │     size: Size(800.0, 400.0)\n'
      '                       │\n'
      '                       ├─child with index 1: RenderLimitedBox#00000\n'                                     // <----- no dashed line starts here
      '                       │ │ parentData: index=1; layoutOffset=400.0\n'
      '                       │ │ constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                       │ │ size: Size(800.0, 400.0)\n'
      '                       │ │ maxWidth: 400.0\n'
      '                       │ │ maxHeight: 400.0\n'
      '                       │ │\n'
      '                       │ └─child: RenderCustomPaint#00000\n'
      '                       │     parentData: <none> (can use size)\n'
      '                       │     constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                       │     size: Size(800.0, 400.0)\n'
      '                       │\n'
      '                       └─child with index 2: RenderLimitedBox#00000 NEEDS-PAINT\n'
      '                         │ parentData: index=2; layoutOffset=800.0\n'
      '                         │ constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                         │ size: Size(800.0, 400.0)\n'
      '                         │ maxWidth: 400.0\n'
      '                         │ maxHeight: 400.0\n'
      '                         │\n'
      '                         └─child: RenderCustomPaint#00000 NEEDS-PAINT\n'
      '                             parentData: <none> (can use size)\n'
      '                             constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                             size: Size(800.0, 400.0)\n',
    ));
    const GlobalObjectKey<_LeafState>(0).currentState!.setKeepAlive(true);
    await tester.drag(find.byType(ListView), const Offset(0.0, -1000.0));
    await tester.pump();
    const GlobalObjectKey<_LeafState>(3).currentState!.setKeepAlive(true);
    await tester.drag(find.byType(ListView), const Offset(0.0, -1000.0));
    await tester.pump();
    expect(tester.binding.renderView.toStringDeep(minLevel: DiagnosticLevel.info), equalsIgnoringHashCodes(
      'RenderView#00000\n'
      ' │ debug mode enabled - ${Platform.operatingSystem}\n'
      ' │ window size: Size(2400.0, 1800.0) (in physical pixels)\n'
      ' │ device pixel ratio: 3.0 (physical pixels per logical pixel)\n'
      ' │ configuration: Size(800.0, 600.0) at 3.0x (in logical pixels)\n'
      ' │\n'
      ' └─child: RenderRepaintBoundary#00000\n'
      '   │ needs compositing\n'
      '   │ parentData: <none>\n'
      '   │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '   │ layer: OffsetLayer#00000\n'
      '   │ size: Size(800.0, 600.0)\n'
      '   │ metrics: 0.0% useful (1 bad vs 0 good)\n'
      '   │ diagnosis: insufficient data to draw conclusion (less than five\n'
      '   │   repaints)\n'
      '   │\n'
      '   └─child: RenderCustomPaint#00000\n'
      '     │ needs compositing\n'
      '     │ parentData: <none> (can use size)\n'
      '     │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '     │ size: Size(800.0, 600.0)\n'
      '     │\n'
      '     └─child: RenderRepaintBoundary#00000\n'
      '       │ needs compositing\n'
      '       │ parentData: <none> (can use size)\n'
      '       │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '       │ layer: OffsetLayer#00000\n'
      '       │ size: Size(800.0, 600.0)\n'
      '       │ metrics: 0.0% useful (1 bad vs 0 good)\n'
      '       │ diagnosis: insufficient data to draw conclusion (less than five\n'
      '       │   repaints)\n'
      '       │\n'
      '       └─child: _RenderScrollSemantics#00000\n'
      '         │ needs compositing\n'
      '         │ parentData: <none> (can use size)\n'
      '         │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '         │ semantics node: SemanticsNode#1\n'
      '         │ semantic boundary\n'
      '         │ size: Size(800.0, 600.0)\n'
      '         │\n'
      '         └─child: RenderPointerListener#00000\n'
      '           │ needs compositing\n'
      '           │ parentData: <none> (can use size)\n'
      '           │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '           │ size: Size(800.0, 600.0)\n'
      '           │ behavior: deferToChild\n'
      '           │ listeners: signal\n'
      '           │\n'
      '           └─child: RenderSemanticsGestureHandler#00000\n'
      '             │ needs compositing\n'
      '             │ parentData: <none> (can use size)\n'
      '             │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '             │ size: Size(800.0, 600.0)\n'
      '             │ behavior: opaque\n'
      '             │ gestures: vertical scroll\n'
      '             │\n'
      '             └─child: RenderPointerListener#00000\n'
      '               │ needs compositing\n'
      '               │ parentData: <none> (can use size)\n'
      '               │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '               │ size: Size(800.0, 600.0)\n'
      '               │ behavior: opaque\n'
      '               │ listeners: down\n'
      '               │\n'
      '               └─child: RenderSemanticsAnnotations#00000\n'
      '                 │ needs compositing\n'
      '                 │ parentData: <none> (can use size)\n'
      '                 │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '                 │ size: Size(800.0, 600.0)\n'
      '                 │\n'
      '                 └─child: RenderIgnorePointer#00000\n'
      '                   │ needs compositing\n'
      '                   │ parentData: <none> (can use size)\n'
      '                   │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '                   │ size: Size(800.0, 600.0)\n'
      '                   │ ignoring: false\n'
      '                   │ ignoringSemantics: false\n'
      '                   │\n'
      '                   └─child: RenderViewport#00000\n'
      '                     │ needs compositing\n'
      '                     │ parentData: <none> (can use size)\n'
      '                     │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
      '                     │ layer: OffsetLayer#00000\n'
      '                     │ size: Size(800.0, 600.0)\n'
      '                     │ axisDirection: down\n'
      '                     │ crossAxisDirection: right\n'
      '                     │ offset: ScrollPositionWithSingleContext#00000(offset: 2000.0,\n'
      '                     │   range: 0.0..39400.0, viewport: 600.0, ScrollableState,\n'
      '                     │   AlwaysScrollableScrollPhysics -> ClampingScrollPhysics ->\n'
      '                     │   RangeMaintainingScrollPhysics, IdleScrollActivity#00000,\n'
      '                     │   ScrollDirection.idle)\n'
      '                     │ anchor: 0.0\n'
      '                     │\n'
      '                     └─center child: RenderSliverFixedExtentList#00000 relayoutBoundary=up1\n'
      '                       │ parentData: paintOffset=Offset(0.0, 0.0) (can use size)\n'
      '                       │ constraints: SliverConstraints(AxisDirection.down,\n'
      '                       │   GrowthDirection.forward, ScrollDirection.idle, scrollOffset:\n'
      '                       │   2000.0, remainingPaintExtent: 600.0, crossAxisExtent: 800.0,\n'
      '                       │   crossAxisDirection: AxisDirection.right,\n'
      '                       │   viewportMainAxisExtent: 600.0, remainingCacheExtent: 1100.0,\n'
      '                       │   cacheOrigin: -250.0)\n'
      '                       │ geometry: SliverGeometry(scrollExtent: 40000.0, paintExtent:\n'
      '                       │   600.0, maxPaintExtent: 40000.0, hasVisualOverflow: true,\n'
      '                       │   cacheExtent: 1100.0)\n'
      '                       │ currently live children: 4 to 7\n'
      '                       │\n'
      '                       ├─child with index 4: RenderLimitedBox#00000 NEEDS-PAINT\n'
      '                       │ │ parentData: index=4; layoutOffset=1600.0\n'
      '                       │ │ constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                       │ │ size: Size(800.0, 400.0)\n'
      '                       │ │ maxWidth: 400.0\n'
      '                       │ │ maxHeight: 400.0\n'
      '                       │ │\n'
      '                       │ └─child: RenderCustomPaint#00000 NEEDS-PAINT\n'
      '                       │     parentData: <none> (can use size)\n'
      '                       │     constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                       │     size: Size(800.0, 400.0)\n'
      '                       │\n'
      '                       ├─child with index 5: RenderLimitedBox#00000\n'                                     // <----- this is index 5, not 0
      '                       │ │ parentData: index=5; layoutOffset=2000.0\n'
      '                       │ │ constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                       │ │ size: Size(800.0, 400.0)\n'
      '                       │ │ maxWidth: 400.0\n'
      '                       │ │ maxHeight: 400.0\n'
      '                       │ │\n'
      '                       │ └─child: RenderCustomPaint#00000\n'
      '                       │     parentData: <none> (can use size)\n'
      '                       │     constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                       │     size: Size(800.0, 400.0)\n'
      '                       │\n'
      '                       ├─child with index 6: RenderLimitedBox#00000\n'
      '                       │ │ parentData: index=6; layoutOffset=2400.0\n'
      '                       │ │ constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                       │ │ size: Size(800.0, 400.0)\n'
      '                       │ │ maxWidth: 400.0\n'
      '                       │ │ maxHeight: 400.0\n'
      '                       │ │\n'
      '                       │ └─child: RenderCustomPaint#00000\n'
      '                       │     parentData: <none> (can use size)\n'
      '                       │     constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                       │     size: Size(800.0, 400.0)\n'
      '                       │\n'
      '                       ├─child with index 7: RenderLimitedBox#00000 NEEDS-PAINT\n'
      '                       ╎ │ parentData: index=7; layoutOffset=2800.0\n'
      '                       ╎ │ constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                       ╎ │ size: Size(800.0, 400.0)\n'
      '                       ╎ │ maxWidth: 400.0\n'
      '                       ╎ │ maxHeight: 400.0\n'
      '                       ╎ │\n'
      '                       ╎ └─child: RenderCustomPaint#00000 NEEDS-PAINT\n'
      '                       ╎     parentData: <none> (can use size)\n'
      '                       ╎     constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                       ╎     size: Size(800.0, 400.0)\n'
      '                       ╎\n'
      '                       ╎╌child with index 0 (kept alive but not laid out): RenderLimitedBox#00000\n'               // <----- this one is index 0 and is marked as being kept alive but not laid out
      '                       ╎ │ parentData: index=0; keepAlive; layoutOffset=0.0\n'
      '                       ╎ │ constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                       ╎ │ size: Size(800.0, 400.0)\n'
      '                       ╎ │ maxWidth: 400.0\n'
      '                       ╎ │ maxHeight: 400.0\n'
      '                       ╎ │\n'
      '                       ╎ └─child: RenderCustomPaint#00000\n'
      '                       ╎     parentData: <none> (can use size)\n'
      '                       ╎     constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                       ╎     size: Size(800.0, 400.0)\n'
      '                       ╎\n'                                                                                // <----- dashed line ends here
      '                       └╌child with index 3 (kept alive but not laid out): RenderLimitedBox#00000\n'
      '                         │ parentData: index=3; keepAlive; layoutOffset=1200.0\n'
      '                         │ constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                         │ size: Size(800.0, 400.0)\n'
      '                         │ maxWidth: 400.0\n'
      '                         │ maxHeight: 400.0\n'
      '                         │\n'
      '                         └─child: RenderCustomPaint#00000\n'
      '                             parentData: <none> (can use size)\n'
      '                             constraints: BoxConstraints(w=800.0, h=400.0)\n'
      '                             size: Size(800.0, 400.0)\n',
    ));
  }, skip: kIsWeb); // https://github.com/flutter/flutter/issues/87876

}
