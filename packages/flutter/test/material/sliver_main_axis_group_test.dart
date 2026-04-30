// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const double _kViewportHeight = 600;
const double _kViewportWidth = 300;

Widget _buildSliverMainAxisGroup({
  required List<Widget> slivers,
  ScrollController? controller,
  double viewportHeight = _kViewportHeight,
  double viewportWidth = _kViewportWidth,
  List<Widget> otherSlivers = const <Widget>[],
}) {
  return MaterialApp(
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        height: viewportHeight,
        width: viewportWidth,
        child: CustomScrollView(
          controller: controller,
          slivers: <Widget>[
            SliverMainAxisGroup(slivers: slivers),
            ...otherSlivers,
          ],
        ),
      ),
    ),
  );
}

void main() {
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

}
