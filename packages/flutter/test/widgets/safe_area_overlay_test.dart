// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SafeAreaOverlay', () {
    testWidgets('passes through when no sides are provided', (WidgetTester tester) async {
      EdgeInsets? observedPadding;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: MediaQuery(
            data: const MediaQueryData(padding: .all(20.0)),
            child: SafeAreaOverlay(
              child: Builder(
                builder: (BuildContext context) {
                  observedPadding = MediaQuery.paddingOf(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );

      expect(observedPadding, const EdgeInsets.all(20.0));
    });

    testWidgets('calculates safe area padding with top and bottom side widgets', (
      WidgetTester tester,
    ) async {
      EdgeInsets? observedPadding;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: MediaQuery(
            data: const MediaQueryData(padding: .all(20.0)),
            child: SafeAreaOverlay(
              top: const SizedBox(height: 60.0),
              bottom: const SizedBox(height: 80.0),
              child: Builder(
                builder: (BuildContext context) {
                  observedPadding = MediaQuery.paddingOf(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );

      expect(observedPadding, const EdgeInsets.fromLTRB(20.0, 60.0, 20.0, 80.0));
      expect(
        tester.getRect(find.byType(SizedBox).at(1)),
        const Rect.fromLTWH(0.0, 0.0, 800.0, 60.0),
      );
      expect(
        tester.getRect(find.byType(SizedBox).at(2)),
        const Rect.fromLTWH(0.0, 520.0, 800.0, 80.0),
      );
    });

    testWidgets('calculates safe area padding with all 4 sides', (WidgetTester tester) async {
      EdgeInsets? observedPadding;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: MediaQuery(
            data: const MediaQueryData(padding: .all(10.0)),
            child: SafeAreaOverlay(
              left: const SizedBox(width: 40.0),
              top: const SizedBox(height: 50.0),
              right: const SizedBox(width: 60.0),
              bottom: const SizedBox(height: 70.0),
              child: Builder(
                builder: (BuildContext context) {
                  observedPadding = MediaQuery.paddingOf(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );

      expect(observedPadding, const EdgeInsets.fromLTRB(40.0, 50.0, 60.0, 70.0));
      expect(
        tester.getRect(find.byType(SizedBox).at(1)),
        const Rect.fromLTWH(0.0, 0.0, 40.0, 600.0),
      );
      expect(
        tester.getRect(find.byType(SizedBox).at(2)),
        const Rect.fromLTWH(0.0, 0.0, 800.0, 50.0),
      );
      expect(
        tester.getRect(find.byType(SizedBox).at(3)),
        const Rect.fromLTWH(740.0, 0.0, 60.0, 600.0),
      );
      expect(
        tester.getRect(find.byType(SizedBox).at(4)),
        const Rect.fromLTWH(0.0, 530.0, 800.0, 70.0),
      );
    });

    testWidgets('works seamlessly with nested SafeArea inside child', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: .ltr,
          child: MediaQuery(
            data: .new(),
            child: SafeAreaOverlay(
              top: SizedBox(height: 50.0),
              child: SafeArea(child: Placeholder()),
            ),
          ),
        ),
      );

      expect(
        tester.getRect(find.byType(Placeholder)),
        const Rect.fromLTWH(0.0, 50.0, 800.0, 550.0),
      );
    });

    testWidgets('hit testing order prioritizes side widgets over child', (
      WidgetTester tester,
    ) async {
      var childTapped = false;
      var topTapped = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: MediaQuery(
            data: const .new(),
            child: SafeAreaOverlay(
              top: GestureDetector(
                behavior: .opaque,
                onTap: () {
                  topTapped = true;
                },
                child: const SizedBox(height: 60.0),
              ),
              child: GestureDetector(
                behavior: .opaque,
                onTap: () {
                  childTapped = true;
                },
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(const .new(400.0, 30.0));
      expect(topTapped, isTrue);
      expect(childTapped, isFalse);

      await tester.tapAt(const .new(400.0, 200.0));
      expect(childTapped, isTrue);
    });

    testWidgets('updates padding dynamically on rebuild', (WidgetTester tester) async {
      EdgeInsets? observedPadding;

      Widget buildWidget({required double topHeight}) {
        return Directionality(
          textDirection: .ltr,
          child: MediaQuery(
            data: const .new(padding: .all(10.0)),
            child: SafeAreaOverlay(
              top: SizedBox(height: topHeight),
              child: Builder(
                builder: (BuildContext context) {
                  observedPadding = MediaQuery.paddingOf(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildWidget(topHeight: 50.0));
      expect(observedPadding, const EdgeInsets.fromLTRB(10.0, 50.0, 10.0, 10.0));

      await tester.pumpWidget(buildWidget(topHeight: 90.0));
      expect(observedPadding, const EdgeInsets.fromLTRB(10.0, 90.0, 10.0, 10.0));
    });

    testWidgets('removes opposite side padding for each overlay widget', (
      WidgetTester tester,
    ) async {
      EdgeInsets? leftObservedPadding;
      EdgeInsets? topObservedPadding;
      EdgeInsets? rightObservedPadding;
      EdgeInsets? bottomObservedPadding;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: MediaQuery(
            data: const .new(padding: .fromLTRB(10.0, 20.0, 30.0, 40.0)),
            child: SafeAreaOverlay(
              left: Builder(
                builder: (BuildContext context) {
                  leftObservedPadding = MediaQuery.paddingOf(context);
                  return const SizedBox(width: 50.0);
                },
              ),
              top: Builder(
                builder: (BuildContext context) {
                  topObservedPadding = MediaQuery.paddingOf(context);
                  return const SizedBox(height: 50.0);
                },
              ),
              right: Builder(
                builder: (BuildContext context) {
                  rightObservedPadding = MediaQuery.paddingOf(context);
                  return const SizedBox(width: 50.0);
                },
              ),
              bottom: Builder(
                builder: (BuildContext context) {
                  bottomObservedPadding = MediaQuery.paddingOf(context);
                  return const SizedBox(height: 50.0);
                },
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      // left widget has removeRight: true
      expect(leftObservedPadding, const EdgeInsets.fromLTRB(10.0, 20.0, 0.0, 40.0));
      // top widget has removeBottom: true
      expect(topObservedPadding, const EdgeInsets.fromLTRB(10.0, 20.0, 30.0, 0.0));
      // right widget has removeLeft: true
      expect(rightObservedPadding, const EdgeInsets.fromLTRB(0.0, 20.0, 30.0, 40.0));
      // bottom widget has removeTop: true
      expect(bottomObservedPadding, const EdgeInsets.fromLTRB(10.0, 0.0, 30.0, 40.0));
    });

    testWidgets('debugFillProperties exports diagnostic properties', (WidgetTester tester) async {
      final builder = DiagnosticPropertiesBuilder();
      const widget = SafeAreaOverlay(
        left: SizedBox(width: 40.0),
        top: SizedBox(height: 50.0),
        right: SizedBox(width: 60.0),
        bottom: SizedBox(height: 70.0),
        paintOrder: <SafeAreaOverlaySide>[SafeAreaOverlaySide.top, SafeAreaOverlaySide.left],
        child: SizedBox(),
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
          (DiagnosticsNode n) => n.name == 'paintOrder' && n.value is Iterable<SafeAreaOverlaySide>,
        ),
        isTrue,
      );
    });

    testWidgets('paintOrder determines overlay rendering and hit testing priority', (
      WidgetTester tester,
    ) async {
      var leftTapped = false;
      var topTapped = false;

      Widget buildWithPaintOrder(List<SafeAreaOverlaySide> paintOrder) {
        return Directionality(
          textDirection: .ltr,
          child: MediaQuery(
            data: const .new(),
            child: SafeAreaOverlay(
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
              child: const SizedBox.expand(),
            ),
          ),
        );
      }

      // When left is painted first, top paints over left at overlapping corner (0, 0)
      await tester.pumpWidget(
        buildWithPaintOrder(const <SafeAreaOverlaySide>[
          SafeAreaOverlaySide.left,
          SafeAreaOverlaySide.top,
        ]),
      );

      await tester.tapAt(const Offset(25.0, 25.0));
      expect(topTapped, isTrue);
      expect(leftTapped, isFalse);

      leftTapped = false;
      topTapped = false;

      // When top is painted first, left paints over top at overlapping corner (0, 0)
      await tester.pumpWidget(
        buildWithPaintOrder(const <SafeAreaOverlaySide>[
          SafeAreaOverlaySide.top,
          SafeAreaOverlaySide.left,
        ]),
      );

      await tester.tapAt(const Offset(25.0, 25.0));
      expect(leftTapped, isTrue);
      expect(topTapped, isFalse);
    });
  });
}
