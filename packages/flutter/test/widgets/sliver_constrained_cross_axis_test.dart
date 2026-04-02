// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const double VIEWPORT_HEIGHT = 500;
const double VIEWPORT_WIDTH = 300;

void main() {
  testWidgets('SliverConstrainedCrossAxis basic test', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildSliverConstrainedCrossAxis(maxExtent: 50, textDirection: TextDirection.ltr),
    );

    final RenderBox box = tester.renderObject<RenderBox>(find.byType(Container));
    expect(box.size.height, 100);
    expect(box.size.width, 50);

    final RenderSliver sliver = tester.renderObject<RenderSliver>(find.byType(SliverToBoxAdapter));
    expect(sliver.geometry!.paintExtent, equals(100));
  });

  testWidgets('SliverConstrainedCrossAxis updates correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildSliverConstrainedCrossAxis(maxExtent: 50, textDirection: TextDirection.ltr),
    );

    final RenderBox box1 = tester.renderObject<RenderBox>(find.byType(Container));
    expect(box1.size.height, 100);
    expect(box1.size.width, 50);

    await tester.pumpWidget(
      _buildSliverConstrainedCrossAxis(maxExtent: 80, textDirection: TextDirection.ltr),
    );

    final RenderBox box2 = tester.renderObject<RenderBox>(find.byType(Container));
    expect(box2.size.height, 100);
    expect(box2.size.width, 80);
  });

  testWidgets('SliverConstrainedCrossAxis uses parent extent if maxExtent is greater', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildSliverConstrainedCrossAxis(maxExtent: 400, textDirection: TextDirection.ltr),
    );

    final RenderBox box = tester.renderObject<RenderBox>(find.byType(Container));
    expect(box.size.height, 100);
    expect(box.size.width, VIEWPORT_WIDTH);
  });

  testWidgets('SliverConstrainedCrossAxis constrains the height when direction is horizontal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildSliverConstrainedCrossAxis(
        maxExtent: 50,
        textDirection: TextDirection.ltr,
        scrollDirection: Axis.horizontal,
      ),
    );

    final RenderBox box = tester.renderObject<RenderBox>(find.byType(Container));
    expect(box.size.height, 50);
  });

  testWidgets('SliverConstrainedCrossAxis sets its own flex to 0', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildSliverConstrainedCrossAxis(maxExtent: 50, textDirection: TextDirection.ltr),
    );

    final RenderSliver sliver = tester.renderObject<RenderSliver>(
      find.byType(SliverConstrainedCrossAxis),
    );
    expect((sliver.parentData! as SliverPhysicalParentData).crossAxisFlex, equals(0));
  });

  testWidgets('SliverConstrainedCrossAxis defaults to zero alignment', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildSliverConstrainedCrossAxis(maxExtent: 50, textDirection: TextDirection.ltr),
    );

    final RenderBox box = tester.renderObject<RenderBox>(find.byType(Container));
    expect(box.size.width, 50);
    final Offset scrollViewOffset = tester.getTopLeft(find.byType(CustomScrollView));
    expect(tester.getTopLeft(find.byType(Container)), scrollViewOffset);
  });

  testWidgets('SliverConstrainedCrossAxis center alignment', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildSliverConstrainedCrossAxis(
        maxExtent: 100,
        textDirection: TextDirection.ltr,
        alignment: Alignment.center,
      ),
    );

    final RenderBox box = tester.renderObject<RenderBox>(find.byType(Container));
    expect(box.size.width, 100);
    final Offset scrollViewOffset = tester.getTopLeft(find.byType(CustomScrollView));
    // (300 - 100) / 2 = 100
    expect(tester.getTopLeft(find.byType(Container)), scrollViewOffset + const Offset(100, 0));
  });

  testWidgets('SliverConstrainedCrossAxis end alignment', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildSliverConstrainedCrossAxis(
        maxExtent: 100,
        textDirection: TextDirection.ltr,
        alignment: Alignment.centerRight,
      ),
    );

    final RenderBox box = tester.renderObject<RenderBox>(find.byType(Container));
    expect(box.size.width, 100);
    final Offset scrollViewOffset = tester.getTopLeft(find.byType(CustomScrollView));
    // 300 - 100 = 200
    expect(tester.getTopLeft(find.byType(Container)), scrollViewOffset + const Offset(200, 0));
  });

  testWidgets('SliverConstrainedCrossAxis directional alignment LTR', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildSliverConstrainedCrossAxis(
        maxExtent: 100,
        textDirection: TextDirection.ltr,
        alignment: AlignmentDirectional.centerEnd,
      ),
    );

    final RenderBox box = tester.renderObject<RenderBox>(find.byType(Container));
    expect(box.size.width, 100);
    final Offset scrollViewOffset = tester.getTopLeft(find.byType(CustomScrollView));
    // Start is left, end is right. 300 - 100 = 200
    expect(tester.getTopLeft(find.byType(Container)), scrollViewOffset + const Offset(200, 0));
  });

  testWidgets('SliverConstrainedCrossAxis directional alignment RTL', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildSliverConstrainedCrossAxis(
        maxExtent: 100,
        alignment: AlignmentDirectional.centerEnd,
        textDirection: TextDirection.rtl,
      ),
    );

    final RenderBox box = tester.renderObject<RenderBox>(find.byType(Container));
    expect(box.size.width, 100);
    final Offset scrollViewOffset = tester.getTopLeft(find.byType(CustomScrollView));
    // End is visual left (0).
    expect(tester.getTopLeft(find.byType(Container)), scrollViewOffset + Offset.zero);
  });

  testWidgets('SliverConstrainedCrossAxis horizontal scroll alignment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildSliverConstrainedCrossAxis(
        maxExtent: 100,
        textDirection: TextDirection.ltr,
        alignment: Alignment.bottomCenter,
        scrollDirection: Axis.horizontal,
      ),
    );

    final RenderBox box = tester.renderObject<RenderBox>(find.byType(Container));
    // In horizontal scroll, cross axis is vertical. VIEWPORT_HEIGHT = 500.
    expect(box.size.height, 100);
    final Offset scrollViewOffset = tester.getTopLeft(find.byType(CustomScrollView));
    // (500 - 100) / 1.0 = 400. Bottom is 1.0.
    expect(tester.getTopLeft(find.byType(Container)), scrollViewOffset + const Offset(0, 400));
  });

  testWidgets('SliverConstrainedCrossAxis does not require TextDirection for non-directional alignment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverConstrainedCrossAxis(
              maxExtent: 100,
              alignment: Alignment.center,
              sliver: SliverToBoxAdapter(child: SizedBox(height: 100, width: 100)),
            ),
          ],
        ),
      ),
    );

    final RenderBox box = tester.renderObject<RenderBox>(find.byType(SizedBox));
    expect(box.size.width, 100);
    final Offset scrollViewOffset = tester.getTopLeft(find.byType(CustomScrollView));
    // Default test viewport is 800x600. (800 - 100) / 2 = 350
    expect(tester.getTopLeft(find.byType(SizedBox)), scrollViewOffset + const Offset(350, 0));
  });

  testWidgets('SliverConstrainedCrossAxis hit testing', (WidgetTester tester) async {
    var tapCount = 0;
    await tester.pumpWidget(
      _buildSliverConstrainedCrossAxis(
        maxExtent: 100,
        textDirection: TextDirection.ltr,
        alignment: Alignment.center,
        onTap: () => tapCount++,
      ),
    );

    final Offset scrollViewOffset = tester.getTopLeft(find.byType(CustomScrollView));

    // Tap at center (visual 150, 50). Child is at [100, 200] in X.
    await tester.tapAt(scrollViewOffset + const Offset(150, 50));
    expect(tapCount, 1);

    // Tap at visual left (50, 50). Should NOT hit child.
    await tester.tapAt(scrollViewOffset + const Offset(50, 50));
    expect(tapCount, 1);

    // Tap at visual right (250, 50). Should NOT hit child.
    await tester.tapAt(scrollViewOffset + const Offset(250, 50));
    expect(tapCount, 1);
  });

  testWidgets(
    'SliverConstrainedCrossAxis asserts during layout when alignment requires TextDirection but none is provided',
    (WidgetTester tester) async {
      final List<Object> exceptions = <Object>[];
      final void Function(FlutterErrorDetails) oldHandler = FlutterError.onError!;
      FlutterError.onError = (FlutterErrorDetails details) {
        exceptions.add(details.exception);
      };

      try {
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: <Widget>[
                _TestSliverConstrainedCrossAxis(
                  maxExtent: 100,
                  alignment: AlignmentDirectional.centerEnd,
                  sliver: SliverToBoxAdapter(child: SizedBox(height: 100, width: 100)),
                ),
              ],
            ),
          ),
        );
      } finally {
        FlutterError.onError = oldHandler;
      }

      expect(exceptions, isNotEmpty);
      expect(exceptions.first, isA<AssertionError>());
    },
  );

  testWidgets('RenderSliverConstrainedCrossAxis constructor asserts on negative maxExtent', (
    WidgetTester tester,
  ) async {
    expect(() => RenderSliverConstrainedCrossAxis(maxExtent: -1.0), throwsAssertionError);
  });
}

