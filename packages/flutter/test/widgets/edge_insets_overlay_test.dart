// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdgeInsetsOverlay', () {
    testWidgets('provides EdgeInsets.zero when no sides are provided', (WidgetTester tester) async {
      EdgeInsets? observedInsets;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay(
            builder: (BuildContext context, EdgeInsets overlayPadding) {
              observedInsets = overlayPadding;
              return const SizedBox.expand();
            },
          ),
        ),
      );

      expect(observedInsets, EdgeInsets.zero);
    });

    testWidgets('calculates overlay insets with top and bottom side widgets', (
      WidgetTester tester,
    ) async {
      EdgeInsets? observedInsets;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay(
            top: const SizedBox(key: Key('top'), height: 60.0),
            bottom: const SizedBox(key: Key('bottom'), height: 80.0),
            builder: (BuildContext context, EdgeInsets overlayPadding) {
              observedInsets = overlayPadding;
              return const SizedBox.expand();
            },
          ),
        ),
      );

      expect(observedInsets, const EdgeInsets.fromLTRB(0.0, 60.0, 0.0, 80.0));
      expect(
        tester.getRect(find.byKey(const Key('top'))),
        const Rect.fromLTWH(0.0, 0.0, 800.0, 60.0),
      );
      expect(
        tester.getRect(find.byKey(const Key('bottom'))),
        const Rect.fromLTWH(0.0, 520.0, 800.0, 80.0),
      );
    });

    testWidgets('calculates overlay insets with all 4 sides', (WidgetTester tester) async {
      EdgeInsets? observedInsets;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay(
            left: const SizedBox(key: Key('left'), width: 40.0),
            top: const SizedBox(key: Key('top'), height: 50.0),
            right: const SizedBox(key: Key('right'), width: 60.0),
            bottom: const SizedBox(key: Key('bottom'), height: 70.0),
            builder: (BuildContext context, EdgeInsets overlayPadding) {
              observedInsets = overlayPadding;
              return const SizedBox.expand();
            },
          ),
        ),
      );

      expect(observedInsets, const EdgeInsets.fromLTRB(40.0, 50.0, 60.0, 70.0));
      expect(
        tester.getRect(find.byKey(const Key('left'))),
        const Rect.fromLTWH(0.0, 0.0, 40.0, 600.0),
      );
      expect(
        tester.getRect(find.byKey(const Key('top'))),
        const Rect.fromLTWH(0.0, 0.0, 800.0, 50.0),
      );
      expect(
        tester.getRect(find.byKey(const Key('right'))),
        const Rect.fromLTWH(740.0, 0.0, 60.0, 600.0),
      );
      expect(
        tester.getRect(find.byKey(const Key('bottom'))),
        const Rect.fromLTWH(0.0, 530.0, 800.0, 70.0),
      );
    });

    testWidgets('hit testing order prioritizes side widgets over builder content', (
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
              child: const SizedBox(height: 60.0),
            ),
            builder: (BuildContext context, EdgeInsets overlayPadding) {
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

      await tester.tapAt(const .new(400.0, 30.0));
      expect(topTapped, isTrue);
      expect(contentTapped, isFalse);

      await tester.tapAt(const .new(400.0, 200.0));
      expect(contentTapped, isTrue);
    });

    testWidgets('updates insets dynamically on rebuild', (WidgetTester tester) async {
      EdgeInsets? observedInsets;

      Widget buildWidget({required double topHeight}) {
        return Directionality(
          textDirection: .ltr,
          child: EdgeInsetsOverlay(
            top: SizedBox(height: topHeight),
            builder: (BuildContext context, EdgeInsets overlayPadding) {
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

    testWidgets('debugFillProperties exports diagnostic properties', (WidgetTester tester) async {
      final builder = DiagnosticPropertiesBuilder();
      final widget = EdgeInsetsOverlay(
        left: const SizedBox(width: 40.0),
        top: const SizedBox(height: 50.0),
        right: const SizedBox(width: 60.0),
        bottom: const SizedBox(height: 70.0),
        paintOrder: const <EdgeInsetsOverlaySlot>[
          EdgeInsetsOverlaySlot.top,
          EdgeInsetsOverlaySlot.left,
        ],
        builder: (BuildContext context, EdgeInsets overlayPadding) => const SizedBox(),
      );

      widget.debugFillProperties(builder);

      final List<DiagnosticsNode> description = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(.info))
          .toList();

      expect(description.any((DiagnosticsNode n) => n.name == 'left' && n.value != null), isTrue);
      expect(description.any((DiagnosticsNode n) => n.name == 'top' && n.value != null), isTrue);
      expect(description.any((DiagnosticsNode n) => n.name == 'right' && n.value != null), isTrue);
      expect(description.any((DiagnosticsNode n) => n.name == 'bottom' && n.value != null), isTrue);
      expect(
        description.any(
          (DiagnosticsNode n) =>
              n.name == 'paintOrder' && n.value is Iterable<EdgeInsetsOverlaySlot>,
        ),
        isTrue,
      );
      expect(description.any((DiagnosticsNode n) => n.name == 'builder'), isTrue);
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
              child: const SizedBox(width: 50.0),
            ),
            top: GestureDetector(
              behavior: .opaque,
              onTap: () {
                topTapped = true;
              },
              child: const SizedBox(height: 50.0),
            ),
            builder: (BuildContext context, EdgeInsets overlayPadding) {
              return const SizedBox.expand();
            },
          ),
        );
      }

      // When left is painted first, top paints over left at overlapping corner (0, 0)
      await tester.pumpWidget(
        buildWithPaintOrder(const <EdgeInsetsOverlaySlot>[
          EdgeInsetsOverlaySlot.left,
          EdgeInsetsOverlaySlot.top,
        ]),
      );

      await tester.tapAt(const Offset(25.0, 25.0));
      expect(topTapped, isTrue);
      expect(leftTapped, isFalse);

      leftTapped = false;
      topTapped = false;

      // When top is painted first, left paints over top at overlapping corner (0, 0)
      await tester.pumpWidget(
        buildWithPaintOrder(const <EdgeInsetsOverlaySlot>[
          EdgeInsetsOverlaySlot.top,
          EdgeInsetsOverlaySlot.left,
        ]),
      );

      await tester.tapAt(const Offset(25.0, 25.0));
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
              child: const SizedBox(height: 60.0),
            ),
            builder: (BuildContext context, EdgeInsets overlayPadding) {
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
      await tester.pumpWidget(
        buildWithPaintOrder(const <EdgeInsetsOverlaySlot>[
          EdgeInsetsOverlaySlot.child,
          EdgeInsetsOverlaySlot.top,
        ]),
      );

      await tester.tapAt(const Offset(400.0, 30.0));
      expect(topTapped, isTrue);
      expect(childTapped, isFalse);

      topTapped = false;
      childTapped = false;

      // When top is painted first and child is painted last, child receives hit testing
      await tester.pumpWidget(
        buildWithPaintOrder(const <EdgeInsetsOverlaySlot>[
          EdgeInsetsOverlaySlot.top,
          EdgeInsetsOverlaySlot.child,
        ]),
      );

      await tester.tapAt(const Offset(400.0, 30.0));
      expect(childTapped, isTrue);
      expect(topTapped, isFalse);
    });
  });
}
