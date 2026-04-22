// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// A minimal ListTile widget for testing purposes.
// Duplicated from test/widgets/list_tile_tester.dart to avoid cross-importing
// test utilities across package boundaries (see https://github.com/flutter/flutter/issues/182636).
class _TestListTile extends StatelessWidget {
  const _TestListTile({this.title});

  final Widget? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: title,
    );
  }
}

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

  testWidgets(
    'With SliverList can handle inaccurate scroll offset due to changes in children list',
    (WidgetTester tester) async {
      var skip = true;
      Widget buildItem(BuildContext context, int index) {
        return !skip || index.isEven
            ? Card(
                child: _TestListTile(
                  title: Text('item$index', style: const TextStyle(fontSize: 80)),
                ),
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
}