class _TestSliverConstrainedCrossAxis extends SingleChildRenderObjectWidget {
  const _TestSliverConstrainedCrossAxis({
    required this.maxExtent,
    this.alignment,
    required Widget sliver,
  }) : super(child: sliver);

  final double maxExtent;
  final AlignmentGeometry? alignment;

  @override
  RenderSliverConstrainedCrossAxis createRenderObject(BuildContext context) {
    return RenderSliverConstrainedCrossAxis(maxExtent: maxExtent, alignment: alignment);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverConstrainedCrossAxis renderObject) {
    renderObject
      ..maxExtent = maxExtent
      ..alignment = alignment;
  }
}

Widget _buildSliverConstrainedCrossAxis({
  required double maxExtent,
  AlignmentGeometry? alignment,
  TextDirection? textDirection,
  Axis scrollDirection = Axis.vertical,
  VoidCallback? onTap,
}) {
  final Widget result = CustomScrollView(
    scrollDirection: scrollDirection,
    slivers: <Widget>[
      SliverConstrainedCrossAxis(
        maxExtent: maxExtent,
        alignment: alignment,
        sliver: SliverToBoxAdapter(
          child: GestureDetector(
            onTap: onTap,
            child: scrollDirection == Axis.vertical
                ? Container(height: 100, color: const Color(0xFF0000FF))
                : Container(width: 100, color: const Color(0xFF0000FF)),
          ),
        ),
      ),
    ],
  );

  final Widget sizedResult = Center(
    child: SizedBox(
      width: VIEWPORT_WIDTH,
      height: VIEWPORT_HEIGHT,
      child: result,
    ),
  );

  if (textDirection == null) {
    return sizedResult;
  }

  return Directionality(
    textDirection: textDirection,
    child: sizedResult,
  );
}
