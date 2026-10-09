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
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsetsOverlayMetrics metrics,
                ) {
                  observedConstraints = constraints;
                  observedInsets = metrics.padding;
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
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsetsOverlayMetrics metrics,
                ) {
                  observedInsets = metrics.padding;
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
                  (
                    BuildContext context,
                    BoxConstraints constraints,
                    EdgeInsetsOverlayMetrics metrics,
                  ) {
                    return const SizedBox(key: .new('content'), width: 300.0, height: 200.0);
                  },
            ),
          ),
        ),
      );

      final RenderBox overlayBox = tester.renderObject(
        find.byWidgetPredicate((Widget widget) => widget is EdgeInsetsOverlay),
      );
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
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsetsOverlayMetrics metrics,
                ) {
                  observedInsets = metrics.padding;
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
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsetsOverlayMetrics metrics,
                ) {
                  observedInsets = metrics.padding;
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
            child: EdgeInsetsOverlay(
              left: const SizedBox(key: .new('left'), width: 30.0, height: 80.0),
              top: const SidePositioned.end(
                child: SizedBox(key: .new('top'), width: 100.0, height: 40.0),
              ),
              right: const SidePositioned.start(
                child: SizedBox(key: .new('right'), width: 40.0, height: 60.0),
              ),
              bottom: const SidePositioned.end(
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

      // Left overlay: default center -> y = (300 - 80) * 0.5 = 110.0; x = 0.0
      expect(
        tester.getRect(find.byKey(const .new('left'))),
        const Rect.fromLTWH(0.0, 110.0, 30.0, 80.0),
      );

      // Top overlay: SidePositioned.end -> x = 400 - 100 = 300.0; y = 0.0
      expect(
        tester.getRect(find.byKey(const .new('top'))),
        const Rect.fromLTWH(300.0, 0.0, 100.0, 40.0),
      );

      // Right overlay: SidePositioned.start -> y = 0.0; x = 400 - 40 = 360.0
      expect(
        tester.getRect(find.byKey(const .new('right'))),
        const Rect.fromLTWH(360.0, 0.0, 40.0, 60.0),
      );

      // Bottom overlay: SidePositioned.end -> x = 400 - 100 = 300.0; y = 300 - 50 = 250.0
      expect(
        tester.getRect(find.byKey(const .new('bottom'))),
        const Rect.fromLTWH(300.0, 250.0, 100.0, 50.0),
      );
    });

    testWidgets('updates left, top, right, and bottom alignments dynamically on rebuild', (
      WidgetTester tester,
    ) async {
      Widget buildWidget({
        required double leftAlignment,
        required double topAlignment,
        required double rightAlignment,
        required double bottomAlignment,
      }) {
        return Directionality(
          textDirection: .ltr,
          child: Align(
            alignment: .topLeft,
            child: EdgeInsetsOverlay(
              left: SidePositioned(
                alignment: leftAlignment,
                child: const SizedBox(key: .new('left'), width: 50.0, height: 60.0),
              ),
              top: SidePositioned(
                alignment: topAlignment,
                child: const SizedBox(key: .new('top'), width: 100.0, height: 40.0),
              ),
              right: SidePositioned(
                alignment: rightAlignment,
                child: const SizedBox(key: .new('right'), width: 50.0, height: 60.0),
              ),
              bottom: SidePositioned(
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
          leftAlignment: 0.0,
          topAlignment: 0.0,
          rightAlignment: 0.0,
          bottomAlignment: 0.0,
        ),
      );

      // Rebuild with unchanged alignments to verify early-exit branch
      await tester.pumpWidget(
        buildWidget(
          leftAlignment: 0.0,
          topAlignment: 0.0,
          rightAlignment: 0.0,
          bottomAlignment: 0.0,
        ),
      );

      // Rebuild with new alignments to verify layout update
      await tester.pumpWidget(
        buildWidget(
          leftAlignment: -1.0,
          topAlignment: 1.0,
          rightAlignment: 1.0,
          bottomAlignment: -1.0,
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

    testWidgets('respects TextDirection.rtl for horizontal edge alignments', (
      WidgetTester tester,
    ) async {
      Widget buildWidget({required TextDirection textDirection, TextDirection? widgetDirection}) {
        return Directionality(
          textDirection: textDirection,
          child: Align(
            alignment: .topLeft,
            child: EdgeInsetsOverlay(
              textDirection: widgetDirection,
              top: const SidePositioned.start(
                child: SizedBox(key: ValueKey<String>('top'), width: 100.0, height: 40.0),
              ),
              bottom: const SidePositioned.end(
                child: SizedBox(key: ValueKey<String>('bottom'), width: 100.0, height: 50.0),
              ),
              left: const SidePositioned.start(
                child: SizedBox(key: ValueKey<String>('left'), width: 30.0, height: 80.0),
              ),
              right: const SidePositioned.end(
                child: SizedBox(key: ValueKey<String>('right'), width: 40.0, height: 60.0),
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

      await tester.pumpWidget(buildWidget(textDirection: .rtl));

      // In RTL, top overlay with start alignment is placed on the RIGHT (x = 400 - 100 = 300.0)
      expect(
        tester.getRect(find.byKey(const ValueKey<String>('top'))),
        const Rect.fromLTWH(300.0, 0.0, 100.0, 40.0),
      );

      // In RTL, bottom overlay with end alignment is placed on the LEFT (x = 0.0)
      expect(
        tester.getRect(find.byKey(const ValueKey<String>('bottom'))),
        const Rect.fromLTWH(0.0, 250.0, 100.0, 50.0),
      );

      // Left and right overlays (vertical) are NOT affected by TextDirection
      // Left overlay with start alignment: y = 0.0, x = 0.0
      expect(
        tester.getRect(find.byKey(const ValueKey<String>('left'))),
        const Rect.fromLTWH(0.0, 0.0, 30.0, 80.0),
      );
      // Right overlay with end alignment: y = 300 - 60 = 240.0, x = 400 - 40 = 360.0
      expect(
        tester.getRect(find.byKey(const ValueKey<String>('right'))),
        const Rect.fromLTWH(360.0, 240.0, 40.0, 60.0),
      );

      // Dynamic update: change Directionality to LTR
      await tester.pumpWidget(buildWidget(textDirection: .ltr));

      // In LTR, top overlay with start alignment is placed on the LEFT (x = 0.0)
      expect(
        tester.getRect(find.byKey(const ValueKey<String>('top'))),
        const Rect.fromLTWH(0.0, 0.0, 100.0, 40.0),
      );
      // In LTR, bottom overlay with end alignment is placed on the RIGHT (x = 300.0)
      expect(
        tester.getRect(find.byKey(const ValueKey<String>('bottom'))),
        const Rect.fromLTWH(300.0, 250.0, 100.0, 50.0),
      );

      // Explicit textDirection parameter overrides ambient Directionality
      await tester.pumpWidget(buildWidget(textDirection: .ltr, widgetDirection: .rtl));
      expect(
        tester.getRect(find.byKey(const ValueKey<String>('top'))),
        const Rect.fromLTWH(300.0, 0.0, 100.0, 40.0),
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
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsetsOverlayMetrics metrics,
                ) {
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
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsetsOverlayMetrics metrics,
                ) {
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
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsetsOverlayMetrics metrics,
                ) {
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
            child: EdgeInsetsOverlay(
              top: SidePositioned.start(
                child: GestureDetector(
                  behavior: .opaque,
                  onTap: () {
                    topTapped = true;
                  },
                  child: const SizedBox(key: .new('top'), width: 200.0, height: 50.0),
                ),
              ),
              left: SidePositioned.end(
                child: GestureDetector(
                  behavior: .opaque,
                  onTap: () {
                    leftTapped = true;
                  },
                  child: const SizedBox(key: .new('left'), width: 60.0, height: 100.0),
                ),
              ),
              builder: (
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
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsetsOverlayMetrics metrics,
                ) {
                  return const SizedBox(width: 300.0, height: 200.0);
                },
          ),
        ),
      );

      final RenderBox renderBox = tester.renderObject(
        find.byWidgetPredicate((Widget widget) => widget is EdgeInsetsOverlay),
      );

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
      const widget = EdgeInsetsOverlay(
        left: SizedBox(width: 40.0),
        top: SizedBox(height: 50.0),
        right: SizedBox(width: 60.0),
        bottom: SizedBox(height: 70.0),
        paintOrder: <EdgeInsetsOverlaySlot>[.top, .left],
        builder: _dummyMetricsBuilder,
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
          child: EdgeInsetsOverlay(
            left: const SidePositioned.start(child: SizedBox(width: 40.0)),
            top: const SidePositioned.end(child: SizedBox(height: 50.0)),
            right: const SidePositioned.start(child: SizedBox(width: 60.0)),
            bottom: const SidePositioned.end(child: SizedBox(height: 70.0)),
            paintOrder: const <EdgeInsetsOverlaySlot>[.bottom, .child],
            builder: (
              BuildContext context,
              BoxConstraints constraints,
              EdgeInsetsOverlayMetrics metrics,
            ) => const SizedBox.expand(),
          ),
        ),
      );

      final RenderBox renderObject = tester.renderObject(
        find.byWidgetPredicate((Widget widget) => widget is EdgeInsetsOverlay),
      );
      final renderBuilder = DiagnosticPropertiesBuilder();
      renderObject.debugFillProperties(renderBuilder);

      final List<DiagnosticsNode> renderProps = renderBuilder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .toList();

      expect(renderProps.any((DiagnosticsNode n) => n.name == 'paintOrder'), isTrue);
      expect(renderProps.any((DiagnosticsNode n) => n.name == 'metrics'), isTrue);
    });

    testWidgets('visitChildrenForSemantics visits children in paintOrder', (
      WidgetTester tester,
    ) async {
      final topKey = UniqueKey();
      final bottomKey = UniqueKey();
      final childKey = UniqueKey();

      Widget buildWidget(List<EdgeInsetsOverlaySlot> paintOrder) {
        return Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay(
            paintOrder: paintOrder,
            top: SizedBox(key: topKey, height: 50.0),
            bottom: SizedBox(key: bottomKey, height: 60.0),
            builder: (
              BuildContext context,
              BoxConstraints constraints,
              EdgeInsetsOverlayMetrics metrics,
            ) => SizedBox.expand(key: childKey),
          ),
        );
      }

      await tester.pumpWidget(buildWidget(const <EdgeInsetsOverlaySlot>[.bottom, .top, .child]));

      final RenderBox renderObject = tester.renderObject(
        find.byWidgetPredicate(
          (Widget widget) => widget.runtimeType.toString() == '_SlottedEdgeInsetsOverlay',
        ),
      );
      final RenderBox topRender = tester.renderObject(find.byKey(topKey));
      final RenderBox bottomRender = tester.renderObject(find.byKey(bottomKey));
      final RenderBox childRender = tester.renderObject(find.byType(LayoutBuilder));

      final visited = <RenderObject>[];
      void visitor(RenderObject child) {
        visited.add(child);
      }

      renderObject.visitChildrenForSemantics(visitor);

      expect(visited, <RenderObject>[bottomRender, topRender, childRender]);

      // Rebuild with a different paintOrder and verify the visit order is updated.
      await tester.pumpWidget(buildWidget(const <EdgeInsetsOverlaySlot>[.child, .top, .bottom]));

      visited.clear();
      renderObject.visitChildrenForSemantics(visitor);

      expect(visited, <RenderObject>[childRender, topRender, bottomRender]);
    });
  });

  group('EdgeInsetsOverlayMetrics', () {
    test('equality and hashCode contract', () {
      const EdgeInsetsOverlayMetrics metrics1 = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{.top: .new(100.0, 50.0)},
        alignments: <EdgeInsetsOverlaySlot, double>{.top: -1.0},
      );

      const EdgeInsetsOverlayMetrics metrics2 = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{.top: .new(100.0, 50.0)},
        alignments: <EdgeInsetsOverlaySlot, double>{.top: -1.0},
      );

      const EdgeInsetsOverlayMetrics metrics3 = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{.top: .new(100.0, 60.0)},
      );
      const EdgeInsetsOverlayMetrics metrics4 = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{.bottom: .new(100.0, 50.0)},
      );
      const EdgeInsetsOverlayMetrics metrics5 = .new(
        alignments: <EdgeInsetsOverlaySlot, double>{.bottom: 1.0},
      );

      expect(metrics1, equals(metrics1));
      expect(metrics1, equals(metrics2));
      expect(metrics1.hashCode, equals(metrics2.hashCode));
      expect(metrics1, isNot(equals(metrics3)));
      expect(metrics1, isNot(equals(metrics4)));
      expect(metrics1, isNot(equals(metrics5)));
      expect(metrics1, isNot(equals(Object())));
      expect(metrics1.toString(), contains('EdgeInsetsOverlayMetrics'));

      const EdgeInsetsOverlayMetrics metricsLtr = .new(textDirection: .ltr);
      const EdgeInsetsOverlayMetrics metricsRtl = .new(textDirection: .rtl);
      expect(metricsLtr, isNot(equals(metricsRtl)));
      expect(metricsRtl.toString(), contains('textDirection: TextDirection.rtl'));

      const EdgeInsetsOverlayMetrics metricsOrderA = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{.top: .new(100.0, 50.0), .left: .new(40.0, 80.0)},
        alignments: <EdgeInsetsOverlaySlot, double>{.top: -1.0, .left: 1.0},
      );
      const EdgeInsetsOverlayMetrics metricsOrderB = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{.left: .new(40.0, 80.0), .top: .new(100.0, 50.0)},
        alignments: <EdgeInsetsOverlaySlot, double>{.left: 1.0, .top: -1.0},
      );
      expect(metricsOrderA, equals(metricsOrderB));
      expect(metricsOrderA.hashCode, equals(metricsOrderB.hashCode));
    });

    test('alignment getters resolve correctly with alignments and textDirection', () {
      const EdgeInsetsOverlayMetrics metricsRtl = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{
          .left: .new(40.0, 100.0),
          .top: .new(100.0, 40.0),
          .right: .new(50.0, 80.0),
          .bottom: .new(100.0, 40.0),
        },
        alignments: <EdgeInsetsOverlaySlot, double>{
          .left: -0.5,
          .top: -1.0,
          .right: 0.5,
          .bottom: 1.0,
        },
        textDirection: .rtl,
      );

      expect(metricsRtl.leftAlignment, -0.5);
      expect(metricsRtl.topAlignment, -1.0);
      expect(metricsRtl.rightAlignment, 0.5);
      expect(metricsRtl.bottomAlignment, 1.0);
      // In RTL, start is right, end is left
      expect(metricsRtl.startAlignment, 0.5);
      expect(metricsRtl.endAlignment, -0.5);

      const EdgeInsetsOverlayMetrics metricsLtr = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{
          .left: .new(40.0, 100.0),
          .top: .new(100.0, 40.0),
          .right: .new(50.0, 80.0),
          .bottom: .new(100.0, 40.0),
        },
        alignments: <EdgeInsetsOverlaySlot, double>{
          .left: -0.5,
          .top: -1.0,
          .right: 0.5,
          .bottom: 1.0,
        },
        textDirection: .ltr,
      );

      expect(metricsLtr.leftAlignment, -0.5);
      expect(metricsLtr.topAlignment, -1.0);
      expect(metricsLtr.rightAlignment, 0.5);
      expect(metricsLtr.bottomAlignment, 1.0);
      // In LTR, start is left, end is right
      expect(metricsLtr.startAlignment, -0.5);
      expect(metricsLtr.endAlignment, 0.5);
    });

    test('empty metrics returns null for alignments and handles presence flags correctly', () {
      const EdgeInsetsOverlayMetrics emptyMetrics = .new();
      expect(emptyMetrics.hasLeft, isFalse);
      expect(emptyMetrics.hasTop, isFalse);
      expect(emptyMetrics.hasRight, isFalse);
      expect(emptyMetrics.hasBottom, isFalse);
      expect(emptyMetrics.hasStart, isFalse);
      expect(emptyMetrics.hasEnd, isFalse);
      expect(emptyMetrics.leftSize, isNull);
      expect(emptyMetrics.topSize, isNull);
      expect(emptyMetrics.rightSize, isNull);
      expect(emptyMetrics.bottomSize, isNull);
      expect(emptyMetrics.startSize, isNull);
      expect(emptyMetrics.endSize, isNull);
      expect(emptyMetrics.leftAlignment, isNull);
      expect(emptyMetrics.topAlignment, isNull);
      expect(emptyMetrics.rightAlignment, isNull);
      expect(emptyMetrics.bottomAlignment, isNull);
      expect(emptyMetrics.startAlignment, isNull);
      expect(emptyMetrics.endAlignment, isNull);
    });

    test('start and end APIs resolve according to textDirection', () {
      const EdgeInsetsOverlayMetrics metricsLtr = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{.left: .new(40.0, 100.0), .right: .new(50.0, 80.0)},
        alignments: <EdgeInsetsOverlaySlot, double>{.left: -1.0, .right: 1.0},
        textDirection: .ltr,
      );
      const EdgeInsetsOverlayMetrics metricsRtl = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{.left: .new(40.0, 100.0), .right: .new(50.0, 80.0)},
        alignments: <EdgeInsetsOverlaySlot, double>{.left: -1.0, .right: 1.0},
        textDirection: .rtl,
      );
      const EdgeInsetsOverlayMetrics metricsUnspecified = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{.left: .new(40.0, 100.0), .right: .new(50.0, 80.0)},
        alignments: <EdgeInsetsOverlaySlot, double>{.left: -1.0, .right: 1.0},
      );

      // In LTR: start is left, end is right
      expect(metricsLtr.hasStart, isTrue);
      expect(metricsLtr.hasEnd, isTrue);
      expect(metricsLtr.startSize, metricsLtr.leftSize);
      expect(metricsLtr.endSize, metricsLtr.rightSize);
      expect(metricsLtr.startAlignment, metricsLtr.leftAlignment);
      expect(metricsLtr.endAlignment, metricsLtr.rightAlignment);

      // In RTL: start is right, end is left
      expect(metricsRtl.hasStart, isTrue);
      expect(metricsRtl.hasEnd, isTrue);
      expect(metricsRtl.startSize, metricsRtl.rightSize);
      expect(metricsRtl.endSize, metricsRtl.leftSize);
      expect(metricsRtl.startAlignment, metricsRtl.rightAlignment);
      expect(metricsRtl.endAlignment, metricsRtl.leftAlignment);

      // When textDirection is null: defaults to LTR
      expect(metricsUnspecified.hasStart, isTrue);
      expect(metricsUnspecified.hasEnd, isTrue);
      expect(metricsUnspecified.startSize, metricsUnspecified.leftSize);
      expect(metricsUnspecified.endSize, metricsUnspecified.rightSize);
      expect(metricsUnspecified.startAlignment, metricsUnspecified.leftAlignment);
      expect(metricsUnspecified.endAlignment, metricsUnspecified.rightAlignment);

      // Asymmetric presence test
      const EdgeInsetsOverlayMetrics leftOnlyRtl = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{.left: .new(40.0, 100.0)},
        textDirection: .rtl,
      );
      expect(leftOnlyRtl.hasStart, isFalse);
      expect(leftOnlyRtl.hasEnd, isTrue);

      const EdgeInsetsOverlayMetrics leftOnlyLtr = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{.left: .new(40.0, 100.0)},
        textDirection: .ltr,
      );
      expect(leftOnlyLtr.hasStart, isTrue);
      expect(leftOnlyLtr.hasEnd, isFalse);
    });

    test('padding and directionalPadding getters compute insets from sizes', () {
      const EdgeInsetsOverlayMetrics metrics = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{
          .left: .new(10.0, 100.0),
          .top: .new(200.0, 20.0),
          .right: .new(30.0, 100.0),
          .bottom: .new(200.0, 40.0),
        },
        textDirection: .ltr,
      );

      expect(metrics.padding, const EdgeInsets.fromLTRB(10.0, 20.0, 30.0, 40.0));
      expect(
        metrics.directionalPadding,
        const EdgeInsetsDirectional.fromSTEB(10.0, 20.0, 30.0, 40.0),
      );

      const EdgeInsetsOverlayMetrics metricsRtl = .new(
        sizes: <EdgeInsetsOverlaySlot, Size>{
          .left: .new(10.0, 100.0),
          .top: .new(200.0, 20.0),
          .right: .new(30.0, 100.0),
          .bottom: .new(200.0, 40.0),
        },
        textDirection: .rtl,
      );

      // Physical padding is unchanged by textDirection
      expect(metricsRtl.padding, const EdgeInsets.fromLTRB(10.0, 20.0, 30.0, 40.0));
      // Directional padding swaps start/end in RTL (start is right: 30.0, end is left: 10.0)
      expect(
        metricsRtl.directionalPadding,
        const EdgeInsetsDirectional.fromSTEB(30.0, 20.0, 10.0, 40.0),
      );

      const EdgeInsetsOverlayMetrics empty = .new();
      expect(empty.padding, EdgeInsets.zero);
      expect(empty.directionalPadding, EdgeInsetsDirectional.zero);
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
            child: EdgeInsetsOverlay(
              left: const SizedBox(width: 40.0, height: 100.0),
              top: const SidePositioned.start(child: SizedBox(width: 120.0, height: 60.0)),
              right: const SidePositioned.end(child: SizedBox(width: 50.0, height: 80.0)),
              bottom: const SizedBox(width: 200.0, height: 70.0),
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
      expect(metrics.startSize, const Size(40.0, 100.0));
      expect(metrics.endSize, const Size(50.0, 80.0));

      // presence checks
      expect(metrics.hasLeft, isTrue);
      expect(metrics.hasTop, isTrue);
      expect(metrics.hasRight, isTrue);
      expect(metrics.hasBottom, isTrue);
      expect(metrics.hasStart, isTrue);
      expect(metrics.hasEnd, isTrue);

      // alignments
      expect(metrics.leftAlignment, 0.0);
      expect(metrics.topAlignment, -1.0);
      expect(metrics.rightAlignment, 1.0);
      expect(metrics.bottomAlignment, 0.0);
      expect(metrics.startAlignment, 0.0);
      expect(metrics.endAlignment, 1.0);
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
                    (
                      BuildContext context,
                      BoxConstraints constraints,
                      EdgeInsetsOverlayMetrics metrics,
                    ) {
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

  group('EdgeInsetsOverlayDirectional', () {
    testWidgets('provides EdgeInsetsDirectional in LTR context', (WidgetTester tester) async {
      EdgeInsetsDirectional? observedInsets;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlayDirectional(
            start: const SizedBox(key: .new('start'), width: 40.0, height: 200.0),
            top: const SizedBox(key: .new('top'), width: 300.0, height: 50.0),
            end: const SizedBox(key: .new('end'), width: 60.0, height: 200.0),
            bottom: const SizedBox(key: .new('bottom'), width: 300.0, height: 70.0),
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsetsOverlayMetrics metrics,
                ) {
                  observedInsets = metrics.directionalPadding;
                  return const SizedBox.expand();
                },
          ),
        ),
      );

      expect(observedInsets, const EdgeInsetsDirectional.fromSTEB(40.0, 50.0, 60.0, 70.0));
      // In LTR: start is left, end is right
      expect(
        tester.getRect(find.byKey(const .new('start'))),
        const Rect.fromLTWH(0.0, 200.0, 40.0, 200.0),
      );
      expect(
        tester.getRect(find.byKey(const .new('end'))),
        const Rect.fromLTWH(740.0, 200.0, 60.0, 200.0),
      );
    });

    testWidgets('provides EdgeInsetsDirectional and flips start/end positions in RTL context', (
      WidgetTester tester,
    ) async {
      EdgeInsetsDirectional? observedInsets;

      await tester.pumpWidget(
        Directionality(
          textDirection: .rtl,
          child: EdgeInsetsOverlayDirectional(
            start: const SizedBox(key: .new('start'), width: 40.0, height: 200.0),
            top: const SizedBox(key: .new('top'), width: 300.0, height: 50.0),
            end: const SizedBox(key: .new('end'), width: 60.0, height: 200.0),
            bottom: const SizedBox(key: .new('bottom'), width: 300.0, height: 70.0),
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsetsOverlayMetrics metrics,
                ) {
                  observedInsets = metrics.directionalPadding;
                  return const SizedBox.expand();
                },
          ),
        ),
      );

      expect(observedInsets, const EdgeInsetsDirectional.fromSTEB(40.0, 50.0, 60.0, 70.0));
      // In RTL: start is right (x = 800 - 40 = 760), end is left (x = 0)
      expect(
        tester.getRect(find.byKey(const .new('start'))),
        const Rect.fromLTWH(760.0, 200.0, 40.0, 200.0),
      );
      expect(
        tester.getRect(find.byKey(const .new('end'))),
        const Rect.fromLTWH(0.0, 200.0, 60.0, 200.0),
      );
    });

    testWidgets('asserts if no Directionality widget is found when textDirection is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        EdgeInsetsOverlayDirectional(
          builder:
              (BuildContext context, BoxConstraints constraints, EdgeInsetsOverlayMetrics metrics) {
                return const SizedBox.expand();
              },
        ),
      );

      final Object? exception = tester.takeException();
      expect(exception, isA<FlutterError>());
      expect((exception! as FlutterError).message, contains('No Directionality widget found'));
    });

    testWidgets('uses explicit textDirection parameter over ambient Directionality', (
      WidgetTester tester,
    ) async {
      EdgeInsetsDirectional? observedInsets;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlayDirectional(
            textDirection: .rtl,
            start: const SizedBox(key: .new('start'), width: 40.0, height: 200.0),
            end: const SizedBox(key: .new('end'), width: 60.0, height: 200.0),
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsetsOverlayMetrics metrics,
                ) {
                  observedInsets = metrics.directionalPadding;
                  return const SizedBox.expand();
                },
          ),
        ),
      );

      expect(observedInsets, const EdgeInsetsDirectional.fromSTEB(40.0, 0.0, 60.0, 0.0));
      // Explicit textDirection is RTL: start is right (x = 760), end is left (x = 0)
      expect(
        tester.getRect(find.byKey(const .new('start'))),
        const Rect.fromLTWH(760.0, 200.0, 40.0, 200.0),
      );
      expect(
        tester.getRect(find.byKey(const .new('end'))),
        const Rect.fromLTWH(0.0, 200.0, 60.0, 200.0),
      );
    });

    testWidgets('debugFillProperties exports diagnostic properties', (WidgetTester tester) async {
      final widgetBuilder = DiagnosticPropertiesBuilder();
      const widget = EdgeInsetsOverlayDirectional(
        start: SizedBox(width: 40.0),
        top: SizedBox(height: 50.0),
        end: SizedBox(width: 60.0),
        bottom: SizedBox(height: 70.0),
        builder: _dummyMetricsBuilder,
      );

      widget.debugFillProperties(widgetBuilder);

      final List<DiagnosticsNode> widgetProps = widgetBuilder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .toList();

      expect(widgetProps.any((DiagnosticsNode n) => n.name == 'start' && n.value != null), isTrue);
      expect(widgetProps.any((DiagnosticsNode n) => n.name == 'top' && n.value != null), isTrue);
      expect(widgetProps.any((DiagnosticsNode n) => n.name == 'end' && n.value != null), isTrue);
      expect(widgetProps.any((DiagnosticsNode n) => n.name == 'bottom' && n.value != null), isTrue);
    });
  });

  group('SidePositioned', () {
    testWidgets('applies alignment to EdgeInsetsOverlayParentData', (WidgetTester tester) async {
      const childKey = Key('child');
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay(
            top: const SidePositioned.end(child: SizedBox(key: childKey, width: 50, height: 50)),
            builder: (
              BuildContext context,
              BoxConstraints constraints,
              EdgeInsetsOverlayMetrics metrics,
            ) => const SizedBox.expand(),
          ),
        ),
      );

      final RenderBox renderBox = tester.renderObject(find.byKey(childKey));
      expect(renderBox.parentData, isA<EdgeInsetsOverlayParentData>());
      final parentData = renderBox.parentData! as EdgeInsetsOverlayParentData;
      expect(parentData.alignment, 1.0);
    });

    test('constructors configure expected alignments', () {
      const child = SizedBox();
      const defaultPositioned = SidePositioned(child: child);
      expect(defaultPositioned.alignment, 0.0);

      const startPositioned = SidePositioned.start(child: child);
      expect(startPositioned.alignment, -1.0);

      const centerPositioned = SidePositioned.center(child: child);
      expect(centerPositioned.alignment, 0.0);

      const endPositioned = SidePositioned.end(child: child);
      expect(endPositioned.alignment, 1.0);

      const customPositioned = SidePositioned(alignment: 0.5, child: child);
      expect(customPositioned.alignment, 0.5);

      expect(() => SidePositioned(alignment: -1.5, child: child), throwsAssertionError);
      expect(() => SidePositioned(alignment: 1.5, child: child), throwsAssertionError);
    });

    test('debugFillProperties exports alignment property', () {
      final builder = DiagnosticPropertiesBuilder();
      const positioned = SidePositioned.start(child: SizedBox());
      positioned.debugFillProperties(builder);

      final List<DiagnosticsNode> props = builder.properties
          .where((DiagnosticsNode n) => !n.isFiltered(DiagnosticLevel.info))
          .toList();
      expect(props.any((DiagnosticsNode n) => n.name == 'alignment'), isTrue);
    });

    testWidgets('positions overlays according to SidePositioned alignment', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: Center(
            child: SizedBox(
              width: 400.0,
              height: 300.0,
              child: EdgeInsetsOverlay(
                top: const SidePositioned.end(
                  child: SizedBox(key: .new('top'), width: 100.0, height: 50.0),
                ),
                left: const SidePositioned.start(
                  child: SizedBox(key: .new('left'), width: 40.0, height: 80.0),
                ),
                builder: (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsetsOverlayMetrics metrics,
                ) => const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      final RenderBox topBox = tester.renderObject(find.byKey(const .new('top')));
      final topParentData = topBox.parentData! as BoxParentData;
      expect(topParentData.offset, const Offset(300.0, 0.0));

      final RenderBox leftBox = tester.renderObject(find.byKey(const .new('left')));
      final leftParentData = leftBox.parentData! as BoxParentData;
      expect(leftParentData.offset, Offset.zero);
    });

    testWidgets('asserts when SidePositioned is placed outside EdgeInsetsOverlay', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: .ltr,
          child: Stack(children: <Widget>[SidePositioned(child: SizedBox())]),
        ),
      );

      final Object? exception = tester.takeException();
      expect(exception, isA<FlutterError>());
      expect((exception! as FlutterError).message, contains('Incorrect use of ParentDataWidget'));
    });
  });
}

Widget _dummyMetricsBuilder(
  BuildContext context,
  BoxConstraints constraints,
  EdgeInsetsOverlayMetrics metrics,
) => const SizedBox();
