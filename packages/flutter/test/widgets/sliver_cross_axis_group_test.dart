// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const double VIEWPORT_HEIGHT = 600;
const double VIEWPORT_WIDTH = 300;

void main() {
  testWidgets('SliverCrossAxisGroup is laid out properly', (WidgetTester tester) async {
    final List<int> items = List<int>.generate(20, (int i) => i);
    final ScrollController controller = ScrollController();

    await tester.pumpWidget(_buildSliverCrossAxisGroup(
      controller: controller,
      slivers: <Widget>[
        _buildSliverList(itemMainAxisExtent: 300, items: items, label: (int item) => Text('Group 0 Tile $item')),
        _buildSliverList(itemMainAxisExtent: 200, items: items, label: (int item) => Text('Group 1 Tile $item')),
      ]),
    );
    await tester.pumpAndSettle();

    expect(controller.offset, 0);

    expect(find.text('Group 0 Tile 0'), findsOneWidget);
    expect(find.text('Group 0 Tile 1'), findsOneWidget);
    expect(find.text('Group 0 Tile 2'), findsNothing);

    expect(find.text('Group 1 Tile 0'), findsOneWidget);
    expect(find.text('Group 1 Tile 2'), findsOneWidget);
    expect(find.text('Group 1 Tile 3'), findsNothing);

    const double scrollOffset = 18 * 300.0;
    controller.jumpTo(scrollOffset);
    await tester.pumpAndSettle();

    expect(controller.offset, scrollOffset);
    expect(find.text('Group 0 Tile 17'), findsNothing);
    expect(find.text('Group 0 Tile 18'), findsOneWidget);
    expect(find.text('Group 0 Tile 19'), findsOneWidget);
    expect(find.text('Group 1 Tile 19'), findsNothing);

    final List<RenderSliverList> renderSlivers = tester.renderObjectList<RenderSliverList>(find.byType(SliverList)).toList();
    final RenderSliverList first = renderSlivers[0];
    final RenderSliverList second = renderSlivers[1];

    expect(first.constraints.crossAxisExtent, equals(VIEWPORT_WIDTH / 2));
    expect(second.constraints.crossAxisExtent, equals(VIEWPORT_WIDTH / 2));

    expect((first.parentData! as SliverPhysicalParentData).paintOffset.dx, equals(0));
    expect((second.parentData! as SliverPhysicalParentData).paintOffset.dx, equals(VIEWPORT_WIDTH / 2));

    final RenderSliverCrossAxisGroup renderGroup = tester.renderObject<RenderSliverCrossAxisGroup>(find.byType(SliverCrossAxisGroup));
    expect(renderGroup.geometry!.scrollExtent, equals(300 * 20));
  });

  testWidgets('SliverExpanded is laid out properly', (WidgetTester tester) async {
    final List<int> items = List<int>.generate(20, (int i) => i);
    await tester.pumpWidget(_buildSliverCrossAxisGroup(
      slivers: <Widget>[
        SliverCrossAxisExpanded(
          flex: 3,
          sliver: _buildSliverList(
            itemMainAxisExtent: 300,
            items: items,
            label: (int item) => Text('Group 0 Tile $item')
          ),
        ),
        SliverCrossAxisExpanded(
          flex: 2,
          sliver: _buildSliverList(
            itemMainAxisExtent: 200,
            items: items,
            label: (int item) => Text('Group 1 Tile $item')
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    final List<RenderSliverList> renderSlivers = tester.renderObjectList<RenderSliverList>(find.byType(SliverList)).toList();
    final RenderSliverList first = renderSlivers[0];
    final RenderSliverList second = renderSlivers[1];

    expect(first.constraints.crossAxisExtent, equals(3 * VIEWPORT_WIDTH / 5));
    expect(second.constraints.crossAxisExtent, equals(2 * VIEWPORT_WIDTH / 5));

    expect((first.parentData! as SliverPhysicalParentData).paintOffset.dx, equals(0));
    expect((second.parentData! as SliverPhysicalParentData).paintOffset.dx, equals(3 * VIEWPORT_WIDTH / 5));

    final RenderSliverCrossAxisGroup renderGroup = tester.renderObject<RenderSliverCrossAxisGroup>(find.byType(SliverCrossAxisGroup));
    expect(renderGroup.geometry!.scrollExtent, equals(300 * 20));
  });

  testWidgets('SliverConstrainedCrossAxis is laid out properly', (WidgetTester tester) async {
    final List<int> items = List<int>.generate(20, (int i) => i);
    await tester.pumpWidget(_buildSliverCrossAxisGroup(
      slivers: <Widget>[
        SliverConstrainedCrossAxis(maxExtent: 60, sliver: _buildSliverList(itemMainAxisExtent: 300, items: items, label: (int item) => Text('Group 0 Tile $item'))),
        SliverConstrainedCrossAxis(maxExtent: 120, sliver: _buildSliverList(itemMainAxisExtent: 200, items: items, label: (int item) => Text('Group 1 Tile $item'))),
      ]),
    );
    await tester.pumpAndSettle();

    final List<RenderSliverList> renderSlivers = tester.renderObjectList<RenderSliverList>(find.byType(SliverList)).toList();
    final RenderSliverList first = renderSlivers[0];
    final RenderSliverList second = renderSlivers[1];

    expect(first.constraints.crossAxisExtent, equals(60));
    expect(second.constraints.crossAxisExtent, equals(120));

    // Check that their parent SliverConstrainedCrossAxis have the correct paintOffsets.
    final List<RenderSliverConstrainedCrossAxis> renderSliversConstrained = tester.renderObjectList<RenderSliverConstrainedCrossAxis>(find.byType(SliverConstrainedCrossAxis)).toList();
    final RenderSliverConstrainedCrossAxis firstConstrained = renderSliversConstrained[0];
    final RenderSliverConstrainedCrossAxis secondConstrained = renderSliversConstrained[1];

    expect((firstConstrained.parentData! as SliverPhysicalParentData).paintOffset.dx, equals(0));
    expect((secondConstrained.parentData! as SliverPhysicalParentData).paintOffset.dx, equals(60));

    final RenderSliverCrossAxisGroup renderGroup = tester.renderObject<RenderSliverCrossAxisGroup>(find.byType(SliverCrossAxisGroup));
    expect(renderGroup.geometry!.scrollExtent, equals(300 * 20));
  });

  testWidgets('Mix of slivers is laid out properly', (WidgetTester tester) async {
    final List<int> items = List<int>.generate(20, (int i) => i);
    await tester.pumpWidget(_buildSliverCrossAxisGroup(
      slivers: <Widget>[
        SliverConstrainedCrossAxis(maxExtent: 30, sliver: _buildSliverList(itemMainAxisExtent: 300, items: items, label: (int item) => Text('Group 0 Tile $item'))),
        SliverCrossAxisExpanded(flex: 2, sliver: _buildSliverList(itemMainAxisExtent: 200, items: items, label: (int item) => Text('Group 1 Tile $item'))),
        _buildSliverList(itemMainAxisExtent: 200, items: items, label: (int item) => Text('Group 2 Tile $item')),
      ]),
    );
    await tester.pumpAndSettle();

    final List<RenderSliverList> renderSlivers = tester.renderObjectList<RenderSliverList>(find.byType(SliverList)).toList();
    final RenderSliverList first = renderSlivers[0];
    final RenderSliverList second = renderSlivers[1];
    final RenderSliverList third = renderSlivers[2];

    expect(first.constraints.crossAxisExtent, equals(30));
    expect(second.constraints.crossAxisExtent, equals(180));
    expect(third.constraints.crossAxisExtent, equals(90));

    // Check that paint offset for sliver children are correct as well.
    final RenderSliverCrossAxisGroup sliverCrossAxisRenderObject = tester.renderObject<RenderSliverCrossAxisGroup>(find.byType(SliverCrossAxisGroup));
    RenderSliver child = sliverCrossAxisRenderObject.firstChild!;
    expect((child.parentData! as SliverPhysicalParentData).paintOffset.dx, equals(0));
    child = sliverCrossAxisRenderObject.childAfter(child)!;
    expect((child.parentData! as SliverPhysicalParentData).paintOffset.dx, equals(30));
    child = sliverCrossAxisRenderObject.childAfter(child)!;
    expect((child.parentData! as SliverPhysicalParentData).paintOffset.dx, equals(210));

    final RenderSliverCrossAxisGroup renderGroup = tester.renderObject<RenderSliverCrossAxisGroup>(find.byType(SliverCrossAxisGroup));
    expect(renderGroup.geometry!.scrollExtent, equals(300 * 20));
  });

  testWidgets('Mix of slivers is laid out properly when horizontal', (WidgetTester tester) async {
    final List<int> items = List<int>.generate(20, (int i) => i);
    await tester.pumpWidget(_buildSliverCrossAxisGroup(
      scrollDirection: Axis.horizontal,
      slivers: <Widget>[
        SliverConstrainedCrossAxis(
          maxExtent: 30,
          sliver: _buildSliverList(
            scrollDirection: Axis.horizontal,
            itemMainAxisExtent: 300,
            items: items,
            label: (int item) => Text('Group 0 Tile $item')
            )
          ),
        SliverCrossAxisExpanded(
          flex: 2,
          sliver: _buildSliverList(
            scrollDirection: Axis.horizontal,
            itemMainAxisExtent: 200,
            items: items,
            label: (int item) => Text('Group 1 Tile $item')
          )
        ),
        _buildSliverList(
          scrollDirection: Axis.horizontal,
          itemMainAxisExtent: 200,
          items: items,
          label: (int item) => Text('Group 2 Tile $item')
        ),
      ]),
    );
    await tester.pumpAndSettle();

    final List<RenderSliverList> renderSlivers = tester.renderObjectList<RenderSliverList>(find.byType(SliverList)).toList();
    final RenderSliverList first = renderSlivers[0];
    final RenderSliverList second = renderSlivers[1];
    final RenderSliverList third = renderSlivers[2];

    expect(first.constraints.crossAxisExtent, equals(30));
    expect(second.constraints.crossAxisExtent, equals(380));
    expect(third.constraints.crossAxisExtent, equals(190));

    // Check that paint offset for sliver children are correct as well.
    final RenderSliverCrossAxisGroup sliverCrossAxisRenderObject = tester.renderObject<RenderSliverCrossAxisGroup>(find.byType(SliverCrossAxisGroup));
    RenderSliver child = sliverCrossAxisRenderObject.firstChild!;
    expect((child.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(0));
    child = sliverCrossAxisRenderObject.childAfter(child)!;
    expect((child.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(30));
    child = sliverCrossAxisRenderObject.childAfter(child)!;
    expect((child.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(410));

    final RenderSliverCrossAxisGroup renderGroup = tester.renderObject<RenderSliverCrossAxisGroup>(find.byType(SliverCrossAxisGroup));
    expect(renderGroup.geometry!.scrollExtent, equals(300 * 20));
  });

  testWidgets('Mix of slivers is laid out properly when reversed horizontal', (WidgetTester tester) async {
    final List<int> items = List<int>.generate(20, (int i) => i);
    await tester.pumpWidget(_buildSliverCrossAxisGroup(
      scrollDirection: Axis.horizontal,
      reverse: true,
      slivers: <Widget>[
        SliverConstrainedCrossAxis(
          maxExtent: 30,
          sliver: _buildSliverList(
            scrollDirection: Axis.horizontal,
            itemMainAxisExtent: 300,
            items: items,
            label: (int item) => Text('Group 0 Tile $item')
            )
          ),
        SliverCrossAxisExpanded(
          flex: 2,
          sliver: _buildSliverList(
            scrollDirection: Axis.horizontal,
            itemMainAxisExtent: 200,
            items: items,
            label: (int item) => Text('Group 1 Tile $item')
          )
        ),
        _buildSliverList(
          scrollDirection: Axis.horizontal,
          itemMainAxisExtent: 200,
          items: items,
          label: (int item) => Text('Group 2 Tile $item')
        ),
      ]),
    );
    await tester.pumpAndSettle();

    final List<RenderSliverList> renderSlivers = tester.renderObjectList<RenderSliverList>(find.byType(SliverList)).toList();
    final RenderSliverList first = renderSlivers[0];
    final RenderSliverList second = renderSlivers[1];
    final RenderSliverList third = renderSlivers[2];

    expect(first.constraints.crossAxisExtent, equals(30));
    expect(second.constraints.crossAxisExtent, equals(380));
    expect(third.constraints.crossAxisExtent, equals(190));

    // Check that paint offset for sliver children are correct as well.
    final RenderSliverCrossAxisGroup sliverCrossAxisRenderObject = tester.renderObject<RenderSliverCrossAxisGroup>(find.byType(SliverCrossAxisGroup));
    RenderSliver child = sliverCrossAxisRenderObject.firstChild!;
    expect((child.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(0));
    child = sliverCrossAxisRenderObject.childAfter(child)!;
    expect((child.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(30));
    child = sliverCrossAxisRenderObject.childAfter(child)!;
    expect((child.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(410));

    final RenderSliverCrossAxisGroup renderGroup = tester.renderObject<RenderSliverCrossAxisGroup>(find.byType(SliverCrossAxisGroup));
    expect(renderGroup.geometry!.scrollExtent, equals(300 * 20));
  });

  testWidgets('Mix of slivers is laid out properly when reversed vertical', (WidgetTester tester) async {
    final List<int> items = List<int>.generate(20, (int i) => i);
    await tester.pumpWidget(_buildSliverCrossAxisGroup(
      reverse: true,
      slivers: <Widget>[
        SliverConstrainedCrossAxis(
          maxExtent: 30,
          sliver: _buildSliverList(
            itemMainAxisExtent: 300,
            items: items,
            label: (int item) => Text('Group 0 Tile $item')
            )
          ),
        SliverCrossAxisExpanded(
          flex: 2,
          sliver: _buildSliverList(
            itemMainAxisExtent: 200,
            items: items,
            label: (int item) => Text('Group 1 Tile $item')
          )
        ),
        _buildSliverList(
          itemMainAxisExtent: 200,
          items: items,
          label: (int item) => Text('Group 2 Tile $item')
        ),
      ]),
    );
    await tester.pumpAndSettle();

    final List<RenderSliverList> renderSlivers = tester.renderObjectList<RenderSliverList>(find.byType(SliverList)).toList();
    final RenderSliverList first = renderSlivers[0];
    final RenderSliverList second = renderSlivers[1];
    final RenderSliverList third = renderSlivers[2];

    expect(first.constraints.crossAxisExtent, equals(30));
    expect(second.constraints.crossAxisExtent, equals(180));
    expect(third.constraints.crossAxisExtent, equals(90));

    // Check that paint offset for sliver children are correct as well.
    final RenderSliverCrossAxisGroup sliverCrossAxisRenderObject = tester.renderObject<RenderSliverCrossAxisGroup>(find.byType(SliverCrossAxisGroup));
    RenderSliver child = sliverCrossAxisRenderObject.firstChild!;
    expect((child.parentData! as SliverPhysicalParentData).paintOffset.dx, equals(0));
    child = sliverCrossAxisRenderObject.childAfter(child)!;
    expect((child.parentData! as SliverPhysicalParentData).paintOffset.dx, equals(30));
    child = sliverCrossAxisRenderObject.childAfter(child)!;
    expect((child.parentData! as SliverPhysicalParentData).paintOffset.dx, equals(210));

    final RenderSliverCrossAxisGroup renderGroup = tester.renderObject<RenderSliverCrossAxisGroup>(find.byType(SliverCrossAxisGroup));
    expect(renderGroup.geometry!.scrollExtent, equals(300 * 20));
  });

  testWidgets('Assertion error when SliverExpanded is used outside of SliverCrossAxisGroup', (WidgetTester tester) async {
    final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
    final Function(FlutterErrorDetails)? oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails error) => errors.add(error);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverCrossAxisExpanded(
                flex: 2,
                sliver: SliverToBoxAdapter(
                  child: Text('Hello World'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    FlutterError.onError = oldHandler;
    expect(errors, isNotEmpty);
    final AssertionError error = errors.first.exception as AssertionError;
    expect(
      error.toString(),
      contains('renderObject.parent is RenderSliverCrossAxisGroup'),
    );
  });

  testWidgets('Hit test works properly on various parts of SliverCrossAxisGroup', (WidgetTester tester) async {
    final List<int> items = List<int>.generate(20, (int i) => i);
    final ScrollController controller = ScrollController();

    String? clickedTile;

    int group = 0;
    int tile = 0;

    await tester.pumpWidget(_buildSliverCrossAxisGroup(
      controller: controller,
      slivers: <Widget>[
        _buildSliverList(
          itemMainAxisExtent: 300,
          items: items,
          label: (int item) => tile == item && group == 0
            ? TextButton(
              onPressed: () => clickedTile = 'Group 0 Tile $item',
              child: Text('Group 0 Tile $item'),
            )
            : Text('Group 0 Tile $item'),
        ),
        _buildSliverList(
          items: items,
          label: (int item) => tile == item && group == 1
            ? TextButton(
              onPressed: () => clickedTile = 'Group 1 Tile $item',
              child: Text('Group 1 Tile $item'),
            )
            : Text('Group 1 Tile $item'),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(clickedTile, equals('Group 0 Tile 0'));

    clickedTile = null;
    group = 1;
    tile = 2;
    await tester.pumpWidget(_buildSliverCrossAxisGroup(
      controller: controller,
      slivers: <Widget>[
        _buildSliverList(
          itemMainAxisExtent: 300,
          items: items,
          label: (int item) => tile == item && group == 0
            ? TextButton(
              onPressed: () => clickedTile = 'Group 0 Tile $item',
              child: Text('Group 0 Tile $item'),
            )
            : Text('Group 0 Tile $item'),
        ),
        _buildSliverList(
          items: items,
          label: (int item) => tile == item && group == 1
            ? TextButton(
              onPressed: () => clickedTile = 'Group 1 Tile $item',
              child: Text('Group 1 Tile $item'),
            )
            : Text('Group 1 Tile $item'),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(clickedTile, equals('Group 1 Tile 2'));
  });

   testWidgets('Constrained sliver takes up remaining space', (WidgetTester tester) async {
    final List<int> items = List<int>.generate(20, (int i) => i);
    await tester.pumpWidget(_buildSliverCrossAxisGroup(
      slivers: <Widget>[
        SliverConstrainedCrossAxis(maxExtent: 200, sliver: _buildSliverList(itemMainAxisExtent: 300, items: items, label: (int item) => Text('Group 0 Tile $item'))),
        SliverConstrainedCrossAxis(maxExtent: 200, sliver: _buildSliverList(itemMainAxisExtent: 200, items: items, label: (int item) => Text('Group 1 Tile $item'))),
      ]),
    );
    await tester.pumpAndSettle();

    final List<RenderSliverList> renderSlivers = tester.renderObjectList<RenderSliverList>(find.byType(SliverList)).toList();
    final RenderSliverList first = renderSlivers[0];
    final RenderSliverList second = renderSlivers[1];

    expect(first.constraints.crossAxisExtent, equals(200));
    expect(second.constraints.crossAxisExtent, equals(100));

    // Check that their parent SliverConstrainedCrossAxis have the correct paintOffsets.
    final List<RenderSliverConstrainedCrossAxis> renderSliversConstrained = tester.renderObjectList<RenderSliverConstrainedCrossAxis>(find.byType(SliverConstrainedCrossAxis)).toList();
    final RenderSliverConstrainedCrossAxis firstConstrained = renderSliversConstrained[0];
    final RenderSliverConstrainedCrossAxis secondConstrained = renderSliversConstrained[1];

    expect((firstConstrained.parentData! as SliverPhysicalParentData).paintOffset.dx, equals(0));
    expect((secondConstrained.parentData! as SliverPhysicalParentData).paintOffset.dx, equals(200));

    final RenderSliverCrossAxisGroup renderGroup = tester.renderObject<RenderSliverCrossAxisGroup>(find.byType(SliverCrossAxisGroup));
    expect(renderGroup.geometry!.scrollExtent, equals(300 * 20));
  });

  testWidgets('Assertion error when constrained widget runs out of cross axis extent', (WidgetTester tester) async {
    final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
    final Function(FlutterErrorDetails)? oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails error) => errors.add(error);

    final List<int> items = List<int>.generate(20, (int i) => i);
    await tester.pumpWidget(_buildSliverCrossAxisGroup(
      slivers: <Widget>[
        SliverConstrainedCrossAxis(maxExtent: 400, sliver: _buildSliverList(itemMainAxisExtent: 300, items: items, label: (int item) => Text('Group 0 Tile $item'))),
        SliverConstrainedCrossAxis(maxExtent: 200, sliver: _buildSliverList(itemMainAxisExtent: 200, items: items, label: (int item) => Text('Group 1 Tile $item'))),
      ]),
    );
    await tester.pumpAndSettle();
    FlutterError.onError = oldHandler;
    expect(errors, isNotEmpty);
    final AssertionError error = errors.first.exception as AssertionError;
    expect(
      error.toString(),
      contains('SliverCrossAxisGroup ran out of extent before child could be laid out.'),
    );
  });

  testWidgets('Assertion error when expanded widget runs out of cross axis extent', (WidgetTester tester) async {
    final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
    final Function(FlutterErrorDetails)? oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails error) => errors.add(error);

    final List<int> items = List<int>.generate(20, (int i) => i);
    await tester.pumpWidget(_buildSliverCrossAxisGroup(
      slivers: <Widget>[
        SliverConstrainedCrossAxis(maxExtent: 200, sliver: _buildSliverList(itemMainAxisExtent: 300, items: items, label: (int item) => Text('Group 0 Tile $item'))),
        SliverConstrainedCrossAxis(maxExtent: 100, sliver: _buildSliverList(itemMainAxisExtent: 200, items: items, label: (int item) => Text('Group 1 Tile $item'))),
       _buildSliverList(itemMainAxisExtent: 200, items: items, label: (int item) => Text('Group 2 Tile $item')),
      ]),
    );
    await tester.pumpAndSettle();
    FlutterError.onError = oldHandler;
    expect(errors, isNotEmpty);
    final AssertionError error = errors.first.exception as AssertionError;
    expect(
      error.toString(),
      contains('SliverCrossAxisGroup ran out of extent before child could be laid out.'),
    );
  });

  testWidgets('applyPaintTransform is implemented properly', (WidgetTester tester) async {
    await tester.pumpWidget(_buildSliverCrossAxisGroup(
      slivers: <Widget>[
        const SliverToBoxAdapter(child: Text('first box')),
        const SliverToBoxAdapter(child: Text('second box')),
      ]),
    );
    await tester.pumpAndSettle();

    // localToGlobal calculates offset via applyPaintTransform
    final RenderBox first = tester.renderObject(find.text('first box'));
    final RenderBox second = tester.renderObject(find.text('second box'));
    expect(first.localToGlobal(Offset.zero), Offset.zero);
    expect(second.localToGlobal(Offset.zero), const Offset(VIEWPORT_WIDTH / 2, 0));
  });
}

Widget _buildSliverList({
  double itemMainAxisExtent = 100,
  List<int> items = const <int>[],
  required Widget Function(int) label,
  Axis scrollDirection = Axis.vertical,
}) {
  return SliverList(
    delegate: SliverChildBuilderDelegate(
      (BuildContext context, int i) {
        return scrollDirection == Axis.vertical
          ? SizedBox(
            key: ValueKey<int>(items[i]),
            height: itemMainAxisExtent,
            child: label(items[i]),
          )
          : SizedBox(
            key: ValueKey<int>(items[i]),
            width: itemMainAxisExtent,
            child: label(items[i]));
      },
      findChildIndexCallback: (Key key) {
        final ValueKey<int> valueKey = key as ValueKey<int>;
        final int index = items.indexOf(valueKey.value);
        return index == -1 ? null : index;
      },
      childCount: items.length,
    ),
  );
}

Widget _buildSliverCrossAxisGroup({
  required List<Widget> slivers,
  ScrollController? controller,
  double viewportHeight = VIEWPORT_HEIGHT,
  double viewportWidth = VIEWPORT_WIDTH,
  Axis scrollDirection = Axis.vertical,
  bool reverse = false,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        height: viewportHeight,
        width: viewportWidth,
        child: CustomScrollView(
          scrollDirection: scrollDirection,
          reverse: reverse,
          controller: controller,
          slivers: <Widget>[SliverCrossAxisGroup(slivers: slivers)],
        ),
      ),
    ),
  );
}
