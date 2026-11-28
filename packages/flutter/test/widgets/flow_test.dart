// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestFlowDelegate extends FlowDelegate {
  TestFlowDelegate({required this.startOffset}) : super(repaint: startOffset);

  final Animation<double> startOffset;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    double dy = startOffset.value;
    for (var i = 0; i < context.childCount; ++i) {
      context.paintChild(i, transform: Matrix4.translationValues(0.0, dy, 0.0));
      dy += 0.75 * context.getChildSize(i)!.height;
    }
  }

  @override
  bool shouldRepaint(TestFlowDelegate oldDelegate) => startOffset == oldDelegate.startOffset;
}

class OpacityFlowDelegate extends FlowDelegate {
  OpacityFlowDelegate(this.opacity);

  double opacity;

  @override
  void paintChildren(FlowPaintingContext context) {
    for (var i = 0; i < context.childCount; ++i) {
      context.paintChild(i, opacity: opacity);
    }
  }

  @override
  bool shouldRepaint(OpacityFlowDelegate oldDelegate) => opacity != oldDelegate.opacity;
}

// OpacityFlowDelegate that paints one of its children twice
class DuplicatePainterOpacityFlowDelegate extends OpacityFlowDelegate {
  DuplicatePainterOpacityFlowDelegate(super.opacity);

  @override
  void paintChildren(FlowPaintingContext context) {
    for (var i = 0; i < context.childCount; ++i) {
      context.paintChild(i, opacity: opacity);
    }
    if (context.childCount > 0) {
      context.paintChild(0, opacity: opacity);
    }
  }
}

