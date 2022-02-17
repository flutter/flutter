// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class OrderPainter extends CustomPainter {
  const OrderPainter(this.index);

  final int index;

  static List<int> log = <int>[];

  @override
  void paint(Canvas canvas, Size size) {
    log.add(index);
  }

  @override
  bool shouldRepaint(OrderPainter old) => false;
}

Widget log(int index) => CustomPaint(painter: OrderPainter(index));

void main() {
  // NO DIRECTION

  testWidgets('without Directionality or textDirection', (WidgetTester tester) async {
    await tester.pumpWidget(
      const TwoPane(
        startPane: SizedBox(),
        endPane: SizedBox(),
      ),
    );

    // With no Directionality or textDirection, the widget throws
    final String message = tester.takeException().toString();
    expect(message, contains('Directionality'));
    expect(message, contains('textDirection'));
  });

  testWidgets('TwoPane separating display feature overrides params', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');
    // A 20 pixel-wide vertical display feature splitting the display left-right
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(390, 0, 410, 600),
            type: DisplayFeatureType.cutout,
            state: DisplayFeatureState.unknown,
          )
        ]
    );

    // Default pane priority is "both"
    // Pane proportion and direction is overridden by the display feature
    // Panes will be laid out left and right of the display feature, at size
    // 390x600, located at 0,0 and 410,0.
    await tester.pumpWidget(MediaQuery(
      data: mediaQuery,
      child: TwoPane(
        key: twoPaneKey,
        textDirection: TextDirection.ltr,
        direction: Axis.vertical,
        verticalDirection: VerticalDirection.up,
        paneProportion: 0.1,
        startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
        endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
      ),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(390.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));
    expect(boxParentData.offset.dy, equals(0.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(390.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(410.0));
    expect(boxParentData.offset.dy, equals(0.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane non-separating display feature is ignored', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');
    // A 600 pixel-wide notch at the top of the screen, does not affect TwoPane
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(100, 0, 700, 100),
            type: DisplayFeatureType.cutout,
            state: DisplayFeatureState.unknown,
          )
        ]
    );

    // Default pane priority is "both"
    // Pane proportion and direction is NOT overridden by the display feature
    await tester.pumpWidget(MediaQuery(
      data: mediaQuery,
      child: TwoPane(
        key: twoPaneKey,
        direction: Axis.vertical,
        textDirection: TextDirection.ltr,
        paneProportion: 0.1,
        startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
        endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
      ),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(60.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));
    expect(boxParentData.offset.dy, equals(0.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(540.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));
    expect(boxParentData.offset.dy, equals(60.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  // Horizontal - LTR

  testWidgets('TwoPane - LTR', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');

    // TwoPane always occupies available space: 800x600.
    // Default paneProportion is 0.5 and default direction is Axis.horizontal,
    // so each pane should be 400x600.
    await tester.pumpWidget(TwoPane(
      key: twoPaneKey,
      textDirection: TextDirection.ltr,
      startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
      endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(400.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(400.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(400.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane - Directionality LTR', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');

    // TwoPane always occupies available space: 800x600.
    // Default paneProportion is 0.5 and default direction is Axis.horizontal,
    // so each pane should be 400x600.
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: TwoPane(
        key: twoPaneKey,
        textDirection: TextDirection.ltr,
        startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
        endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
      ),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(400.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(400.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(400.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane with paneProportion - LTR', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');

    // TwoPane always occupies available space: 800x600.
    // Default direction is Axis.horizontal, and with paneProportion 0.25 panes
    // should be 200x600 and 600x600.
    await tester.pumpWidget(TwoPane(
      key: twoPaneKey,
      textDirection: TextDirection.ltr,
      paneProportion: 0.25,
      startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
      endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(200.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(600.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(200.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane removes MediaQuery paddings and insets - LTR', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    // A 20 pixel-wide vertical display feature splitting the display left-right
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
      padding: const EdgeInsets.all(10),
      viewPadding: const EdgeInsets.all(10),
      viewInsets: const EdgeInsets.all(10),
    );

    late MediaQueryData unpaddedPane1;
    late MediaQueryData unpaddedPane2;
    await tester.pumpWidget(MediaQuery(
      data: mediaQuery,
      child: TwoPane(
        key: twoPaneKey,
        textDirection: TextDirection.ltr,
        startPane: Builder(
          builder: (BuildContext context) {
            unpaddedPane1 = MediaQuery.of(context);
            return log(1);
          },
        ),
        endPane: Builder(
          builder: (BuildContext context) {
            unpaddedPane2 = MediaQuery.of(context);
            return log(2);
          },
        ),
      ),
    ));

    expect(unpaddedPane1.padding, const EdgeInsets.fromLTRB(10, 10, 0, 10));
    expect(unpaddedPane1.viewPadding, const EdgeInsets.fromLTRB(10, 10, 0, 10));
    expect(unpaddedPane1.viewInsets, const EdgeInsets.fromLTRB(10, 10, 0, 10));
    expect(unpaddedPane2.padding, const EdgeInsets.fromLTRB(0, 10, 10, 10));
    expect(unpaddedPane2.viewPadding, const EdgeInsets.fromLTRB(0, 10, 10, 10));
    expect(unpaddedPane2.viewInsets, const EdgeInsets.fromLTRB(0, 10, 10, 10));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane separating display feature - LTR', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');
    // A 20 pixel-wide vertical display feature splitting the display left-right
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(390, 0, 410, 600),
            type: DisplayFeatureType.cutout,
            state: DisplayFeatureState.unknown,
          )
        ]
    );

    // Default pane priority is "both"
    // Pane proportion and direction is overridden by the display feature
    // Panes will be laid out left and right of the display feature, at size
    // 390x600, located at 0,0 and 410,0.
    await tester.pumpWidget(MediaQuery(
      data: mediaQuery,
      child: TwoPane(
        key: twoPaneKey,
        textDirection: TextDirection.ltr,
        startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
        endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
      ),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(390.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));
    expect(boxParentData.offset.dy, equals(0.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(390.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(410.0));
    expect(boxParentData.offset.dy, equals(0.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane separating display feature with padding - LTR', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');
    // A 20 pixel-wide vertical display feature splitting the display left-right
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
      displayFeatures: <DisplayFeature>[
        const DisplayFeature(
          bounds: Rect.fromLTRB(390, 0, 410, 600),
          type: DisplayFeatureType.cutout,
          state: DisplayFeatureState.unknown,
        )
      ],
    );

    // Default pane priority is "both"
    // Pane proportion and direction is overridden by the display feature
    // Panes will be laid out left and right of the display feature
    // Panes "lose" the space occupied by the padding. Top padding
    // affects both panes and left padding affects the left pane.
    // Pane1: 290x500, Pane2: 390x500
    await tester.pumpWidget(MediaQuery(
      data: mediaQuery,
      child: Padding(
        padding: const EdgeInsets.only(top: 100, left: 100),
        child: TwoPane(
          key: twoPaneKey,
          textDirection: TextDirection.ltr,
          inset: const EdgeInsets.only(top: 100, left: 100),
          startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
          endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
        ),
      ),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(700.0));
    expect(renderBox.size.height, equals(500.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(290.0));
    expect(renderBox.size.height, equals(500.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));
    expect(boxParentData.offset.dy, equals(0.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(390.0));
    expect(renderBox.size.height, equals(500.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(310.0));
    expect(boxParentData.offset.dy, equals(0.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  // Horizontal - RTL

  testWidgets('TwoPane - RTL', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');

    // TwoPane always occupies available space: 800x600.
    // Default paneProportion is 0.5 and default direction is Axis.horizontal,
    // so each pane should be 400x600.
    await tester.pumpWidget(TwoPane(
      key: twoPaneKey,
      textDirection: TextDirection.rtl,
      startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
      endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(400.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(400.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(400.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane - Directionality RTL', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');

    // TwoPane always occupies available space: 800x600.
    // Default paneProportion is 0.5 and default direction is Axis.horizontal,
    // so each pane should be 400x600.
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.rtl,
      child: TwoPane(
        key: twoPaneKey,
        startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
        endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
      ),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(400.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(400.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(400.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane with paneProportion - RTL', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');

    // TwoPane always occupies available space: 800x600.
    // Default direction is Axis.horizontal, and with paneProportion 0.25 panes
    // should be 200x600 and 600x600.
    await tester.pumpWidget(TwoPane(
      key: twoPaneKey,
      textDirection: TextDirection.rtl,
      paneProportion: 0.25,
      startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
      endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(200.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(600.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane removes MediaQuery paddings and insets - RTL', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    // A 20 pixel-wide vertical display feature splitting the display left-right
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
      padding: const EdgeInsets.all(10),
      viewPadding: const EdgeInsets.all(10),
      viewInsets: const EdgeInsets.all(10),
    );

    late MediaQueryData unpaddedPane1;
    late MediaQueryData unpaddedPane2;
    await tester.pumpWidget(MediaQuery(
      data: mediaQuery,
      child: TwoPane(
        key: twoPaneKey,
        textDirection: TextDirection.rtl,
        startPane: Builder(
          builder: (BuildContext context) {
            unpaddedPane1 = MediaQuery.of(context);
            return log(1);
          },
        ),
        endPane: Builder(
          builder: (BuildContext context) {
            unpaddedPane2 = MediaQuery.of(context);
            return log(2);
          },
        ),
      ),
    ));

    expect(unpaddedPane1.padding, const EdgeInsets.fromLTRB(0, 10, 10, 10));
    expect(unpaddedPane1.viewPadding, const EdgeInsets.fromLTRB(0, 10, 10, 10));
    expect(unpaddedPane1.viewInsets, const EdgeInsets.fromLTRB(0, 10, 10, 10));
    expect(unpaddedPane2.padding, const EdgeInsets.fromLTRB(10, 10, 0, 10));
    expect(unpaddedPane2.viewPadding, const EdgeInsets.fromLTRB(10, 10, 0, 10));
    expect(unpaddedPane2.viewInsets, const EdgeInsets.fromLTRB(10, 10, 0, 10));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane separating display feature - RTL', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');
    // A 20 pixel-wide vertical display feature splitting the display left-right
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(390, 0, 410, 600),
            type: DisplayFeatureType.cutout,
            state: DisplayFeatureState.unknown,
          )
        ]
    );

    // Default pane priority is "both"
    // Pane proportion and direction is overridden by the display feature
    // Panes will be laid out left and right of the display feature, at size
    // 390x600, located at 0,0 and 410,0.
    await tester.pumpWidget(MediaQuery(
      data: mediaQuery,
      child: TwoPane(
        key: twoPaneKey,
        textDirection: TextDirection.rtl,
        startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
        endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
      ),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(390.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(410.0));
    expect(boxParentData.offset.dy, equals(0.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(390.0));
    expect(renderBox.size.height, equals(600.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));
    expect(boxParentData.offset.dy, equals(0.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane separating display feature with padding - RTL', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');
    // A 20 pixel-wide vertical display feature splitting the display left-right
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
      displayFeatures: <DisplayFeature>[
        const DisplayFeature(
          bounds: Rect.fromLTRB(390, 0, 410, 600),
          type: DisplayFeatureType.cutout,
          state: DisplayFeatureState.unknown,
        )
      ],
    );

    // Default pane priority is "both"
    // Pane proportion and direction is overridden by the display feature
    // Panes will be laid out left and right of the display feature
    // Panes "lose" the space occupied by the padding. Top padding
    // affects both panes and left padding affects the left pane.
    // Pane1: 390x500 , Pane2: 290x500
    await tester.pumpWidget(MediaQuery(
      data: mediaQuery,
      child: Padding(
        padding: const EdgeInsets.only(top: 100, left: 100),
        child: TwoPane(
          key: twoPaneKey,
          textDirection: TextDirection.rtl,
          inset: const EdgeInsets.only(top: 100, left: 100),
          startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
          endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
        ),
      ),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(700.0));
    expect(renderBox.size.height, equals(500.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(390.0));
    expect(renderBox.size.height, equals(500.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(310.0));
    expect(boxParentData.offset.dy, equals(0.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(290.0));
    expect(renderBox.size.height, equals(500.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));
    expect(boxParentData.offset.dy, equals(0.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  // Vertical - down

  testWidgets('TwoPane - down', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');

    // TwoPane always occupies available space: 800x600.
    // Default paneProportion is 0.5 and default direction is down,
    // so each pane should be 800x300.
    await tester.pumpWidget(TwoPane(
      key: twoPaneKey,
      direction: Axis.vertical,
      textDirection: TextDirection.ltr,
      startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
      endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(300.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dy, equals(0.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(300.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dy, equals(300.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane with paneProportion - down', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');

    // TwoPane always occupies available space: 800x600.
    // Default direction is down. Panes should be should be 800x150 and 800x450.
    await tester.pumpWidget(TwoPane(
      key: twoPaneKey,
      direction: Axis.vertical,
      textDirection: TextDirection.ltr,
      paneProportion: 0.25,
      startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
      endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(150.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dy, equals(0.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(450.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dy, equals(150.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane removes MediaQuery paddings and insets - down', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    // A 20 pixel-wide vertical display feature splitting the display left-right
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
      padding: const EdgeInsets.all(10),
      viewPadding: const EdgeInsets.all(10),
      viewInsets: const EdgeInsets.all(10),
    );

    late MediaQueryData unpaddedPane1;
    late MediaQueryData unpaddedPane2;
    await tester.pumpWidget(MediaQuery(
      data: mediaQuery,
      child: TwoPane(
        key: twoPaneKey,
        direction: Axis.vertical,
        textDirection: TextDirection.ltr,
        startPane: Builder(
          builder: (BuildContext context) {
            unpaddedPane1 = MediaQuery.of(context);
            return log(1);
          },
        ),
        endPane: Builder(
          builder: (BuildContext context) {
            unpaddedPane2 = MediaQuery.of(context);
            return log(2);
          },
        ),
      ),
    ));

    expect(unpaddedPane1.padding, const EdgeInsets.fromLTRB(10, 10, 10, 0));
    expect(unpaddedPane1.viewPadding, const EdgeInsets.fromLTRB(10, 10, 10, 0));
    expect(unpaddedPane1.viewInsets, const EdgeInsets.fromLTRB(10, 10, 10, 0));
    expect(unpaddedPane2.padding, const EdgeInsets.fromLTRB(10, 0, 10, 10));
    expect(unpaddedPane2.viewPadding, const EdgeInsets.fromLTRB(10, 0, 10, 10));
    expect(unpaddedPane2.viewInsets, const EdgeInsets.fromLTRB(10, 0, 10, 10));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane separating display feature - down', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');
    // A 20 pixel-wide horizontal display feature splitting the display up-down
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(0, 290, 800, 310),
            type: DisplayFeatureType.cutout,
            state: DisplayFeatureState.unknown,
          )
        ]
    );

    // Default pane priority is "both"
    // Vertical direction default is down
    // Pane proportion and direction is overridden by the display feature
    // Panes will be laid out above and below the display feature, at size
    // 800x290, located at top 0,0 and 310,0.
    await tester.pumpWidget(MediaQuery(
      data: mediaQuery,
      child: TwoPane(
        key: twoPaneKey,
        textDirection: TextDirection.ltr,
        startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
        endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
      ),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(290.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));
    expect(boxParentData.offset.dy, equals(0.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(290.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));
    expect(boxParentData.offset.dy, equals(310.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane separating display feature with padding - down', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');
    // A 20 pixel-wide horizontal display feature splitting the display up-down
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(0, 290, 800, 310),
            type: DisplayFeatureType.cutout,
            state: DisplayFeatureState.unknown,
          )
        ]
    );

    // Default pane priority is "both"
    // Default vertical direction is down
    // Pane proportion and direction is overridden by the display feature
    // Panes will be laid out above and below the display feature
    // Panes "lose" the space occupied by the padding. Left padding
    // affects both panes and top padding affects the top pane.
    // Pane1: 700x190 , Pane2: 700x290
    await tester.pumpWidget(MediaQuery(
      data: mediaQuery,
      child: Padding(
        padding: const EdgeInsets.only(top: 100, left: 100),
        child: TwoPane(
          key: twoPaneKey,
          textDirection: TextDirection.ltr,
          inset: const EdgeInsets.only(top: 100, left: 100),
          startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
          endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
        ),
      ),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(700.0));
    expect(renderBox.size.height, equals(500.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(700.0));
    expect(renderBox.size.height, equals(190.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));
    expect(boxParentData.offset.dy, equals(0.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(700.0));
    expect(renderBox.size.height, equals(290.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));
    expect(boxParentData.offset.dy, equals(210.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  // Vertical - up

  testWidgets('TwoPane - up', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');

    // TwoPane always occupies available space: 800x600.
    // Default paneProportion is 0.5,
    // so each pane should be 800x300.
    await tester.pumpWidget(TwoPane(
      key: twoPaneKey,
      direction: Axis.vertical,
      verticalDirection: VerticalDirection.up,
      textDirection: TextDirection.ltr,
      startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
      endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(300.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dy, equals(300.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(300.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dy, equals(0.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane with paneProportion - up', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');

    // TwoPane always occupies available space: 800x600.
    // Panes should be should be 800x150 and 800x450.
    await tester.pumpWidget(TwoPane(
      key: twoPaneKey,
      direction: Axis.vertical,
      textDirection: TextDirection.ltr,
      verticalDirection: VerticalDirection.up,
      paneProportion: 0.25,
      startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
      endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(150.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dy, equals(450.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(450.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dy, equals(0.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane removes MediaQuery paddings and insets - up', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    // A 20 pixel-wide vertical display feature splitting the display left-right
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
      padding: const EdgeInsets.all(10),
      viewPadding: const EdgeInsets.all(10),
      viewInsets: const EdgeInsets.all(10),
    );

    late MediaQueryData unpaddedPane1;
    late MediaQueryData unpaddedPane2;
    await tester.pumpWidget(MediaQuery(
      data: mediaQuery,
      child: TwoPane(
        key: twoPaneKey,
        direction: Axis.vertical,
        textDirection: TextDirection.ltr,
        verticalDirection: VerticalDirection.up,
        startPane: Builder(
          builder: (BuildContext context) {
            unpaddedPane1 = MediaQuery.of(context);
            return log(1);
          },
        ),
        endPane: Builder(
          builder: (BuildContext context) {
            unpaddedPane2 = MediaQuery.of(context);
            return log(2);
          },
        ),
      ),
    ));

    expect(unpaddedPane1.padding, const EdgeInsets.fromLTRB(10, 0, 10, 10));
    expect(unpaddedPane1.viewPadding, const EdgeInsets.fromLTRB(10, 0, 10, 10));
    expect(unpaddedPane1.viewInsets, const EdgeInsets.fromLTRB(10, 0, 10, 10));
    expect(unpaddedPane2.padding, const EdgeInsets.fromLTRB(10, 10, 10, 0));
    expect(unpaddedPane2.viewPadding, const EdgeInsets.fromLTRB(10, 10, 10, 0));
    expect(unpaddedPane2.viewInsets, const EdgeInsets.fromLTRB(10, 10, 10, 0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane separating display feature - up', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');
    // A 20 pixel-wide horizontal display feature splitting the display up-down
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(0, 290, 800, 310),
            type: DisplayFeatureType.cutout,
            state: DisplayFeatureState.unknown,
          )
        ]
    );

    // Default pane priority is "both"
    // Pane proportion and direction is overridden by the display feature
    // Panes will be laid out above and below the display feature, at size
    // 800x290, located at top 0,0 and 310,0.
    await tester.pumpWidget(MediaQuery(
      data: mediaQuery,
      child: TwoPane(
        key: twoPaneKey,
        verticalDirection: VerticalDirection.up,
        textDirection: TextDirection.ltr,
        startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
        endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
      ),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(600.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(290.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));
    expect(boxParentData.offset.dy, equals(310.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(290.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));
    expect(boxParentData.offset.dy, equals(0.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });

  testWidgets('TwoPane separating display feature with padding - up', (WidgetTester tester) async {
    OrderPainter.log.clear();
    const Key twoPaneKey = Key('twoPane');
    const Key pane1Key = Key('pane1');
    const Key pane2Key = Key('pane2');
    // A 20 pixel-wide horizontal display feature splitting the display up-down
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
        displayFeatures: <DisplayFeature>[
          const DisplayFeature(
            bounds: Rect.fromLTRB(0, 290, 800, 310),
            type: DisplayFeatureType.cutout,
            state: DisplayFeatureState.unknown,
          )
        ]
    );

    // Default pane priority is "both"
    // Default vertical direction is down
    // Pane proportion and direction is overridden by the display feature
    // Panes will be laid out above and below the display feature
    // Panes "lose" the space occupied by the padding. Left and right padding
    // affects both panes and top padding affects the top pane and bottom
    // padding affects the bottom pane
    // Pane2: 694x236, Pane2: 694x238
    await tester.pumpWidget(MediaQuery(
      data: mediaQuery,
      child: Padding(
        padding: const EdgeInsets.only(left: 52, right: 54, top: 52, bottom: 54),
        child: TwoPane(
          key: twoPaneKey,
          textDirection: TextDirection.ltr,
          verticalDirection: VerticalDirection.up,
          inset: const EdgeInsets.only(left: 52, right: 54, top: 52, bottom: 54),
          startPane: SizedBox(key: pane1Key, width: 100.0, height: 100.0, child: log(1)),
          endPane: SizedBox(key: pane2Key, width: 100.0, height: 100.0, child: log(2)),
        ),
      ),
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(twoPaneKey));
    expect(renderBox.size.width, equals(694.0));
    expect(renderBox.size.height, equals(494.0));

    renderBox = tester.renderObject(find.byKey(pane1Key));
    expect(renderBox.size.width, equals(694.0));
    expect(renderBox.size.height, equals(236.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));
    expect(boxParentData.offset.dy, equals(258.0));

    renderBox = tester.renderObject(find.byKey(pane2Key));
    expect(renderBox.size.width, equals(694.0));
    expect(renderBox.size.height, equals(238.0));
    boxParentData = renderBox.parentData! as BoxParentData;
    expect(boxParentData.offset.dx, equals(0.0));
    expect(boxParentData.offset.dy, equals(0.0));

    expect(OrderPainter.log, <int>[1, 2]);
  });
}
