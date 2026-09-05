// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdgeInsetsOverlay - Insets and Layout', () {
    testWidgets('provides EdgeInsets.zero and incoming BoxConstraints when no sides are provided', (
      WidgetTester tester,
    ) async {
      EdgeInsets? observedInsets;
      BoxConstraints? observedConstraints;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay(
            builder: (BuildContext context, BoxConstraints constraints, EdgeInsets overlayPadding) {
              observedConstraints = constraints;
              observedInsets = overlayPadding;
              return const SizedBox.expand();
            },
          ),
        ),
      );

      expect(observedInsets, EdgeInsets.zero);
      expect(observedConstraints, isNotNull);
      expect(observedConstraints!.biggest, const Size(800.0, 600.0));
      expect(observedConstraints!.isTight, isTrue);
    });

    testWidgets('calculates overlay insets and centers overlays along edges by default', (
      WidgetTester tester,
    ) async {
      EdgeInsets? observedInsets;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay(
            left: const SizedBox(key: .new('left'), width: 40.0, height: 200.0),
            top: const SizedBox(key: .new('top'), width: 300.0, height: 50.0),
            right: const SizedBox(key: .new('right'), width: 60.0, height: 200.0),
            bottom: const SizedBox(key: .new('bottom'), width: 300.0, height: 70.0),
            builder: (BuildContext context, BoxConstraints constraints, EdgeInsets overlayPadding) {
              observedInsets = overlayPadding;
              return const SizedBox.expand();
            },
          ),
        ),
      );

      expect(observedInsets, const EdgeInsets.fromLTRB(40.0, 50.0, 60.0, 70.0));
      // Left: width 40, height 200 centered vertically on 600 -> y = (600 - 200) / 2 = 200
      expect(
        tester.getRect(find.byKey(const .new('left'))),
        const Rect.fromLTWH(0.0, 200.0, 40.0, 200.0),
      );
      // Top: width 300, height 50 centered horizontally on 800 -> x = (800 - 300) / 2 = 250
      expect(
        tester.getRect(find.byKey(const .new('top'))),
        const Rect.fromLTWH(250.0, 0.0, 300.0, 50.0),
      );
      // Right: width 60, height 200 centered vertically on 600 -> x = 800 - 60 = 740, y = 200
      expect(
        tester.getRect(find.byKey(const .new('right'))),
        const Rect.fromLTWH(740.0, 200.0, 60.0, 200.0),
      );
      // Bottom: width 300, height 70 centered horizontally on 800 -> x = 250, y = 600 - 70 = 530
      expect(
        tester.getRect(find.byKey(const .new('bottom'))),
        const Rect.fromLTWH(250.0, 530.0, 300.0, 70.0),
      );
    });

    testWidgets('sizes itself based on contentChild under loose constraints', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: Align(
            alignment: .topLeft,
            child: EdgeInsetsOverlay(
              top: const SizedBox(height: 40.0),
              builder:
                  (BuildContext context, BoxConstraints constraints, EdgeInsets overlayPadding) {
                    return const SizedBox(key: .new('content'), width: 300.0, height: 200.0);
                  },
            ),
          ),
        ),
      );

      final RenderBox overlayBox = tester.renderObject(find.byType(EdgeInsetsOverlay));
      expect(overlayBox.size, const Size(300.0, 200.0));
      expect(
        tester.getRect(find.byKey(const .new('content'))),
        const Rect.fromLTWH(0.0, 0.0, 300.0, 200.0),
      );
    });

    testWidgets('updates insets dynamically on rebuild when overlay sizes change', (
      WidgetTester tester,
    ) async {
      EdgeInsets? observedInsets;

      Widget buildWidget({required double topHeight}) {
        return Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay(
            top: SizedBox(height: topHeight),
            builder: (BuildContext context, BoxConstraints constraints, EdgeInsets overlayPadding) {
              observedInsets = overlayPadding;
              return const SizedBox.expand();
            },
          ),
        );
      }

      await tester.pumpWidget(buildWidget(topHeight: 50.0));
      expect(observedInsets, const EdgeInsets.fromLTRB(0.0, 50.0, 0.0, 0.0));

      await tester.pumpWidget(buildWidget(topHeight: 90.0));
      expect(observedInsets, const EdgeInsets.fromLTRB(0.0, 90.0, 0.0, 0.0));
    });

    testWidgets('updates insets dynamically when side widgets are added or removed', (
      WidgetTester tester,
    ) async {
      EdgeInsets? observedInsets;

      Widget buildWidget({Widget? left, Widget? top}) {
        return Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay(
            left: left,
            top: top,
            builder: (BuildContext context, BoxConstraints constraints, EdgeInsets overlayPadding) {
              observedInsets = overlayPadding;
              return const SizedBox.expand();
            },
          ),
        );
      }

      await tester.pumpWidget(buildWidget(left: const SizedBox(width: 40.0)));
      expect(observedInsets, const EdgeInsets.fromLTRB(40.0, 0.0, 0.0, 0.0));

      await tester.pumpWidget(
        buildWidget(left: const SizedBox(width: 40.0), top: const SizedBox(height: 60.0)),
      );
      expect(observedInsets, const EdgeInsets.fromLTRB(40.0, 60.0, 0.0, 0.0));

      await tester.pumpWidget(buildWidget(top: const SizedBox(height: 60.0)));
      expect(observedInsets, const EdgeInsets.fromLTRB(0.0, 60.0, 0.0, 0.0));

      await tester.pumpWidget(buildWidget());
      expect(observedInsets, EdgeInsets.zero);
    });
  });

  group('EdgeInsetsOverlay - Positioning and Alignment', () {
    testWidgets('positions side overlays with custom alignments', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: Align(
            alignment: .topLeft,
            child: EdgeInsetsOverlay.metrics(
              left: const .new(child: SizedBox(key: .new('left'), width: 30.0, height: 80.0)),
              top: const .new(
                alignment: .end,
                child: SizedBox(key: .new('top'), width: 100.0, height: 40.0),
              ),
              right: const .new(
                alignment: .start,
                child: SizedBox(key: .new('right'), width: 40.0, height: 60.0),
              ),
              bottom: const .new(
                alignment: .end,
                child: SizedBox(key: .new('bottom'), width: 100.0, height: 50.0),
              ),
              builder:
                  (
                    BuildContext context,
                    BoxConstraints constraints,
                    EdgeInsetsOverlayMetrics metrics,
                  ) {
                    return const SizedBox(width: 400.0, height: 300.0);
                  },
            ),
          ),
        ),
      );

      // Left overlay: default EdgeOverlayAlignment.center -> y = (300 - 80) * 0.5 = 110.0; x = 0.0
      expect(
        tester.getRect(find.byKey(const .new('left'))),
        const Rect.fromLTWH(0.0, 110.0, 30.0, 80.0),
      );

      // Top overlay: EdgeOverlayAlignment.end -> x = 400 - 100 = 300.0; y = 0.0
      expect(
        tester.getRect(find.byKey(const .new('top'))),
        const Rect.fromLTWH(300.0, 0.0, 100.0, 40.0),
      );

      // Right overlay: EdgeOverlayAlignment.start -> y = 0.0; x = 400 - 40 = 360.0
      expect(
        tester.getRect(find.byKey(const .new('right'))),
        const Rect.fromLTWH(360.0, 0.0, 40.0, 60.0),
      );

      // Bottom overlay: EdgeOverlayAlignment.end -> x = 400 - 100 = 300.0; y = 300 - 50 = 250.0
      expect(
        tester.getRect(find.byKey(const .new('bottom'))),
        const Rect.fromLTWH(300.0, 250.0, 100.0, 50.0),
      );
    });

    testWidgets('updates left, top, right, and bottom alignments dynamically on rebuild', (
      WidgetTester tester,
    ) async {
      Widget buildWidget({
        required EdgeOverlayAlignment leftAlignment,
        required EdgeOverlayAlignment topAlignment,
        required EdgeOverlayAlignment rightAlignment,
        required EdgeOverlayAlignment bottomAlignment,
      }) {
        return Directionality(
          textDirection: .ltr,
          child: Align(
            alignment: .topLeft,
            child: EdgeInsetsOverlay.metrics(
              left: .new(
                alignment: leftAlignment,
                child: const SizedBox(key: .new('left'), width: 50.0, height: 60.0),
              ),
              top: .new(
                alignment: topAlignment,
                child: const SizedBox(key: .new('top'), width: 100.0, height: 40.0),
              ),
              right: .new(
                alignment: rightAlignment,
                child: const SizedBox(key: .new('right'), width: 50.0, height: 60.0),
              ),
              bottom: .new(
                alignment: bottomAlignment,
                child: const SizedBox(key: .new('bottom'), width: 60.0, height: 40.0),
              ),
              builder:
                  (
                    BuildContext context,
                    BoxConstraints constraints,
                    EdgeInsetsOverlayMetrics metrics,
                  ) {
                    return const SizedBox(width: 400.0, height: 300.0);
                  },
            ),
          ),
        );
      }

      await tester.pumpWidget(
        buildWidget(
          leftAlignment: .center,
          topAlignment: .center,
          rightAlignment: .center,
          bottomAlignment: .center,
        ),
      );

      // Rebuild with unchanged alignments to verify early-exit branch
      await tester.pumpWidget(
        buildWidget(
          leftAlignment: .center,
          topAlignment: .center,
          rightAlignment: .center,
          bottomAlignment: .center,
        ),
      );

      // Rebuild with new alignments to verify layout update
      await tester.pumpWidget(
        buildWidget(
          leftAlignment: .start,
          topAlignment: .end,
          rightAlignment: .end,
          bottomAlignment: .start,
        ),
      );

      // left: x = 0.0, y = 0.0
      expect(
        tester.getRect(find.byKey(const .new('left'))),
        const Rect.fromLTWH(0.0, 0.0, 50.0, 60.0),
      );
      // top: x = 400 - 100 = 300.0, y = 0.0
      expect(
        tester.getRect(find.byKey(const .new('top'))),
        const Rect.fromLTWH(300.0, 0.0, 100.0, 40.0),
      );
      // right: x = 400 - 50 = 350.0, y = 300 - 60 = 240.0
      expect(
        tester.getRect(find.byKey(const .new('right'))),
        const Rect.fromLTWH(350.0, 240.0, 50.0, 60.0),
      );
      // bottom: x = 0.0, y = 300 - 40 = 260.0
      expect(
        tester.getRect(find.byKey(const .new('bottom'))),
        const Rect.fromLTWH(0.0, 260.0, 60.0, 40.0),
      );
    });
  });

  group('EdgeInsetsOverlay - Paint and Hit-Testing', () {
    testWidgets('default hit-testing prioritizes side overlays over builder content', (
      WidgetTester tester,
    ) async {
      var contentTapped = false;
      var topTapped = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay(
            top: GestureDetector(
              behavior: .opaque,
              onTap: () {
                topTapped = true;
              },
              child: const SizedBox(width: double.infinity, height: 60.0),
            ),
            builder: (BuildContext context, BoxConstraints constraints, EdgeInsets overlayPadding) {
              return GestureDetector(
                behavior: .opaque,
                onTap: () {
                  contentTapped = true;
                },
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      );

      // Tap on top overlay area
      await tester.tapAt(const .new(400.0, 30.0));
      expect(topTapped, isTrue);
      expect(contentTapped, isFalse);

      // Tap on content area below top overlay
      await tester.tapAt(const .new(400.0, 200.0));
      expect(contentTapped, isTrue);
    });

    testWidgets('paintOrder determines overlay rendering and hit testing priority', (
      WidgetTester tester,
    ) async {
      var leftTapped = false;
      var topTapped = false;

      Widget buildWithPaintOrder(List<EdgeInsetsOverlaySlot> paintOrder) {
        return Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay(
            paintOrder: paintOrder,
            left: GestureDetector(
              behavior: .opaque,
              onTap: () {
                leftTapped = true;
              },
              child: const SizedBox(width: 50.0, height: double.infinity),
            ),
            top: GestureDetector(
              behavior: .opaque,
              onTap: () {
                topTapped = true;
              },
              child: const SizedBox(width: double.infinity, height: 50.0),
            ),
            builder: (BuildContext context, BoxConstraints constraints, EdgeInsets overlayPadding) {
              return const SizedBox.expand();
            },
          ),
        );
      }

      // When left is painted first, top paints over left at overlapping corner (25, 25)
      await tester.pumpWidget(buildWithPaintOrder(const <EdgeInsetsOverlaySlot>[.left, .top]));

      await tester.tapAt(const .new(25.0, 25.0));
      expect(topTapped, isTrue);
      expect(leftTapped, isFalse);

      leftTapped = false;
      topTapped = false;

      // Rebuild with unchanged paintOrder to test early exit
      await tester.pumpWidget(buildWithPaintOrder(const <EdgeInsetsOverlaySlot>[.left, .top]));

      // When top is painted first, left paints over top at overlapping corner (25, 25)
      await tester.pumpWidget(buildWithPaintOrder(const <EdgeInsetsOverlaySlot>[.top, .left]));

      await tester.tapAt(const .new(25.0, 25.0));
      expect(leftTapped, isTrue);
      expect(topTapped, isFalse);
    });

    testWidgets('paintOrder determines whether child renders beneath or above overlay widgets', (
      WidgetTester tester,
    ) async {
      var childTapped = false;
      var topTapped = false;

      Widget buildWithPaintOrder(List<EdgeInsetsOverlaySlot> paintOrder) {
        return Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay(
            paintOrder: paintOrder,
            top: GestureDetector(
              behavior: .opaque,
              onTap: () {
                topTapped = true;
              },
              child: const SizedBox(width: double.infinity, height: 60.0),
            ),
            builder: (BuildContext context, BoxConstraints constraints, EdgeInsets overlayPadding) {
              return GestureDetector(
                behavior: .opaque,
                onTap: () {
                  childTapped = true;
                },
                child: const SizedBox.expand(),
              );
            },
          ),
        );
      }

      // When child is painted first and top is painted last, top receives hit testing
      await tester.pumpWidget(buildWithPaintOrder(const <EdgeInsetsOverlaySlot>[.child, .top]));

      await tester.tapAt(const .new(400.0, 30.0));
      expect(topTapped, isTrue);
      expect(childTapped, isFalse);

      topTapped = false;
      childTapped = false;

      // When top is painted first and child is painted last, child receives hit testing
      await tester.pumpWidget(buildWithPaintOrder(const <EdgeInsetsOverlaySlot>[.top, .child]));

      await tester.tapAt(const .new(400.0, 30.0));
      expect(childTapped, isTrue);
      expect(topTapped, isFalse);
    });

    testWidgets('hit-tests overlays positioned along edges with alignment offsets', (
      WidgetTester tester,
    ) async {
      var topTapped = false;
      var leftTapped = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: Align(
            alignment: .topLeft,
            child: EdgeInsetsOverlay.metrics(
              top: .new(
                alignment: .start,
                child: GestureDetector(
                  behavior: .opaque,
                  onTap: () {
                    topTapped = true;
                  },
                  child: const SizedBox(key: .new('top'), width: 200.0, height: 50.0),
                ),
              ),
              left: .new(
                alignment: .end,
                child: GestureDetector(
                  behavior: .opaque,
                  onTap: () {
                    leftTapped = true;
                  },
                  child: const SizedBox(key: .new('left'), width: 60.0, height: 100.0),
                ),
              ),
              builder:
                  (
                    BuildContext context,
                    BoxConstraints constraints,
                    EdgeInsetsOverlayMetrics metrics,
                  ) => const SizedBox(width: 300.0, height: 200.0),
            ),
          ),
        ),
      );

      // Top overlay rect is at (0, 0, 200, 50). Tap at (50, 25).
      await tester.tapAt(const .new(50.0, 25.0));
      expect(topTapped, isTrue);

      // Left overlay rect is at (0, 100, 60, 100). Tap at (30, 150).
      await tester.tapAt(const .new(30.0, 150.0));
      expect(leftTapped, isTrue);
    });
  });

  group('EdgeInsetsOverlay - Intrinsics and Dry Layout', () {
    testWidgets('computes intrinsic dimensions and dry layout from contentChild', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay(
            top: const SizedBox(height: 50.0),
            builder: (BuildContext context, BoxConstraints constraints, EdgeInsets overlayPadding) {
              return const SizedBox(width: 300.0, height: 200.0);
            },
          ),
        ),
      );

      final RenderBox renderBox = tester.renderObject(find.byType(EdgeInsetsOverlay));

      RenderObject.debugCheckingIntrinsics = true;
      try {
        expect(renderBox.getMinIntrinsicWidth(100.0), 0.0);
        expect(renderBox.getMaxIntrinsicWidth(100.0), 0.0);
        expect(renderBox.getMinIntrinsicHeight(100.0), 0.0);
        expect(renderBox.getMaxIntrinsicHeight(100.0), 0.0);
        expect(
          renderBox.getDryLayout(const BoxConstraints(maxWidth: 400.0, maxHeight: 300.0)),
          Size.zero,
        );
      } finally {
        RenderObject.debugCheckingIntrinsics = false;
      }
    });
  });

  group('EdgeInsetsOverlay - Diagnostics and Semantics', () {
    testWidgets('debugFillProperties exports diagnostic properties on widget and render object', (
      WidgetTester tester,
    ) async {
      final widgetBuilder = DiagnosticPropertiesBuilder();
      final widget = EdgeInsetsOverlay.metrics(
        left: const .new(child: SizedBox(width: 40.0)),
        top: const .new(child: SizedBox(height: 50.0)),
        right: const .new(child: SizedBox(width: 60.0)),
        bottom: const .new(child: SizedBox(height: 70.0)),
        paintOrder: const <EdgeInsetsOverlaySlot>[.top, .left],
        builder:
            (BuildContext context, BoxConstraints constraints, EdgeInsetsOverlayMetrics metrics) =>
                const SizedBox(),
      );

      widget.debugFillProperties(widgetBuilder);

      final List<DiagnosticsNode> widgetProps = widgetBuilder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .toList();

      expect(widgetProps.any((DiagnosticsNode n) => n.name == 'left' && n.value != null), isTrue);
      expect(widgetProps.any((DiagnosticsNode n) => n.name == 'top' && n.value != null), isTrue);
      expect(widgetProps.any((DiagnosticsNode n) => n.name == 'right' && n.value != null), isTrue);
      expect(widgetProps.any((DiagnosticsNode n) => n.name == 'bottom' && n.value != null), isTrue);
      expect(
        widgetProps.any(
          (DiagnosticsNode n) =>
              n.name == 'paintOrder' && n.value is Iterable<EdgeInsetsOverlaySlot>,
        ),
        isTrue,
      );
      expect(widgetProps.any((DiagnosticsNode n) => n.name == 'builder'), isTrue);

      // Render object diagnostics
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay.metrics(
            left: const .new(alignment: .start, child: SizedBox(width: 40.0)),
            top: const .new(alignment: .end, child: SizedBox(height: 50.0)),
            right: const .new(alignment: .start, child: SizedBox(width: 60.0)),
            bottom: const .new(alignment: .end, child: SizedBox(height: 70.0)),
            paintOrder: const <EdgeInsetsOverlaySlot>[.bottom, .child],
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsetsOverlayMetrics metrics,
                ) => const SizedBox.expand(),
          ),
        ),
      );

      final RenderBox renderObject = tester.renderObject(find.byType(EdgeInsetsOverlay));
      final renderBuilder = DiagnosticPropertiesBuilder();
      renderObject.debugFillProperties(renderBuilder);

      final List<DiagnosticsNode> renderProps = renderBuilder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .toList();

      expect(renderProps.any((DiagnosticsNode n) => n.name == 'leftAlignment'), isTrue);
      expect(renderProps.any((DiagnosticsNode n) => n.name == 'topAlignment'), isTrue);
      expect(renderProps.any((DiagnosticsNode n) => n.name == 'rightAlignment'), isTrue);
      expect(renderProps.any((DiagnosticsNode n) => n.name == 'bottomAlignment'), isTrue);
      expect(renderProps.any((DiagnosticsNode n) => n.name == 'paintOrder'), isTrue);
      expect(renderProps.any((DiagnosticsNode n) => n.name == 'metrics'), isTrue);
    });

    testWidgets('visitChildrenForSemantics visits children in paintOrder', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay(
            paintOrder: const <EdgeInsetsOverlaySlot>[.bottom, .top, .child],
            top: const SizedBox(height: 50.0),
            bottom: const SizedBox(height: 60.0),
            builder:
                (BuildContext context, BoxConstraints constraints, EdgeInsets overlayPadding) =>
                    const SizedBox.expand(),
          ),
        ),
      );

      final RenderBox renderObject = tester.renderObject(find.byType(EdgeInsetsOverlay));
      final visited = <RenderObject>[];
      renderObject.visitChildrenForSemantics((RenderObject child) {
        visited.add(child);
      });

      expect(visited.length, 3);
    });
  });

  group('EdgeOverlayAlignment', () {
    test('constants and value properties', () {
      expect(EdgeOverlayAlignment.start.value, -1.0);
      expect(EdgeOverlayAlignment.center.value, 0.0);
      expect(EdgeOverlayAlignment.end.value, 1.0);
    });

    test('alongOffset computation', () {
      expect(EdgeOverlayAlignment.start.alongOffset(100.0), 0.0);
      expect(EdgeOverlayAlignment.center.alongOffset(100.0), 50.0);
      expect(EdgeOverlayAlignment.end.alongOffset(100.0), 100.0);
      expect(const EdgeOverlayAlignment(-0.5).alongOffset(100.0), 25.0);
      expect(const EdgeOverlayAlignment(0.5).alongOffset(100.0), 75.0);
    });

    test('lerp', () {
      expect(EdgeOverlayAlignment.lerp(null, null, 0.5), isNull);
      expect(
        EdgeOverlayAlignment.lerp(EdgeOverlayAlignment.start, EdgeOverlayAlignment.end, 0.0),
        EdgeOverlayAlignment.start,
      );
      expect(
        EdgeOverlayAlignment.lerp(EdgeOverlayAlignment.start, EdgeOverlayAlignment.end, 0.5),
        EdgeOverlayAlignment.center,
      );
      expect(
        EdgeOverlayAlignment.lerp(EdgeOverlayAlignment.start, EdgeOverlayAlignment.end, 1.0),
        EdgeOverlayAlignment.end,
      );
      expect(
        EdgeOverlayAlignment.lerp(null, EdgeOverlayAlignment.end, 0.5),
        const EdgeOverlayAlignment(0.5),
      );
      expect(
        EdgeOverlayAlignment.lerp(EdgeOverlayAlignment.start, null, 0.5),
        const EdgeOverlayAlignment(-0.5),
      );
    });

    test('equality, hashCode, and toString contract', () {
      const EdgeOverlayAlignment a1 = .new(0.25);
      const EdgeOverlayAlignment a2 = .new(0.25);
      const EdgeOverlayAlignment b = .new(0.5);

      expect(a1, equals(a1));
      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
      expect(a1, isNot(equals(b)));
      expect(a1, isNot(equals(Object())));
      expect(EdgeOverlayAlignment.start.toString(), 'EdgeOverlayAlignment.start');
      expect(EdgeOverlayAlignment.center.toString(), 'EdgeOverlayAlignment.center');
      expect(EdgeOverlayAlignment.end.toString(), 'EdgeOverlayAlignment.end');
      expect(a1.toString(), 'EdgeOverlayAlignment(0.25)');
    });
  });

  group('EdgeInsetsOverlaySide', () {
    test('default constructor creates instance with default alignment', () {
      const Widget child = SizedBox();
      const EdgeInsetsOverlaySide side = .new(child: child);
      expect(side.child, equals(child));
      expect(side.alignment, EdgeOverlayAlignment.center);
    });

    test('equality, hashCode, and toString contract', () {
      const Widget child1 = SizedBox(key: ValueKey<String>('1'));
      const Widget child2 = SizedBox(key: ValueKey<String>('2'));
      const EdgeInsetsOverlaySide side1 = .new(child: child1, alignment: .start);
      const EdgeInsetsOverlaySide side2 = .new(child: child1, alignment: .start);
      const EdgeInsetsOverlaySide side3 = .new(child: child2, alignment: .start);
      const EdgeInsetsOverlaySide side4 = .new(child: child1, alignment: .end);

      expect(side1, equals(side1));
      expect(side1, equals(side2));
      expect(side1.hashCode, equals(side2.hashCode));
      expect(side1, isNot(equals(side3)));
      expect(side1, isNot(equals(side4)));
      expect(side1, isNot(equals(Object())));
      expect(side1.toString(), contains('EdgeInsetsOverlaySide('));
    });
  });

  group('EdgeInsetsOverlayMetrics', () {
    test('equality and hashCode contract', () {
      const EdgeInsetsOverlayMetrics metrics1 = .new(
        padding: .all(10.0),
        sizes: <EdgeInsetsOverlaySlot, Size>{.top: .new(100.0, 50.0)},
        alignments: <EdgeInsetsOverlaySlot, EdgeOverlayAlignment>{.top: .start},
      );

      const EdgeInsetsOverlayMetrics metrics2 = .new(
        padding: .all(10.0),
        sizes: <EdgeInsetsOverlaySlot, Size>{.top: .new(100.0, 50.0)},
        alignments: <EdgeInsetsOverlaySlot, EdgeOverlayAlignment>{.top: .start},
      );

      const EdgeInsetsOverlayMetrics metrics3 = .new(padding: .all(20.0));
      const EdgeInsetsOverlayMetrics metrics4 = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{.bottom: .new(100.0, 50.0)},
      );
      const EdgeInsetsOverlayMetrics metrics5 = .new(
        alignments: <EdgeInsetsOverlaySlot, EdgeOverlayAlignment>{.bottom: .end},
      );

      expect(metrics1, equals(metrics1));
      expect(metrics1, equals(metrics2));
      expect(metrics1.hashCode, equals(metrics2.hashCode));
      expect(metrics1, isNot(equals(metrics3)));
      expect(metrics1, isNot(equals(metrics4)));
      expect(metrics1, isNot(equals(metrics5)));
      expect(metrics1, isNot(equals(Object())));
      expect(metrics1.toString(), contains('EdgeInsetsOverlayMetrics'));

      const EdgeInsetsOverlayMetrics metricsOrderA = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{.top: .new(100.0, 50.0), .left: .new(40.0, 80.0)},
        alignments: <EdgeInsetsOverlaySlot, EdgeOverlayAlignment>{.top: .start, .left: .end},
      );
      const EdgeInsetsOverlayMetrics metricsOrderB = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{.left: .new(40.0, 80.0), .top: .new(100.0, 50.0)},
        alignments: <EdgeInsetsOverlaySlot, EdgeOverlayAlignment>{.left: .end, .top: .start},
      );
      expect(metricsOrderA, equals(metricsOrderB));
      expect(metricsOrderA.hashCode, equals(metricsOrderB.hashCode));
    });

    test('empty metrics returns null for rectOf and handles hasSlot correctly', () {
      const EdgeInsetsOverlayMetrics emptyMetrics = .new();
      expect(emptyMetrics.hasSlot(.left), isFalse);
      expect(emptyMetrics.hasLeft, isFalse);
      expect(emptyMetrics.hasTop, isFalse);
      expect(emptyMetrics.hasRight, isFalse);
      expect(emptyMetrics.hasBottom, isFalse);
      expect(emptyMetrics.leftSize, isNull);
      expect(emptyMetrics.topSize, isNull);
      expect(emptyMetrics.rightSize, isNull);
      expect(emptyMetrics.bottomSize, isNull);
      expect(emptyMetrics.leftAlignment, isNull);
      expect(emptyMetrics.topAlignment, isNull);
      expect(emptyMetrics.rightAlignment, isNull);
      expect(emptyMetrics.bottomAlignment, isNull);
      expect(emptyMetrics.leftRect(const .new(200.0, 200.0)), isNull);
      expect(emptyMetrics.topRect(const .new(200.0, 200.0)), isNull);
      expect(emptyMetrics.rightRect(const .new(200.0, 200.0)), isNull);
      expect(emptyMetrics.bottomRect(const .new(200.0, 200.0)), isNull);
      expect(
        emptyMetrics.rectOf(.child, const .new(200.0, 200.0)),
        const Rect.fromLTWH(0.0, 0.0, 200.0, 200.0),
      );
    });

    test('innerBounds computes correct rectangles', () {
      const EdgeInsetsOverlayMetrics metrics = .new(padding: .fromLTRB(10.0, 20.0, 30.0, 40.0));

      const Size size = .new(300.0, 200.0);
      expect(metrics.innerBounds(size), const Rect.fromLTWH(10.0, 20.0, 260.0, 140.0));
    });

    testWidgets('provides complete EdgeInsetsOverlayMetrics to metrics builder', (
      WidgetTester tester,
    ) async {
      EdgeInsetsOverlayMetrics? observedMetrics;
      BoxConstraints? observedConstraints;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: Align(
            alignment: .topLeft,
            child: EdgeInsetsOverlay.metrics(
              left: const .new(child: SizedBox(width: 40.0, height: 100.0)),
              top: const .new(alignment: .start, child: SizedBox(width: 120.0, height: 60.0)),
              right: const .new(alignment: .end, child: SizedBox(width: 50.0, height: 80.0)),
              bottom: const .new(child: SizedBox(width: 200.0, height: 70.0)),
              builder:
                  (
                    BuildContext context,
                    BoxConstraints constraints,
                    EdgeInsetsOverlayMetrics metrics,
                  ) {
                    observedConstraints = constraints;
                    observedMetrics = metrics;
                    return const SizedBox(width: 400.0, height: 300.0);
                  },
            ),
          ),
        ),
      );

      expect(observedConstraints, isNotNull);
      expect(observedMetrics, isNotNull);
      final EdgeInsetsOverlayMetrics metrics = observedMetrics!;

      // padding
      expect(metrics.padding, const EdgeInsets.fromLTRB(40.0, 60.0, 50.0, 70.0));

      // individual sizes
      expect(metrics.leftSize, const Size(40.0, 100.0));
      expect(metrics.topSize, const Size(120.0, 60.0));
      expect(metrics.rightSize, const Size(50.0, 80.0));
      expect(metrics.bottomSize, const Size(200.0, 70.0));

      // individual alignments
      expect(metrics.leftAlignment, EdgeOverlayAlignment.center);
      expect(metrics.topAlignment, EdgeOverlayAlignment.start);
      expect(metrics.rightAlignment, EdgeOverlayAlignment.end);
      expect(metrics.bottomAlignment, EdgeOverlayAlignment.center);

      // presence checks
      expect(metrics.hasSlot(.left), isTrue);
      expect(metrics.hasLeft, isTrue);
      expect(metrics.hasTop, isTrue);
      expect(metrics.hasRight, isTrue);
      expect(metrics.hasBottom, isTrue);

      // innerBounds helper
      const Size contentSize = .new(400.0, 300.0);
      expect(metrics.innerBounds(contentSize), const Rect.fromLTWH(40.0, 60.0, 310.0, 170.0));

      // rectOf checks with contentSize (400, 300)
      expect(metrics.leftRect(contentSize), const Rect.fromLTWH(0.0, 100.0, 40.0, 100.0));
      expect(metrics.topRect(contentSize), const Rect.fromLTWH(0.0, 0.0, 120.0, 60.0));
      expect(metrics.rightRect(contentSize), const Rect.fromLTWH(350.0, 220.0, 50.0, 80.0));
      expect(metrics.bottomRect(contentSize), const Rect.fromLTWH(100.0, 230.0, 200.0, 70.0));
      expect(metrics.rectOf(.child, contentSize), const Rect.fromLTWH(0.0, 0.0, 400.0, 300.0));
    });
  });

  group('_EdgeInsetsOverlayBoxConstraints', () {
    testWidgets('equality and hashCode contract', (WidgetTester tester) async {
      BoxConstraints? constraintsA;
      BoxConstraints? constraintsAIdentical;
      BoxConstraints? constraintsBDiffMetrics;
      BoxConstraints? constraintsCDiffSize;

      Widget buildHarness({
        required double topHeight,
        double width = 400.0,
        required ValueChanged<BoxConstraints> onConstraints,
      }) {
        return Directionality(
          textDirection: .ltr,
          child: Align(
            alignment: .topLeft,
            child: SizedBox(
              width: width,
              height: 300.0,
              child: EdgeInsetsOverlay(
                top: SizedBox(height: topHeight),
                builder:
                    (BuildContext context, BoxConstraints constraints, EdgeInsets overlayPadding) {
                      onConstraints(constraints);
                      return const SizedBox.expand();
                    },
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(
        buildHarness(topHeight: 50.0, onConstraints: (BoxConstraints c) => constraintsA = c),
      );
      await tester.pumpWidget(
        buildHarness(
          topHeight: 50.0,
          onConstraints: (BoxConstraints c) => constraintsAIdentical = c,
        ),
      );
      await tester.pumpWidget(
        buildHarness(
          topHeight: 80.0,
          onConstraints: (BoxConstraints c) => constraintsBDiffMetrics = c,
        ),
      );
      await tester.pumpWidget(
        buildHarness(
          topHeight: 50.0,
          width: 500.0,
          onConstraints: (BoxConstraints c) => constraintsCDiffSize = c,
        ),
      );

      expect(constraintsA, isNotNull);
      expect(constraintsAIdentical, isNotNull);
      expect(constraintsBDiffMetrics, isNotNull);
      expect(constraintsCDiffSize, isNotNull);

      final BoxConstraints cA = constraintsA!;
      final BoxConstraints cAIdentical = constraintsAIdentical!;
      final BoxConstraints cB = constraintsBDiffMetrics!;
      final BoxConstraints cC = constraintsCDiffSize!;

      expect(cA == cA, isTrue);
      expect(cA == cAIdentical, isTrue);
      expect(cA.hashCode, equals(cAIdentical.hashCode));

      // Different metrics -> not equal
      expect(cA == cB, isFalse);

      // Different outer box dimensions -> not equal
      expect(cA == cC, isFalse);

      // Different type (standard BoxConstraints) -> not equal
      expect(cA == const BoxConstraints(), isFalse);
      expect(cA == .tight(const Size(400.0, 300.0)), isFalse);
    });
  });
}