void main() {
  testWidgets('Flow control test', (WidgetTester tester) async {
    final startOffset = AnimationController.unbounded(vsync: tester);
    addTearDown(startOffset.dispose);
    final log = <int>[];

    Widget buildBox(int i) {
      return GestureDetector(
        onTap: () {
          log.add(i);
        },
        child: Container(
          width: 100.0,
          height: 100.0,
          color: const Color(0xFF0000FF),
          child: Text('$i', textDirection: TextDirection.ltr),
        ),
      );
    }

    await tester.pumpWidget(
      Flow(
        delegate: TestFlowDelegate(startOffset: startOffset),
        children: <Widget>[
          buildBox(0),
          buildBox(1),
          buildBox(2),
          buildBox(3),
          buildBox(4),
          buildBox(5),
          buildBox(6),
        ],
      ),
    );

    await tester.tap(find.text('0'));
    expect(log, equals(<int>[0]));
    await tester.tap(find.text('1'));
    expect(log, equals(<int>[0, 1]));
    await tester.tap(find.text('2'));
    expect(log, equals(<int>[0, 1, 2]));

    log.clear();
    await tester.tapAt(const Offset(20.0, 90.0));
    expect(log, equals(<int>[1]));

    startOffset.value = 50.0;
    await tester.pump();

    log.clear();
    await tester.tapAt(const Offset(20.0, 90.0));
    expect(log, equals(<int>[0]));
  });

  testWidgets('paintChild gets called twice', (WidgetTester tester) async {
    await tester.pumpWidget(
      Flow(
        delegate: DuplicatePainterOpacityFlowDelegate(1.0),
        children: const <Widget>[
          SizedBox(width: 100.0, height: 100.0),
          SizedBox(width: 100.0, height: 100.0),
        ],
      ),
    );
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    final error = exception as FlutterError;
    expect(
      error.toStringDeep(),
      equalsIgnoringHashCodes(
        'FlutterError\n'
        '   Cannot call paintChild twice for the same child.\n'
        '   The flow delegate of type DuplicatePainterOpacityFlowDelegate\n'
        '   attempted to paint child 0 multiple times, which is not\n'
        '   permitted.\n',
      ),
    );
  });

  testWidgets('Flow opacity layer', (WidgetTester tester) async {
    const opacity = 0.2;
    await tester.pumpWidget(
      Flow(
        delegate: OpacityFlowDelegate(opacity),
        children: const <Widget>[SizedBox(width: 100.0, height: 100.0)],
      ),
    );
    ContainerLayer? layer = RendererBinding.instance.renderView.debugLayer;
    while (layer != null && layer is! OpacityLayer) {
      layer = layer.firstChild as ContainerLayer?;
    }
    expect(layer, isA<OpacityLayer>());
    final opacityLayer = layer as OpacityLayer?;
    expect(opacityLayer!.alpha, equals(opacity * 255));
    expect(layer!.firstChild, isA<TransformLayer>());
  });

  testWidgets('Flow can set and update clipBehavior', (WidgetTester tester) async {
    const opacity = 0.2;
    await tester.pumpWidget(
      Flow(
        delegate: OpacityFlowDelegate(opacity),
        children: const <Widget>[SizedBox(width: 100.0, height: 100.0)],
      ),
    );

    // By default, clipBehavior should be Clip.hardEdge
    final RenderFlow renderObject = tester.renderObject(find.byType(Flow));
    expect(renderObject.clipBehavior, equals(Clip.hardEdge));

    for (final Clip clip in Clip.values) {
      await tester.pumpWidget(
        Flow(
          delegate: OpacityFlowDelegate(opacity),
          clipBehavior: clip,
          children: const <Widget>[SizedBox(width: 100.0, height: 100.0)],
        ),
      );
      expect(renderObject.clipBehavior, clip);
    }
  });

  testWidgets('Flow.unwrapped can set and update clipBehavior', (WidgetTester tester) async {
    const opacity = 0.2;
    await tester.pumpWidget(
      Flow.unwrapped(
        delegate: OpacityFlowDelegate(opacity),
        children: const <Widget>[SizedBox(width: 100.0, height: 100.0)],
      ),
    );

    // By default, clipBehavior should be Clip.hardEdge
    final RenderFlow renderObject = tester.renderObject(find.byType(Flow));
    expect(renderObject.clipBehavior, equals(Clip.hardEdge));

    for (final Clip clip in Clip.values) {
      await tester.pumpWidget(
        Flow.unwrapped(
          delegate: OpacityFlowDelegate(opacity),
          clipBehavior: clip,
          children: const <Widget>[SizedBox(width: 100.0, height: 100.0)],
        ),
      );
      expect(renderObject.clipBehavior, clip);
    }
  });

  testWidgets('Flow does not crash at zero area', (WidgetTester tester) async {
    tester.view.physicalSize = Size.zero;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Center(
        child: Flow(delegate: OpacityFlowDelegate(0.2), children: const <Widget>[Placeholder()]),
      ),
    );
    expect(tester.getSize(find.byType(Flow)), Size.zero);
  });

  testWidgets('Flow clips the semantics rect of an overflowing child', (WidgetTester tester) async {
    Widget buildFlow(Clip clipBehavior) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 100,
            height: 100,
            child: Flow(
              delegate: _TranslateFlowDelegate(const Offset(0, 50)),
              clipBehavior: clipBehavior,
              children: <Widget>[
                Semantics(
                  label: 'target',
                  container: true,
                  child: const SizedBox(width: 100, height: 100),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Only the top half of the target is inside the clip.
    await tester.pumpWidget(buildFlow(Clip.hardEdge));
    expect(
      tester.getSemantics(find.bySemanticsLabel('target')).rect,
      const Rect.fromLTRB(0, 0, 100, 50),
    );

    // Without clipping, the whole target is visible.
    await tester.pumpWidget(buildFlow(Clip.none));
    expect(
      tester.getSemantics(find.bySemanticsLabel('target')).rect,
      const Rect.fromLTRB(0, 0, 100, 100),
    );
  });

  testWidgets('Flow updates semantics when only repainting', (WidgetTester tester) async {
    final children = <Widget>[
      Semantics(label: 'target', container: true, child: const SizedBox(width: 100, height: 100)),
    ];

    Widget buildFlow(FlowDelegate delegate) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 100,
            height: 100,
            child: Flow.unwrapped(delegate: delegate, children: children),
          ),
        ),
      );
    }

    Rect targetRect() => tester.getSemantics(find.bySemanticsLabel('target')).rect;

    // Repaint triggered by FlowDelegate.shouldRepaint.
    await tester.pumpWidget(buildFlow(_TranslateFlowDelegate(Offset.zero)));
    expect(targetRect(), const Rect.fromLTRB(0, 0, 100, 100));
    await tester.pumpWidget(buildFlow(_TranslateFlowDelegate(const Offset(0, 50))));
    expect(targetRect(), const Rect.fromLTRB(0, 0, 100, 50));

    // Repaint triggered by the repaint listenable.
    final offset = ValueNotifier<Offset>(Offset.zero);
    addTearDown(offset.dispose);
    await tester.pumpWidget(buildFlow(_ListenableTranslateFlowDelegate(offset)));
    expect(targetRect(), const Rect.fromLTRB(0, 0, 100, 100));
    offset.value = const Offset(0, 50);
    await tester.pump();
    expect(targetRect(), const Rect.fromLTRB(0, 0, 100, 50));
    offset.value = const Offset(0, -25);
    await tester.pump();
    expect(targetRect(), const Rect.fromLTRB(0, 25, 100, 100));
  });
}

class _TranslateFlowDelegate extends FlowDelegate {
  _TranslateFlowDelegate(this.offset);

  final Offset offset;

  @override
  void paintChildren(FlowPaintingContext context) {
    for (var i = 0; i < context.childCount; ++i) {
      context.paintChild(i, transform: Matrix4.translationValues(offset.dx, offset.dy, 0.0));
    }
  }

  @override
  bool shouldRepaint(_TranslateFlowDelegate oldDelegate) => offset != oldDelegate.offset;
}

class _ListenableTranslateFlowDelegate extends FlowDelegate {
  _ListenableTranslateFlowDelegate(this.offset) : super(repaint: offset);

  final ValueNotifier<Offset> offset;

  @override
  void paintChildren(FlowPaintingContext context) {
    for (var i = 0; i < context.childCount; ++i) {
      context.paintChild(
        i,
        transform: Matrix4.translationValues(offset.value.dx, offset.value.dy, 0.0),
      );
    }
  }

  @override
  bool shouldRepaint(_ListenableTranslateFlowDelegate oldDelegate) => offset != oldDelegate.offset;
}
