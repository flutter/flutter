// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/sliver_utils.dart';
import 'semantics_tester.dart';

const double VIEWPORT_HEIGHT = 600;
const double VIEWPORT_WIDTH = 300;

void main() {
  testWidgets('SliverMainAxisGroup is laid out properly', (WidgetTester tester) async {
    final items = List<int>.generate(20, (int i) => i);
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        controller: controller,
        slivers: <Widget>[
          _buildSliverList(
            itemMainAxisExtent: 300,
            items: items,
            label: (int item) => Text('Group 0 Tile $item'),
          ),
          _buildSliverList(
            itemMainAxisExtent: 200,
            items: items,
            label: (int item) => Text('Group 1 Tile $item'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.offset, 0);

    expect(find.text('Group 0 Tile 0'), findsOneWidget);
    expect(
      tester.getRect(find.text('Group 0 Tile 0')),
      const Rect.fromLTRB(0.0, 0.0, 300.0, 300.0),
    );
    expect(find.text('Group 0 Tile 1'), findsOneWidget);
    expect(
      tester.getRect(find.text('Group 0 Tile 1')),
      const Rect.fromLTRB(0.0, 300.0, 300.0, 600.0),
    );
    expect(find.text('Group 0 Tile 2'), findsNothing);
    expect(find.text('Group 1 Tile 0'), findsNothing);

    const double scrollOffset = 19 * 300.0;
    controller.jumpTo(scrollOffset);
    await tester.pumpAndSettle();

    expect(controller.offset, scrollOffset);
    expect(find.text('Group 0 Tile 18'), findsNothing);
    expect(find.text('Group 0 Tile 19'), findsOneWidget);
    expect(
      tester.getRect(find.text('Group 0 Tile 19')),
      const Rect.fromLTRB(0.0, 0.0, 300.0, 300.0),
    );
    expect(find.text('Group 1 Tile 0'), findsOneWidget);
    expect(
      tester.getRect(find.text('Group 1 Tile 0')),
      const Rect.fromLTRB(0.0, 300.0, 300.0, 500.0),
    );

    final List<RenderSliverList> renderSlivers = tester
        .renderObjectList<RenderSliverList>(find.byType(SliverList))
        .toList();
    final RenderSliverList first = renderSlivers[0];
    final RenderSliverList second = renderSlivers[1];

    expect(first.geometry!.layoutExtent, equals(300.0));
    expect(second.geometry!.layoutExtent, equals(300.0));
    expect(first.geometry!.scrollExtent, equals(20 * 300.0));
    expect(second.geometry!.scrollExtent, equals(20 * 200.0));

    expect((first.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(0.0));
    expect(first.constraints.scrollOffset, equals(19 * 300.0));
    expect((second.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(1 * 300.0));

    final RenderSliverMainAxisGroup renderGroup = tester.renderObject<RenderSliverMainAxisGroup>(
      find.byType(SliverMainAxisGroup),
    );
    expect(renderGroup.geometry!.scrollExtent, equals(300 * 20 + 200 * 20));
    expect(renderGroup.geometry!.hasVisualOverflow, isTrue);
  });

  testWidgets('SliverMainAxisGroup is laid out properly when reversed', (
    WidgetTester tester,
  ) async {
    final items = List<int>.generate(20, (int i) => i);
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        controller: controller,
        reverse: true,
        slivers: <Widget>[
          _buildSliverList(
            itemMainAxisExtent: 300,
            items: items,
            label: (int item) => Text('Group 0 Tile $item'),
          ),
          _buildSliverList(
            itemMainAxisExtent: 200,
            items: items,
            label: (int item) => Text('Group 1 Tile $item'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.offset, 0);

    expect(find.text('Group 0 Tile 0'), findsOneWidget);
    expect(
      tester.getRect(find.text('Group 0 Tile 0')),
      const Rect.fromLTRB(0.0, 300.0, 300.0, 600.0),
    );
    expect(find.text('Group 0 Tile 1'), findsOneWidget);
    expect(
      tester.getRect(find.text('Group 0 Tile 1')),
      const Rect.fromLTRB(0.0, 0.0, 300.0, 300.0),
    );
    expect(find.text('Group 0 Tile 2'), findsNothing);
    expect(find.text('Group 1 Tile 0'), findsNothing);

    const double scrollOffset = 19 * 300.0;
    controller.jumpTo(scrollOffset);
    await tester.pumpAndSettle();

    expect(controller.offset, scrollOffset);
    expect(find.text('Group 0 Tile 18'), findsNothing);
    expect(find.text('Group 0 Tile 19'), findsOneWidget);
    expect(
      tester.getRect(find.text('Group 0 Tile 19')),
      const Rect.fromLTRB(0.0, 300.0, 300.0, 600.0),
    );
    expect(find.text('Group 1 Tile 0'), findsOneWidget);
    expect(
      tester.getRect(find.text('Group 1 Tile 0')),
      const Rect.fromLTRB(0.0, 100.0, 300.0, 300.0),
    );

    final List<RenderSliverList> renderSlivers = tester
        .renderObjectList<RenderSliverList>(find.byType(SliverList))
        .toList();
    final RenderSliverList first = renderSlivers[0];
    final RenderSliverList second = renderSlivers[1];

    expect(first.geometry!.layoutExtent, equals(300.0));
    expect(second.geometry!.layoutExtent, equals(300.0));
    expect(first.geometry!.scrollExtent, equals(20 * 300.0));
    expect(second.geometry!.scrollExtent, equals(20 * 200.0));

    expect((first.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(300.0));
    expect(first.constraints.scrollOffset, equals(19 * 300.0));
    expect((second.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(0.0));

    final RenderSliverMainAxisGroup renderGroup = tester.renderObject<RenderSliverMainAxisGroup>(
      find.byType(SliverMainAxisGroup),
    );
    expect(renderGroup.geometry!.scrollExtent, equals(300 * 20 + 200 * 20));
    expect(renderGroup.geometry!.hasVisualOverflow, isTrue);
  });

  testWidgets('SliverMainAxisGroup is laid out properly when horizontal', (
    WidgetTester tester,
  ) async {
    final items = List<int>.generate(20, (int i) => i);
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        controller: controller,
        scrollDirection: Axis.horizontal,
        slivers: <Widget>[
          _buildSliverList(
            itemMainAxisExtent: 300,
            items: items,
            label: (int item) => Text('Group 0 Tile $item'),
            scrollDirection: Axis.horizontal,
          ),
          _buildSliverList(
            itemMainAxisExtent: 200,
            items: items,
            label: (int item) => Text('Group 1 Tile $item'),
            scrollDirection: Axis.horizontal,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.offset, 0);

    expect(find.text('Group 0 Tile 0'), findsOneWidget);
    expect(
      tester.getRect(find.text('Group 0 Tile 0')),
      const Rect.fromLTRB(0.0, 0.0, 300.0, 600.0),
    );
    expect(find.text('Group 0 Tile 1'), findsNothing);
    expect(find.text('Group 1 Tile 0'), findsNothing);

    const double scrollOffset = 19 * 300.0;
    controller.jumpTo(scrollOffset);
    await tester.pumpAndSettle();

    expect(controller.offset, scrollOffset);
    expect(find.text('Group 0 Tile 18'), findsNothing);
    expect(find.text('Group 0 Tile 19'), findsOneWidget);
    expect(
      tester.getRect(find.text('Group 0 Tile 19')),
      const Rect.fromLTRB(0.0, 0.0, 300.0, 600.0),
    );
    expect(find.text('Group 1 Tile 0'), findsNothing);

    const double scrollOffset2 = 20 * 300.0;
    controller.jumpTo(scrollOffset2);
    await tester.pumpAndSettle();
    expect(find.text('Group 0 Tile 19'), findsNothing);
    expect(find.text('Group 1 Tile 0'), findsOneWidget);
    expect(
      tester.getRect(find.text('Group 1 Tile 0')),
      const Rect.fromLTRB(0.0, 0.0, 200.0, 600.0),
    );

    final List<RenderSliverList> renderSlivers = tester
        .renderObjectList<RenderSliverList>(find.byType(SliverList, skipOffstage: false))
        .toList();
    final RenderSliverList first = renderSlivers[0];
    final RenderSliverList second = renderSlivers[1];

    expect(first.geometry!.layoutExtent, equals(0.0));
    expect(second.geometry!.layoutExtent, equals(300.0));
    expect(first.geometry!.scrollExtent, equals(20 * 300.0));
    expect(second.geometry!.scrollExtent, equals(20 * 200.0));

    expect((first.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(0.0));
    expect(first.constraints.scrollOffset, equals(20 * 300.0));
    expect((second.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(0.0));

    final RenderSliverMainAxisGroup renderGroup = tester.renderObject<RenderSliverMainAxisGroup>(
      find.byType(SliverMainAxisGroup),
    );
    expect(renderGroup.geometry!.scrollExtent, equals(300 * 20 + 200 * 20));
    expect(renderGroup.geometry!.hasVisualOverflow, isTrue);
  });

  testWidgets('SliverMainAxisGroup is laid out properly when horizontal, reversed', (
    WidgetTester tester,
  ) async {
    final items = List<int>.generate(20, (int i) => i);
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        controller: controller,
        scrollDirection: Axis.horizontal,
        reverse: true,
        slivers: <Widget>[
          _buildSliverList(
            itemMainAxisExtent: 300,
            items: items,
            label: (int item) => Text('Group 0 Tile $item'),
            scrollDirection: Axis.horizontal,
          ),
          _buildSliverList(
            itemMainAxisExtent: 200,
            items: items,
            label: (int item) => Text('Group 1 Tile $item'),
            scrollDirection: Axis.horizontal,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.offset, 0);

    expect(find.text('Group 0 Tile 0'), findsOneWidget);
    expect(
      tester.getRect(find.text('Group 0 Tile 0')),
      const Rect.fromLTRB(0.0, 0.0, 300.0, 600.0),
    );
    expect(find.text('Group 0 Tile 1'), findsNothing);
    expect(find.text('Group 1 Tile 0'), findsNothing);

    const double scrollOffset = 19 * 300.0;
    controller.jumpTo(scrollOffset);
    await tester.pumpAndSettle();

    expect(controller.offset, scrollOffset);
    expect(find.text('Group 0 Tile 18'), findsNothing);
    expect(find.text('Group 0 Tile 19'), findsOneWidget);
    expect(
      tester.getRect(find.text('Group 0 Tile 19')),
      const Rect.fromLTRB(0.0, 0.0, 300.0, 600.0),
    );
    expect(find.text('Group 1 Tile 0'), findsNothing);

    const double scrollOffset2 = 20 * 300.0;
    controller.jumpTo(scrollOffset2);
    await tester.pumpAndSettle();
    expect(find.text('Group 0 Tile 19'), findsNothing);
    expect(find.text('Group 1 Tile 0'), findsOneWidget);
    expect(
      tester.getRect(find.text('Group 1 Tile 0')),
      const Rect.fromLTRB(100.0, 0.0, 300.0, 600.0),
    );

    final List<RenderSliverList> renderSlivers = tester
        .renderObjectList<RenderSliverList>(find.byType(SliverList, skipOffstage: false))
        .toList();
    final RenderSliverList first = renderSlivers[0];
    final RenderSliverList second = renderSlivers[1];

    expect(first.geometry!.layoutExtent, equals(0.0));
    expect(second.geometry!.layoutExtent, equals(300.0));
    expect(first.geometry!.scrollExtent, equals(20 * 300.0));
    expect(second.geometry!.scrollExtent, equals(20 * 200.0));

    expect((first.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(0.0));
    expect(first.constraints.scrollOffset, equals(20 * 300.0));
    expect((second.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(0.0));

    final RenderSliverMainAxisGroup renderGroup = tester.renderObject<RenderSliverMainAxisGroup>(
      find.byType(SliverMainAxisGroup),
    );
    expect(renderGroup.geometry!.scrollExtent, equals(300 * 20 + 200 * 20));
    expect(renderGroup.geometry!.hasVisualOverflow, isTrue);
  });

  testWidgets('Hit test works properly on various parts of SliverMainAxisGroup', (
    WidgetTester tester,
  ) async {
    final items = List<int>.generate(20, (int i) => i);
    final controller = ScrollController();
    addTearDown(controller.dispose);

    String? clickedTile;

    var group = 0;
    var tile = 0;

    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
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
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(clickedTile, equals('Group 0 Tile 0'));

    clickedTile = null;
    group = 1;
    tile = 2;
    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
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
        ],
      ),
    );
    controller.jumpTo(300.0 * 20);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(clickedTile, equals('Group 1 Tile 2'));
  });

  testWidgets('applyPaintTransform is implemented properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        slivers: <Widget>[
          const SliverToBoxAdapter(child: Text('first box')),
          const SliverToBoxAdapter(child: Text('second box')),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // localToGlobal calculates offset via applyPaintTransform
    final first = tester.renderObject(find.text('first box')) as RenderBox;
    final RenderBox second = tester.renderObject(find.text('second box'));
    expect(first.localToGlobal(Offset.zero), Offset.zero);
    expect(second.localToGlobal(Offset.zero), Offset(0, first.size.height));
  });

  testWidgets('visitChildrenForSemantics visits children in the correct order', (
    WidgetTester tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        controller: controller,
        slivers: const <Widget>[
          SliverToBoxAdapter(child: SizedBox(height: 200)),
          SliverToBoxAdapter(child: SizedBox(height: 300)),
          SliverToBoxAdapter(child: SizedBox(height: 500)),
          SliverToBoxAdapter(child: SizedBox(height: 400)),
        ],
      ),
    );
    controller.jumpTo(RenderAbstractViewport.defaultCacheExtent + 200);
    await tester.pumpAndSettle();

    final visitedChildren = <RenderSliver>[];
    final RenderSliverMainAxisGroup renderGroup = tester.renderObject<RenderSliverMainAxisGroup>(
      find.byType(SliverMainAxisGroup),
    );
    void visitor(RenderObject child) {
      visitedChildren.add(child as RenderSliver);
    }

    renderGroup.visitChildrenForSemantics(visitor);
    expect(visitedChildren.length, equals(3));
    expect(visitedChildren[0].geometry!.scrollExtent, equals(300));
    expect(visitedChildren[1].geometry!.scrollExtent, equals(500));
    expect(visitedChildren[2].geometry!.scrollExtent, equals(400));
  });

  testWidgets('SliverPinnedPersistentHeader is painted within bounds of SliverMainAxisGroup', (
    WidgetTester tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        controller: controller,
        slivers: <Widget>[
          SliverPersistentHeader(delegate: TestDelegate(), pinned: true),
          const SliverToBoxAdapter(child: SizedBox(height: 600)),
        ],
        otherSlivers: <Widget>[const SliverToBoxAdapter(child: SizedBox(height: 2400))],
      ),
    );
    final renderGroup =
        tester.renderObject(find.byType(SliverMainAxisGroup)) as RenderSliverMainAxisGroup;
    // Scroll extent is the total of the box sliver and the sliver persistent header.
    expect(renderGroup.geometry!.scrollExtent, equals(600.0 + 60.0));
    controller.jumpTo(620);
    await tester.pumpAndSettle();
    final renderHeader =
        tester.renderObject(find.byType(SliverPersistentHeader)) as RenderSliverPersistentHeader;
    // Paint extent after header's layout is 60.0, so we must offset by -20.0 to fit within the 40.0 remaining extent.
    expect(renderHeader.geometry!.paintExtent, equals(60.0));
    expect((renderHeader.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(-20.0));
  });

  testWidgets('SliverFloatingPersistentHeader is painted within bounds of SliverMainAxisGroup', (
    WidgetTester tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        controller: controller,
        slivers: <Widget>[
          SliverPersistentHeader(delegate: TestDelegate(), floating: true),
          const SliverToBoxAdapter(child: SizedBox(height: 600)),
        ],
        otherSlivers: <Widget>[const SliverToBoxAdapter(child: SizedBox(height: 2400))],
      ),
    );
    await tester.pumpAndSettle();
    final renderGroup =
        tester.renderObject(find.byType(SliverMainAxisGroup)) as RenderSliverMainAxisGroup;
    expect(renderGroup.geometry!.scrollExtent, equals(660));
    controller.jumpTo(660.0);
    await tester.pumpAndSettle();
    final TestGesture gesture = await tester.startGesture(const Offset(150.0, 300.0));
    await gesture.moveBy(const Offset(0.0, 40));
    await tester.pump();
    final renderHeader =
        tester.renderObject(find.byType(SliverPersistentHeader)) as RenderSliverPersistentHeader;
    // Paint extent after header's layout is 40.0, so no need to correct the paintOffset.
    expect(renderHeader.geometry!.paintExtent, equals(40.0));
    expect((renderHeader.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(0.0));
  });

  testWidgets(
    'SliverPinnedPersistentHeader is painted within bounds of SliverMainAxisGroup with different minExtent/maxExtent',
    (WidgetTester tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildSliverMainAxisGroup(
          controller: controller,
          slivers: <Widget>[
            SliverPersistentHeader(delegate: TestDelegate(minExtent: 40.0), pinned: true),
            const SliverToBoxAdapter(child: SizedBox(height: 600)),
          ],
          otherSlivers: <Widget>[const SliverToBoxAdapter(child: SizedBox(height: 2400))],
        ),
      );
      final renderGroup =
          tester.renderObject(find.byType(SliverMainAxisGroup)) as RenderSliverMainAxisGroup;
      final renderHeader =
          tester.renderObject(find.byType(SliverPersistentHeader)) as RenderSliverPersistentHeader;
      expect(renderGroup.geometry!.scrollExtent, equals(660));
      controller.jumpTo(630);
      await tester.pumpAndSettle();
      // Paint extent of the header is 40.0, so we must provide an offset of -10.0 to make it fit in the 30.0 remaining paint extent of the group.
      expect(renderHeader.geometry!.paintExtent, equals(40.0));
      expect((renderHeader.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(-10.0));
      controller.jumpTo(610);
      await tester.pumpAndSettle();
      expect(renderHeader.geometry!.paintExtent, equals(40.0));
      expect((renderHeader.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(0.0));
    },
  );

  testWidgets(
    'SliverFloatingPersistentHeader is painted within bounds of SliverMainAxisGroup with different minExtent/maxExtent',
    (WidgetTester tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildSliverMainAxisGroup(
          controller: controller,
          slivers: <Widget>[
            SliverPersistentHeader(delegate: TestDelegate(minExtent: 40.0), floating: true),
            const SliverToBoxAdapter(child: SizedBox(height: 600)),
          ],
          otherSlivers: <Widget>[const SliverToBoxAdapter(child: SizedBox(height: 2400))],
        ),
      );
      await tester.pumpAndSettle();
      final renderGroup =
          tester.renderObject(find.byType(SliverMainAxisGroup)) as RenderSliverMainAxisGroup;
      final renderHeader =
          tester.renderObject(find.byType(SliverPersistentHeader)) as RenderSliverPersistentHeader;
      expect(renderGroup.geometry!.scrollExtent, equals(660));

      controller.jumpTo(660);
      await tester.pumpAndSettle();

      final TestGesture gesture = await tester.startGesture(const Offset(150.0, 300.0));
      await gesture.moveBy(const Offset(0.0, 30.0));
      await tester.pump();
      // Paint extent after header's layout is 30.0, so no need to correct the paintOffset.
      expect(renderHeader.geometry!.paintExtent, equals(30.0));
      expect((renderHeader.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(0.0));
      // Floating headers should expand to maximum extent as we continue scrolling.
      await gesture.moveBy(const Offset(0.0, 20.0));
      await tester.pump();
      expect(renderHeader.geometry!.paintExtent, equals(50.0));
      expect((renderHeader.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(0.0));
    },
  );

  testWidgets(
    'SliverPinnedFloatingPersistentHeader is painted within bounds of SliverMainAxisGroup with different minExtent/maxExtent',
    (WidgetTester tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildSliverMainAxisGroup(
          controller: controller,
          slivers: <Widget>[
            SliverPersistentHeader(
              delegate: TestDelegate(minExtent: 40.0),
              pinned: true,
              floating: true,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 600)),
          ],
          otherSlivers: <Widget>[const SliverToBoxAdapter(child: SizedBox(height: 2400))],
        ),
      );
      await tester.pumpAndSettle();
      final renderGroup =
          tester.renderObject(find.byType(SliverMainAxisGroup)) as RenderSliverMainAxisGroup;
      final renderHeader =
          tester.renderObject(find.byType(SliverPersistentHeader)) as RenderSliverPersistentHeader;
      expect(renderGroup.geometry!.scrollExtent, equals(660));

      controller.jumpTo(660);
      await tester.pumpAndSettle();

      final TestGesture gesture = await tester.startGesture(const Offset(150.0, 300.0));
      await gesture.moveBy(const Offset(0.0, 30.0));
      await tester.pump();
      // Paint extent after header's layout is 40.0, so we need to adjust by -10.0.
      expect(renderHeader.geometry!.paintExtent, equals(40.0));
      expect((renderHeader.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(-10.0));
      // Pinned floating headers should expand to maximum extent as we continue scrolling.
      await gesture.moveBy(const Offset(0.0, 20.0));
      await tester.pump();
      expect(renderHeader.geometry!.paintExtent, equals(50.0));
      expect((renderHeader.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(0.0));
    },
  );

  testWidgets(
    'SliverAppBar with floating: false, pinned: false, snap: false is painted within bounds of SliverMainAxisGroup',
    (WidgetTester tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildSliverMainAxisGroup(
          controller: controller,
          slivers: <Widget>[
            const SliverAppBar(toolbarHeight: 30, expandedHeight: 60),
            const SliverToBoxAdapter(child: SizedBox(height: 600)),
          ],
          otherSlivers: <Widget>[const SliverToBoxAdapter(child: SizedBox(height: 2400))],
        ),
      );
      await tester.pumpAndSettle();
      final renderGroup =
          tester.renderObject(find.byType(SliverMainAxisGroup)) as RenderSliverMainAxisGroup;
      expect(renderGroup.geometry!.scrollExtent, equals(660));

      controller.jumpTo(660);
      await tester.pumpAndSettle();
      controller.jumpTo(630);
      await tester.pumpAndSettle();

      // At a scroll offset of 630, a normal scrolling header should be out of view.
      final renderHeader =
          tester.renderObject(find.byType(SliverPersistentHeader, skipOffstage: false))
              as RenderSliverPersistentHeader;
      expect(renderHeader.constraints.scrollOffset, equals(630));
      expect(renderHeader.geometry!.layoutExtent, equals(0.0));
    },
  );

  testWidgets(
    'SliverAppBar with floating: true, pinned: false, snap: true is painted within bounds of SliverMainAxisGroup',
    (WidgetTester tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildSliverMainAxisGroup(
          controller: controller,
          slivers: <Widget>[
            const SliverAppBar(toolbarHeight: 30, expandedHeight: 60, floating: true, snap: true),
            const SliverToBoxAdapter(child: SizedBox(height: 600)),
          ],
          otherSlivers: <Widget>[const SliverToBoxAdapter(child: SizedBox(height: 2400))],
        ),
      );
      await tester.pumpAndSettle();
      final renderGroup =
          tester.renderObject(find.byType(SliverMainAxisGroup)) as RenderSliverMainAxisGroup;
      final renderHeader =
          tester.renderObject(find.byType(SliverPersistentHeader)) as RenderSliverPersistentHeader;
      expect(renderGroup.geometry!.scrollExtent, equals(660));

      controller.jumpTo(660);
      await tester.pumpAndSettle();

      final TestGesture gesture = await tester.startGesture(const Offset(150.0, 300.0));
      await gesture.moveBy(const Offset(0.0, 10));
      await tester.pump();

      // The snap animation does not go through until the gesture is released.
      expect(renderHeader.geometry!.paintExtent, equals(10));
      expect((renderHeader.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(0.0));

      // Once it is released, the header's paint extent becomes the maximum and the group sets an offset of -50.0.
      await gesture.up();
      await tester.pumpAndSettle();
      expect(renderHeader.geometry!.paintExtent, equals(60));
      expect((renderHeader.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(-50.0));
    },
  );

  testWidgets(
    'SliverAppBar with floating: true, pinned: true, snap: true is painted within bounds of SliverMainAxisGroup',
    (WidgetTester tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildSliverMainAxisGroup(
          controller: controller,
          slivers: <Widget>[
            const SliverAppBar(
              toolbarHeight: 30,
              expandedHeight: 60,
              floating: true,
              pinned: true,
              snap: true,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 600)),
          ],
          otherSlivers: <Widget>[const SliverToBoxAdapter(child: SizedBox(height: 2400))],
        ),
      );
      await tester.pumpAndSettle();
      final renderGroup =
          tester.renderObject(find.byType(SliverMainAxisGroup)) as RenderSliverMainAxisGroup;
      final renderHeader =
          tester.renderObject(find.byType(SliverPersistentHeader)) as RenderSliverPersistentHeader;
      expect(renderGroup.geometry!.scrollExtent, equals(660));

      controller.jumpTo(660);
      await tester.pumpAndSettle();

      final TestGesture gesture = await tester.startGesture(const Offset(150.0, 300.0));
      await gesture.moveBy(const Offset(0.0, 10));
      await tester.pump();

      expect(renderHeader.geometry!.paintExtent, equals(30.0));
      expect((renderHeader.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(-20.0));

      // Once we lift the gesture up, the animation should finish.
      await gesture.up();
      await tester.pumpAndSettle();
      expect(renderHeader.geometry!.paintExtent, equals(60.0));
      expect((renderHeader.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(-50.0));
    },
  );

  testWidgets('SliverMainAxisGroup skips painting invisible children', (WidgetTester tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    var counter = 0;
    void incrementCounter() {
      counter += 1;
    }

    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        controller: controller,
        slivers: <Widget>[
          MockSliverToBoxAdapter(
            incrementCounter: incrementCounter,
            child: Container(height: 1000, decoration: const BoxDecoration(color: Colors.amber)),
          ),
          MockSliverToBoxAdapter(
            incrementCounter: incrementCounter,
            child: Container(height: 400, decoration: const BoxDecoration(color: Colors.amber)),
          ),
          MockSliverToBoxAdapter(
            incrementCounter: incrementCounter,
            child: Container(height: 500, decoration: const BoxDecoration(color: Colors.amber)),
          ),
          MockSliverToBoxAdapter(
            incrementCounter: incrementCounter,
            child: Container(height: 300, decoration: const BoxDecoration(color: Colors.amber)),
          ),
        ],
      ),
    );

    // Can only see top sliver.
    expect(counter, equals(1));

    // Reset paint counter.
    counter = 0;
    controller.jumpTo(1000);
    await tester.pumpAndSettle();

    // Can only see second and third slivers.
    expect(controller.offset, 1000);
    expect(counter, equals(2));
  });

  testWidgets('SliverMainAxisGroup does not cause extra builds for lazy sliver children', (
    WidgetTester tester,
  ) async {
    // By setting the correct SliverGeometry in the first SliverMainAxisGroup,
    // the following SliverMainAxisGroups will not perform extra work.
    final buildsPerGroup = <int, int>{0: 0, 1: 0, 2: 0};
    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            for (int groupIndex = 0; groupIndex < 3; groupIndex++)
              SliverMainAxisGroup(
                slivers: <Widget>[
                  SliverList.builder(
                    itemCount: 100,
                    itemBuilder: (BuildContext context, int index) {
                      buildsPerGroup[groupIndex] = buildsPerGroup[groupIndex]! + 1;
                      return const SizedBox.square(dimension: 50);
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(buildsPerGroup[0], 17); // First sliver filled the screen and cache extent
    expect(buildsPerGroup[1], 1); // Second only lays out one child
    expect(buildsPerGroup[2], 1); // Third only lays out one child
    final renderGroup =
        tester.renderObject(find.byType(SliverMainAxisGroup).first) as RenderSliverMainAxisGroup;
    expect(renderGroup.geometry!.cacheExtent, 850.0);
  });

  testWidgets('SliverMainAxisGroup has consistent cacheOrigin', (WidgetTester tester) async {
    const Widget item = SizedBox.square(dimension: 50);

    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverMainAxisGroup(
              slivers: <Widget>[
                const PinnedHeaderSliver(child: SizedBox(height: 500)),
                SliverList.builder(
                  itemCount: 100,
                  itemBuilder: (BuildContext context, int index) => item,
                ),
                const SliverToBoxAdapter(child: item),
              ],
            ),
          ],
        ),
      ),
    );

    await tester.scrollUntilVisible(find.byType(SliverToBoxAdapter), 500);
    await tester.pumpAndSettle();

    final sliverList =
        find.byType(SliverList).evaluate().single.findRenderObject()! as RenderSliver;

    expect(sliverList.constraints.cacheOrigin, -250.0);
    expect(sliverList.constraints.remainingCacheExtent, 1100);
  });

  testWidgets('SliverMainAxisGroup correctly handles ensureVisible', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        viewportHeight: 300,
        slivers: <Widget>[
          const SliverToBoxAdapter(child: SizedBox(height: 300)),
          SliverToBoxAdapter(child: SizedBox(key: key, height: 100)),
          const SliverToBoxAdapter(child: SizedBox(height: 300)),
        ],
      ),
    );
    Scrollable.ensureVisible(key.currentContext!);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(key)), Offset.zero);
  });

  // Regression test for https://github.com/flutter/flutter/issues/167801
  testWidgets(
    'Nesting SliverMainAxisGroups does not break ShowCaretOnScreen for text fields inside nested SliverMainAxisGroup',
    (WidgetTester tester) async {
      // The number of groups and items per group needs to be high enough to reproduce the bug.
      const sliverGroupsCount = 3;
      const sliverGroupItemsCount = 60;
      // To make working with the scroll offset easier, each item is a fixed height.
      const itemHeight = 72.0;

      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      final Widget widget = MaterialApp(
        theme: ThemeData(
          inputDecorationTheme: const InputDecorationTheme(
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1489FD))),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB1BDC5))),
          ),
        ),
        home: Scaffold(
          body: CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              SliverMainAxisGroup(
                slivers: <Widget>[
                  for (int i = 1; i <= sliverGroupsCount; i++)
                    SliverMainAxisGroup(
                      slivers: <Widget>[
                        SliverList.builder(
                          itemCount: sliverGroupItemsCount,
                          itemBuilder: (_, int index) {
                            final label = 'Field $i.${index + 1}';

                            return SizedBox(
                              height: itemHeight,
                              child: Padding(
                                // This extra padding is to make visually debugging the test app a bit better,
                                // othwerwise the label text clips the text field above.
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: TextField(
                                  key: ValueKey<String>(label),
                                  decoration: InputDecoration(labelText: label),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(widget);

      // Scroll down to the first field in the second group, so that it is at the top of the screen.
      const double offset = sliverGroupItemsCount * itemHeight;
      scrollController.jumpTo(offset);

      await tester.pumpAndSettle();

      // Tap the field so that it gains focus and requests the scrollable to scroll it into view.
      // However, since the field is at the top of the screen, far away from the keyboard,
      // the scroll position should not change.
      await tester.tap(find.byKey(const ValueKey<String>('Field 2.1')));
      await tester.pumpAndSettle();

      expect(scrollController.offset, offset);
    },
  );

  testWidgets('SliverMainAxisGroup offstage child', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        viewportHeight: 300,
        slivers: <Widget>[
          const SliverToBoxAdapter(child: SizedBox(height: 300)),
          const SliverToBoxAdapter(child: SizedBox(height: 100, child: Text('1'))),
        ],
      ),
    );
    expect(find.text('1'), findsNothing);
    expect(find.text('1', skipOffstage: false), findsOneWidget);
  });

  testWidgets("The localToGlobal of SliverMainAxisGroup's children works in reverse.", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        viewportHeight: 400,
        reverse: true,
        slivers: <Widget>[
          const SliverToBoxAdapter(child: SizedBox(height: 70)),
          const SliverToBoxAdapter(child: SizedBox(height: 20, child: Text('1'))),
          const SliverToBoxAdapter(child: SizedBox(height: 700)),
        ],
      ),
    );
    final renderBox = tester.renderObject(find.text('1')) as RenderBox;
    expect(renderBox.localToGlobal(Offset.zero), const Offset(0.0, 310.0));
    expect(tester.getTopLeft(find.text('1')), const Offset(0.0, 310.0));
  });

  testWidgets('SliverMainAxisGroup multiple PinnedHeaderSliver children', (
    WidgetTester tester,
  ) async {
    final Size screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
    final controller = ScrollController();
    addTearDown(controller.dispose);
    Future<void> pumpWidget({Axis scrollDirection = Axis.vertical, bool reverse = false}) async {
      Widget buildExtentBox(double size, {Widget? child}) {
        return switch (scrollDirection) {
          Axis.vertical => SizedBox(height: size, child: child),
          Axis.horizontal => SizedBox(width: size, child: child),
        };
      }

      await tester.pumpWidget(
        _buildSliverMainAxisGroup(
          controller: controller,
          viewportHeight: screenSize.height,
          viewportWidth: screenSize.width,
          scrollDirection: scrollDirection,
          reverse: reverse,
          slivers: <Widget>[
            PinnedHeaderSliver(child: buildExtentBox(30)),
            SliverToBoxAdapter(child: buildExtentBox(30)),
            PinnedHeaderSliver(child: buildExtentBox(20, child: const Text('1'))),
            SliverToBoxAdapter(child: buildExtentBox(1000)),
          ],
        ),
      );
    }

    await pumpWidget();
    controller.jumpTo(500);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('1')), const Offset(0, 30));

    await pumpWidget(scrollDirection: Axis.horizontal);
    controller.jumpTo(500);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('1')), const Offset(30, 0));

    await pumpWidget(reverse: true);
    controller.jumpTo(500);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('1')), Offset(0, screenSize.height - 50));

    await pumpWidget(scrollDirection: Axis.horizontal, reverse: true);
    controller.jumpTo(500);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('1')), Offset(screenSize.width - 50, 0));
  });

  testWidgets('SliverMainAxisGroup precision error', (WidgetTester tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            height: 201,
            child: CustomScrollView(
              controller: controller,
              slivers: const <Widget>[
                SliverMainAxisGroup(
                  slivers: <Widget>[
                    SliverToBoxAdapter(child: SizedBox(height: 70)),
                    PinnedHeaderSliver(child: SizedBox(height: 70)),
                    SliverToBoxAdapter(child: SizedBox(height: 70)),
                    PinnedHeaderSliver(child: SizedBox(height: 70)),
                    SliverToBoxAdapter(child: SizedBox(height: 70)),
                    PinnedHeaderSliver(child: SizedBox(height: 70)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.jumpTo(60.22678428085297);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('SliverMainAxisGroup reverse hitTest', (WidgetTester tester) async {
    var onTapCalled = false;
    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        reverse: true,
        viewportHeight: 70,
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                onTapCalled = true;
              },
              child: const SizedBox(height: 50),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
    await tester.tapAt(const Offset(0, 10));
    await tester.pumpAndSettle();
    expect(onTapCalled, isFalse);
    await tester.tapAt(const Offset(0, 69));
    await tester.pumpAndSettle();
    expect(onTapCalled, isTrue);
  });

  testWidgets('SliverMainAxisGroup with center', (WidgetTester tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    const centerKey = Key('center');
    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          center: centerKey,
          controller: controller,
          slivers: const <Widget>[
            SliverMainAxisGroup(
              slivers: <Widget>[
                SliverToBoxAdapter(child: SizedBox(height: 50, child: Text('-2'))),
                SliverToBoxAdapter(child: SizedBox(height: 50, child: Text('-1'))),
              ],
            ),
            SliverMainAxisGroup(
              key: centerKey,
              slivers: <Widget>[
                SliverToBoxAdapter(child: SizedBox(height: 50, child: Text('1'))),
                SliverToBoxAdapter(child: SizedBox(height: 50, child: Text('2'))),
              ],
            ),
          ],
        ),
      ),
    );
    controller.jumpTo(-51);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('-1')), const Offset(0, 1));
    expect(tester.getTopLeft(find.text('1')), const Offset(0, 51));
    expect(tester.getTopLeft(find.text('2')), const Offset(0, 101));
    expect(tester.getTopLeft(find.text('-2')), const Offset(0, -49));
  });

  testWidgets('showOnScreen reveals the Sliver after a pinned child in SliverMainAxisGroup', (
    WidgetTester tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        viewportHeight: 100,
        controller: controller,
        slivers: <Widget>[
          const PinnedHeaderSliver(child: SizedBox(height: 50)),
          const SliverToBoxAdapter(child: SizedBox(height: 50, child: Text('1'))),
          const SliverToBoxAdapter(child: SizedBox(height: 400)),
        ],
      ),
    );
    controller.jumpTo(200);
    await tester.pumpAndSettle();
    final RenderObject renderObject = tester.renderObject(find.text('1', skipOffstage: false));
    renderObject.showOnScreen();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('1')), const Offset(0.0, 50.0));
  });

  // Regression test for https://github.com/flutter/flutter/issues/173274
  testWidgets(
    'In multiple SliverMainAxisGroups, children after a PinnedHeaderSliver do not overscroll.',
    (WidgetTester tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final Key key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 100,
              child: CustomScrollView(
                controller: controller,
                slivers: <Widget>[
                  SliverMainAxisGroup(
                    slivers: <Widget>[
                      const PinnedHeaderSliver(child: SizedBox(height: 20)),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      SliverToBoxAdapter(child: SizedBox(height: 60, key: key)),
                    ],
                  ),
                  const SliverMainAxisGroup(
                    slivers: <Widget>[
                      PinnedHeaderSliver(child: SizedBox(height: 20)),
                      SliverToBoxAdapter(child: SizedBox(height: 20)),
                      SliverToBoxAdapter(child: SizedBox(height: 60)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      controller.jumpTo(70);
      await tester.pumpAndSettle();
      final Offset offset = tester.getBottomRight(find.byKey(key));
      controller.jumpTo(80);
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(find.byKey(key)), offset - const Offset(0.0, 10.0));
      controller.jumpTo(90);
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(find.byKey(key)), offset - const Offset(0.0, 20.0));
    },
  );

  // Regression test for https://github.com/flutter/flutter/issues/173029.
  testWidgets('SliverMainAxisGroup pointer event positions', (WidgetTester tester) async {
    final tapDownLog = <({int index, TapDownDetails details})>[];

    Widget buildItem(int index) {
      return SliverToBoxAdapter(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails details) => tapDownLog.add((index: index, details: details)),
          child: const SizedBox(height: 20),
        ),
      );
    }

    Future<void> checkTapDown({
      required Offset tapAt,
      required int expectedIndex,
      required Offset expectedLocalPosition,
    }) async {
      await tester.tapAt(tapAt);
      expect(tapDownLog.last.index, expectedIndex);
      expect(tapDownLog.last.details.localPosition, expectedLocalPosition);
      expect(tapDownLog.last.details.globalPosition, tapAt);
    }

    // Forward direction.
    final controller1 = ScrollController();
    addTearDown(controller1.dispose);
    await tester.pumpWidget(
      KeyedSubtree(
        key: const ObjectKey('froward'),
        child: _buildSliverMainAxisGroup(
          // x1.5 of item height, so only half of the second item is visible.
          viewportHeight: 30,
          viewportWidth: 30,
          controller: controller1,
          slivers: <Widget>[buildItem(0), buildItem(1)],
        ),
      ),
    );

    await checkTapDown(
      tapAt: const Offset(15, 5),
      expectedIndex: 0,
      expectedLocalPosition: const Offset(15, 5),
    );
    await checkTapDown(
      tapAt: const Offset(15, 15),
      expectedIndex: 0,
      expectedLocalPosition: const Offset(15, 15),
    );
    await checkTapDown(
      tapAt: const Offset(15, 25),
      expectedIndex: 1,
      expectedLocalPosition: const Offset(15, 5),
    );

    // Scroll to the end to fully reveal the second item.
    controller1.jumpTo(10);
    await tester.pump();

    await checkTapDown(
      tapAt: const Offset(15, 5),
      expectedIndex: 0,
      expectedLocalPosition: const Offset(15, 15),
    );
    await checkTapDown(
      tapAt: const Offset(15, 15),
      expectedIndex: 1,
      expectedLocalPosition: const Offset(15, 5),
    );
    await checkTapDown(
      tapAt: const Offset(15, 25),
      expectedIndex: 1,
      expectedLocalPosition: const Offset(15, 15),
    );

    tapDownLog.clear();

    // Reverse direction.
    final controller2 = ScrollController();
    addTearDown(controller2.dispose);
    await tester.pumpWidget(
      KeyedSubtree(
        key: const ObjectKey('reverse'),
        child: _buildSliverMainAxisGroup(
          reverse: true,
          // x1.5 of item height, so only half of the second item is visible.
          viewportHeight: 30,
          viewportWidth: 30,
          controller: controller2,
          slivers: <Widget>[buildItem(0), buildItem(1)],
        ),
      ),
    );

    await checkTapDown(
      tapAt: const Offset(15, 5),
      expectedIndex: 1,
      expectedLocalPosition: const Offset(15, 15),
    );
    await checkTapDown(
      tapAt: const Offset(15, 15),
      expectedIndex: 0,
      expectedLocalPosition: const Offset(15, 5),
    );
    await checkTapDown(
      tapAt: const Offset(15, 25),
      expectedIndex: 0,
      expectedLocalPosition: const Offset(15, 15),
    );

    // Scroll to the end to fully reveal the second item.
    controller2.jumpTo(10);
    await tester.pump();

    await checkTapDown(
      tapAt: const Offset(15, 5),
      expectedIndex: 1,
      expectedLocalPosition: const Offset(15, 5),
    );
    await checkTapDown(
      tapAt: const Offset(15, 15),
      expectedIndex: 1,
      expectedLocalPosition: const Offset(15, 15),
    );
    await checkTapDown(
      tapAt: const Offset(15, 25),
      expectedIndex: 0,
      expectedLocalPosition: const Offset(15, 5),
    );
  });
  testWidgets(
    'With SliverList can handle inaccurate scroll offset due to changes in children list',
    (WidgetTester tester) async {
      var skip = true;
      Widget buildItem(BuildContext context, int index) {
        return !skip || index.isEven
            ? Card(
                child: ListTile(title: Text('item$index', style: const TextStyle(fontSize: 80))),
              )
            : Container();
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: CustomScrollView(
              slivers: <Widget>[
                SliverMainAxisGroup(
                  slivers: <Widget>[
                    SliverList(delegate: SliverChildBuilderDelegate(buildItem, childCount: 30)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      // Only even items 0~12 are on the screen.
      for (var index = 0; index <= 12; index++) {
        expect(find.text('item$index'), index.isEven ? findsOneWidget : findsNothing);
      }
      expect(find.text('item12'), findsOneWidget);
      expect(find.text('item14'), findsNothing);

      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, -750.0));
      await tester.pump();
      // Only even items 16~28 are on the screen.
      expect(find.text('item15'), findsNothing);
      expect(find.text('item16'), findsOneWidget);
      expect(find.text('item28'), findsOneWidget);

      skip = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: <Widget>[
                SliverMainAxisGroup(
                  slivers: <Widget>[
                    SliverList(delegate: SliverChildBuilderDelegate(buildItem, childCount: 30)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      // Only items 12~19 are on the screen.
      expect(find.text('item11'), findsNothing);
      expect(find.text('item12'), findsOneWidget);
      expect(find.text('item19'), findsOneWidget);
      expect(find.text('item20'), findsNothing);

      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, 250.0));
      await tester.pump();

      // Only items 10~16 are on the screen.
      expect(find.text('item9'), findsNothing);
      expect(find.text('item10'), findsOneWidget);
      expect(find.text('item16'), findsOneWidget);
      expect(find.text('item17'), findsNothing);

      // The inaccurate scroll offset should reach zero at this point
      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, 250.0));
      await tester.pump();

      // Only items 7~13 are on the screen.
      expect(find.text('item6'), findsNothing);
      expect(find.text('item7'), findsOneWidget);
      expect(find.text('item13'), findsOneWidget);
      expect(find.text('item14'), findsNothing);

      // It will be corrected as we scroll, so we have to drag multiple times.
      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, 250.0));
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, 250.0));
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, 250.0));
      await tester.pump();

      // Only items 0~6 are on the screen.
      expect(find.text('item0'), findsOneWidget);
      expect(find.text('item6'), findsOneWidget);
      expect(find.text('item7'), findsNothing);
    },
  );

  testWidgets('SliverMainAxisGroup ensure semantics', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        slivers: <Widget>[
          const SliverEnsureSemantics(sliver: SliverToBoxAdapter(child: Text('a'))),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Lorem Ipsum $index'),
                  ),
                );
              },
              childCount: 50,
              semanticIndexOffset: 1,
            ),
          ),
          const SliverEnsureSemantics(sliver: SliverToBoxAdapter(child: Text('b'))),
        ],
      ),
    );

    // Even though 'b' is outside of the Viewport and cacheExtent, since it is
    // wrapped with a `SliverEnsureSemantics` it will still be included in the
    // semantics tree.
    expect(semantics.nodesWith(label: 'b'), hasLength(1));
    expect(find.text('b'), findsNothing);
    expect(find.byType(SliverEnsureSemantics, skipOffstage: false), findsNWidgets(2));
    semantics.dispose();
  });

  testWidgets('SliverMainAxisGroup includes items in cacheExtent in semantics', (
    WidgetTester tester,
  ) async {
    final semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      _buildSliverMainAxisGroup(
        viewportHeight: 300,
        // Default cacheExtent is 250.0
        slivers: <Widget>[
          const SliverToBoxAdapter(child: SizedBox(height: 300, child: Text('a'))),
          const SliverToBoxAdapter(child: SizedBox(height: 100, child: Text('b'))),
        ],
      ),
    );

    // 'b' is not visible, but it should be in the cache extent.
    expect(find.text('b'), findsNothing);
    // So it should be in the semantics tree.
    expect(semantics.nodesWith(label: 'b'), hasLength(1));
    semantics.dispose();
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
                child: label(items[i]),
              );
      },
      findChildIndexCallback: (Key key) {
        final valueKey = key as ValueKey<int>;
        final int index = items.indexOf(valueKey.value);
        return index == -1 ? null : index;
      },
      childCount: items.length,
    ),
  );
}

Widget _buildSliverMainAxisGroup({
  required List<Widget> slivers,
  ScrollController? controller,
  double viewportHeight = VIEWPORT_HEIGHT,
  double viewportWidth = VIEWPORT_WIDTH,
  Axis scrollDirection = Axis.vertical,
  bool reverse = false,
  List<Widget> otherSlivers = const <Widget>[],
}) {
  return MaterialApp(
    home: Directionality(
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
            slivers: <Widget>[
              SliverMainAxisGroup(slivers: slivers),
              ...otherSlivers,
            ],
          ),
        ),
      ),
    ),
  );
}

class TestDelegate extends SliverPersistentHeaderDelegate {
  TestDelegate({this.maxExtent = 60.0, this.minExtent = 60.0});

  @override
  final double maxExtent;

  @override
  final double minExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(height: maxExtent);
  }

  @override
  bool shouldRebuild(TestDelegate oldDelegate) => true;
}
