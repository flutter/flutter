// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('SliverMasonryGrid', () {
    testWidgets('the size of each child', (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: customScrollViewBoilerplate(
          sliverMasonryGrid: sliverMasonryGridWithChildrenBoilerplate(crossAxisCount: 2),
        ),
        textDirection: TextDirection.ltr,
      ));

      expect(
        tester.getSize(find.widgetWithText(Container, "0.He'd have you all unravel at the")),
        const Size(400.0, 50.0),
      );

      expect(tester.getSize(find.widgetWithText(Container, '1.Heed not the rabble')),
        const Size(400.0, 70.0),
      );

      expect(
        tester.getSize(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Size(400.0, 90.0),
      );

      expect(
        tester.getSize(find.widgetWithText(Container, '3.Who scream')),
        const Size(400.0, 60.0),
      );

      expect(
        tester.getSize(find.widgetWithText(Container, '4.Revolution is coming...')),
        const Size(400.0, 80.0),
      );

      expect(
        tester.getSize(find.widgetWithText(Container, '5.Revolution, they...')),
        const Size(400.0, 100.0),
      );
    });

    testWidgets('the position of each child at TextDirection.ltr',
      (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: customScrollViewBoilerplate(
          sliverMasonryGrid: sliverMasonryGridWithChildrenBoilerplate(crossAxisCount: 2),
        ),
        textDirection: TextDirection.ltr,
      ));

      expect(
        tester.getTopLeft(find.widgetWithText(Container, "0.He'd have you all unravel at the")),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1.Heed not the rabble')),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 50.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(400.0, 70.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4.Revolution is coming...')),
        const Offset(400.0, 130.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5.Revolution, they...')),
        const Offset(0.0, 140.0),
      );
    });

    testWidgets('the position of each child at TextDirection.rtl',
      (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: customScrollViewBoilerplate(
          sliverMasonryGrid: sliverMasonryGridWithChildrenBoilerplate(crossAxisCount: 2),
        ),
        textDirection: TextDirection.rtl),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, "0.He'd have you all unravel at the")),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1.Heed not the rabble')),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(400.0, 50.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(0.0, 70.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4.Revolution is coming...')),
        const Offset(0.0, 130.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5.Revolution, they...')),
        const Offset(400.0, 140.0),
      );
    });

    testWidgets('crossAxisCount change test', (WidgetTester tester) async {
      int crossAxisCount = 2;
      await tester.pumpWidget(materialAppBoilerplate(
        child: SliverMasonryTestPage(
          crossAxisCount: crossAxisCount,
          setState: (_SliverMasonryTestPageState state) {
            state._crossAxisCount = crossAxisCount;
          },
        ),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 50.0),
      );

      crossAxisCount = 4;
      await setStateBoilerplate(tester);

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(400.0, 0.0),
      );
    });

    testWidgets('crossAxisSpacing change test', (WidgetTester tester) async {
      double crossAxisSpacing = 10;
      await tester.pumpWidget(materialAppBoilerplate(
        child: SliverMasonryTestPage(
          crossAxisSpacing: crossAxisSpacing,
          crossAxisCount: 2,
          setState: (_SliverMasonryTestPageState state) {
            state._crossAxisSpacing = crossAxisSpacing;
          },
        ),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 50.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(405.0, 70.0),
      );

      crossAxisSpacing = 20;
      await setStateBoilerplate(tester);

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 50.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(410.0, 70.0),
      );
    });

    testWidgets('mainAxisSpacing test', (WidgetTester tester) async {
      double mainAxisSpacing = 10;
      await tester.pumpWidget(materialAppBoilerplate(
        child: SliverMasonryTestPage(
          mainAxisSpacing: mainAxisSpacing,
          crossAxisCount: 2,
          setState: (_SliverMasonryTestPageState state) {
            state._mainAxisSpacing = mainAxisSpacing;
          },
        ),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 60.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(400.0, 80.0),
      );

      mainAxisSpacing = 20;
      await setStateBoilerplate(tester);

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 70.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(400.0, 90.0),
      );
    });

    testWidgets('maxCrossAxisExtent change test', (WidgetTester tester) async {
      double maxCrossAxisExtent = 400;
      await tester.pumpWidget(materialAppBoilerplate(
        child: SliverMasonryTestPage(
          maxCrossAxisExtent: maxCrossAxisExtent,
          crossAxisCount: 2,
          setState: (_SliverMasonryTestPageState state) {
            state._maxCrossAxisExtent = maxCrossAxisExtent;
          },
        ),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 50.0),
      );

      maxCrossAxisExtent = 200;
      await setStateBoilerplate(tester);

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(400.0, 0.0),
      );
    });

    testWidgets('itemCount change test', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      int itemCount = 100;
      await tester.pumpWidget(materialAppBoilerplate(
        child: SliverMasonryTestPage(
          controller: controller,
          crossAxisCount: 4,
          items: List<int>.generate(itemCount, (int index) => index),
          setState: (_SliverMasonryTestPageState state) {
             state._items = List<int>.generate(itemCount, (int index) => index);
          },
          builder: true,
        )),
      );
      expect(find.widgetWithText(Container, '0'), findsOneWidget);
      controller.jumpTo(10000);
      await tester.pumpAndSettle();

      itemCount = 0;
      await setStateBoilerplate(tester);

      expect(find.widgetWithText(Container, '0'), findsNothing);
      expect(controller.offset, 0.0);

      itemCount = 100;
      await setStateBoilerplate(tester);

      expect(find.widgetWithText(Container, '3'), findsOneWidget);

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1')),
        const Offset(200.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2')),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3')),
        const Offset(600.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4')),
        const Offset(0.0, 100.0),
      );
    });

    testWidgets('items removeRange test', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      int start;
      int end;
      await tester.pumpWidget(materialAppBoilerplate(
        child: SliverMasonryTestPage(
          controller: controller,
          crossAxisCount: 4,
          items: List<int>.generate(100, (int index) => index),
          setState: (_SliverMasonryTestPageState state) {
             state._items.removeRange(start, end);
          },
          builder: true,
        )),
      );
      expect(find.widgetWithText(Container, '0'), findsOneWidget);
      controller.jumpTo(10000);
      await tester.pumpAndSettle();

      start = 40;
      end = 60;
      await setStateBoilerplate(tester);
      controller.jumpTo(0);
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1')),
        const Offset(200.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2')),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3')),
        const Offset(600.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4')),
        const Offset(0.0, 100.0),
      );
    });

    // code coverage: [RenderSliverMasonryGrid]
    // if (data.layoutOffset < -precisionErrorTolerance)
    testWidgets('the child who out of viewport change big test', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      double size;
      await tester.pumpWidget(materialAppBoilerplate(
        child: SliverMasonryTestPage(
          controller: controller,
          crossAxisCount: 4,
          items: List<int>.generate(100, (int index) => index),
          sizeBuilder: (int index) {
            if(index == 1 && size !=null) {
              return size;
            }
            return null;
          },
          builder: true,
        )),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1')),
        const Offset(200.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2')),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3')),
        const Offset(600.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4')),
        const Offset(0.0, 100.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5')),
        const Offset(0.0, 200.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '6')),
        const Offset(200.0, 200.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '7')),
        const Offset(400.0, 300.0),
      );

      controller.jumpTo(10000);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Container, '0'), findsNothing);

      // change child size from 200 to 500.
      size = 500;
      await setStateBoilerplate(tester);
      controller.jumpTo(0);
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1')),
        const Offset(200.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2')),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3')),
        const Offset(600.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4')),
        const Offset(0.0, 100.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5')),
        const Offset(0.0, 200.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '6')),
        const Offset(400.0, 300.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '7')),
        const Offset(0.0, 400.0),
      );
    });

    // code coverage: [RenderSliverMasonryGrid]
    // if (earliestUsefulChild == null) {
    testWidgets('the child who out of viewport change small sroll into 0 test', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      double size;
      await tester.pumpWidget(materialAppBoilerplate(
        child: SliverMasonryTestPage(
          controller: controller,
          crossAxisCount: 4,
          items: List<int>.generate(100, (int index) => index),
          sizeBuilder: (int index) {
            if(index == 0 && size !=null) {
              return size;
            }
            return null;
          },
          builder: true,
        )),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1')),
        const Offset(200.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2')),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3')),
        const Offset(600.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4')),
        const Offset(0.0, 100.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5')),
        const Offset(0.0, 200.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '6')),
        const Offset(200.0, 200.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '7')),
        const Offset(400.0, 300.0),
      );

      controller.jumpTo(10000);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Container, '0'), findsNothing);

      // change child size from 100 to 30.
      size = 30;
      await setStateBoilerplate(tester);
      controller.jumpTo(0);
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1')),
        const Offset(200.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2')),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3')),
        const Offset(600.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4')),
        const Offset(0.0, 30.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5')),
        const Offset(0.0, 130.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '6')),
        const Offset(200.0, 200.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '7')),
        const Offset(400.0, 300.0),
      );
    });

    // code coverage: [RenderSliverMasonryGrid]
    // if (earliestUsefulChild == null) {
    testWidgets('the child who out of viewport change small sroll into 100 test', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      double size;
      await tester.pumpWidget(materialAppBoilerplate(
        child: SliverMasonryTestPage(
          controller: controller,
          crossAxisCount: 4,
          items: List<int>.generate(100, (int index) => index),
          sizeBuilder: (int index) {
            if(index == 1 && size !=null) {
              return size;
            }
            return null;
          },
          builder: true,
        )),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1')),
        const Offset(200.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2')),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3')),
        const Offset(600.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4')),
        const Offset(0.0, 100.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5')),
        const Offset(0.0, 200.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '6')),
        const Offset(200.0, 200.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '7')),
        const Offset(400.0, 300.0),
      );

      controller.jumpTo(10000);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Container, '0'), findsNothing);

      // change child size from 100 to 30.
      size = 30;
      await setStateBoilerplate(tester);
      controller.jumpTo(100);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Container, '0'), findsNothing);

      expect(find.widgetWithText(Container, '1'), findsNothing);

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2')),
        const Offset(400.0, -100.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3')),
        const Offset(600.0, -100.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4')),
        const Offset(200.0, -70.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5')),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '6')),
        const Offset(200.0, 30.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '7')),
        const Offset(0.0, 200.0),
      );
    });

    // code coverage: [RenderSliverMasonryGrid]
    // if (data.layoutOffset < -precisionErrorTolerance)
    testWidgets('insert child out of viewport test', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      double size;
      await tester.pumpWidget(materialAppBoilerplate(
        child: SliverMasonryTestPage(
          controller: controller,
          crossAxisCount: 4,
          items: List<int>.generate(100, (int index) => index),
          sizeBuilder: (int index) {
            if(index == 0 && size !=null) {
              return size;
            }
            return null;
          },
          setState: (_SliverMasonryTestPageState state) {
             state._items.insert(0, 999);
          },
          builder: true,
        )),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1')),
        const Offset(200.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2')),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3')),
        const Offset(600.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4')),
        const Offset(0.0, 100.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5')),
        const Offset(0.0, 200.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '6')),
        const Offset(200.0, 200.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '7')),
        const Offset(400.0, 300.0),
      );

      controller.jumpTo(10000);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Container, '0'), findsNothing);

      // insert 999 into 0 index with size 500.0.
      size = 500;
      await setStateBoilerplate(tester);
      controller.jumpTo(0);
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '999')),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')),
        const Offset(200.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1')),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2')),
        const Offset(600.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3')),
        const Offset(200.0, 200.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4')),
        const Offset(200.0, 300.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5')),
        const Offset(400.0, 300.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '7')),
        const Offset(0.0, 500.0),
      );
    });

    testWidgets('remove child out of viewport test', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      int removeIndex;
      await tester.pumpWidget(materialAppBoilerplate(
        child: SliverMasonryTestPage(
          controller: controller,
          crossAxisCount: 4,
          items: List<int>.generate(100, (int index) => index),
          sizeBuilder: (int index) {
            if(removeIndex !=null && index >= removeIndex) {
              return (((index + 1) % 4) + 1) * 100.0;
            }
            return null;
          },
          setState: (_SliverMasonryTestPageState state) {
             state._items.remove(removeIndex);
          },
          builder: true,
        )),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1')),
        const Offset(200.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2')),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3')),
        const Offset(600.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4')),
        const Offset(0.0, 100.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5')),
        const Offset(0.0, 200.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '6')),
        const Offset(200.0, 200.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '7')),
        const Offset(400.0, 300.0),
      );

      controller.jumpTo(10000);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Container, '0'), findsNothing);

      // remove index 3.
      removeIndex = 3;
      await setStateBoilerplate(tester);
      controller.jumpTo(0);
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1')),
        const Offset(200.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2')),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4')),
        const Offset(600.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5')),
        const Offset(0.0, 100.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '6')),
        const Offset(600.0, 100.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '7')),
        const Offset(200.0, 200.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '8')),
        const Offset(0.0, 300.0),
      );
    });

    testWidgets('test with other slivers', (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: SliverMasonryTestPage(
          crossAxisCount: 2,
          headerSlivers: <Widget>[
            SliverToBoxAdapter(
              child: Container(
                height: 200.0,
                color: Colors.red,
              ),
            )
          ],
          footSlivers: <Widget>[
            SliverToBoxAdapter(
              child: Container(
                height: 200.0,
                color: Colors.blue,
              ),
            )
          ],
        ),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 250.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(400.0, 270.0),
      );
    });

    testWidgets('insert other slivers test', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      await tester.pumpWidget(materialAppBoilerplate(
        child: SliverMasonryTestPage(
          controller: controller,
          crossAxisCount: 2,
          headerSlivers: <Widget>[
            SliverToBoxAdapter(
              child: Container(
                height: 200.0,
                color: Colors.red,
              ),
            )
          ],
          footSlivers: <Widget>[
            SliverToBoxAdapter(
              child: Container(
                height: 200.0,
                color: Colors.blue,
              ),
            )
          ],
          setState: (_SliverMasonryTestPageState state) {
            state._headerSlivers.add(
              SliverToBoxAdapter(
                child: Container(
                  height: 200.0,
                  color: Colors.yellow,
                ),
              ),
            );
          },
        ),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 250.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(400.0, 270.0),
      );

      controller.jumpTo(10000);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Container, "0.He'd have you all unravel at the"), findsOneWidget);

      await setStateBoilerplate(tester);
      controller.jumpTo(0);
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.widgetWithText(Container, "0.He'd have you all unravel at the")),
        const Offset(0.0, 400.0),
      );
    });
  });
}

SliverMasonryGrid masonryGridBoilerplate({
  int crossAxisCount = 4,
  double crossAxisSpacing = 0.0,
  double mainAxisSpacing = 0.0,
  double maxCrossAxisExtent,
  List<int> items,
  double Function(int index) sizeBuilder,
}) {
  final SliverMasonryGridDelegate delegate = maxCrossAxisExtent != null ?
    SliverMasonryGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxCrossAxisExtent,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
    ) :
    SliverMasonryGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
    );

  return SliverMasonryGrid(
    gridDelegate: delegate,
    delegate: SliverChildBuilderDelegate(
      (BuildContext context, int index) {
        return Container(
          alignment: Alignment.center,
          child: Text(
            '${items[index]}',
          ),
          height: sizeBuilder?.call(index) ?? ((index % crossAxisCount) + 1) * 100.0,
        );
      },
      childCount: items.length,
    ),
  );
}

SliverMasonryGrid sliverMasonryGridWithChildrenBoilerplate({
  int crossAxisCount = 2,
  double crossAxisSpacing = 0.0,
  double mainAxisSpacing = 0.0,
  double maxCrossAxisExtent,
}) {

  final List<Widget> children = <Widget> [
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text("0.He'd have you all unravel at the"),
      color: Colors.teal[100],
      height: 50.0,
    ),
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text('1.Heed not the rabble'),
      color: Colors.teal[200],
      height: 70.0,
    ),
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text('2.Sound of screams but the'),
      color: Colors.teal[300],
      height: 90.0,
    ),
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text('3.Who scream'),
      color: Colors.teal[400],
      height: 60.0,
    ),
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text('4.Revolution is coming...'),
      color: Colors.teal[500],
      height: 80.0,
    ),
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text('5.Revolution, they...'),
      color: Colors.teal[600],
      height: 100.0,
    ),
  ];

  return maxCrossAxisExtent != null ?
    SliverMasonryGrid.extent(
      maxCrossAxisExtent: maxCrossAxisExtent,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      children: children,
    ):
    SliverMasonryGrid.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      children: children,
    );
}

Widget customScrollViewBoilerplate({
  List<Widget> headerSlivers,
  List<Widget> footSlivers,
  SliverMasonryGrid sliverMasonryGrid,
  ScrollController controller,
  }) {
  return CustomScrollView(
    controller: controller,
    slivers: <Widget>[
      if (headerSlivers != null) ...headerSlivers,
      sliverMasonryGrid,
      if (footSlivers != null) ...footSlivers,
  ],);
}

Widget materialAppBoilerplate({
  Widget child,
  TextDirection textDirection = TextDirection.ltr,
  }) {
  return MaterialApp(
    home: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800.0, 600.0)),
        child: Material(
          child: child,
        ),
      ),
    ),
  );
}

class SliverMasonryTestPage extends StatefulWidget {
  const SliverMasonryTestPage({
    this.crossAxisCount = 4,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.textDirection = TextDirection.ltr,
    this.maxCrossAxisExtent,
    this.items,
    this.controller,
    this.setState,
    this.builder = false,
    this.headerSlivers,
    this.footSlivers,
    this.sizeBuilder,
  });
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final TextDirection textDirection;
  final double maxCrossAxisExtent;
  final List<int> items;
  final ScrollController controller;
  final void Function(_SliverMasonryTestPageState setState) setState;
  final bool builder;
  final List<Widget> headerSlivers;
  final List<Widget> footSlivers;
  final double Function(int index) sizeBuilder;
  @override
  _SliverMasonryTestPageState createState() => _SliverMasonryTestPageState();
}

class _SliverMasonryTestPageState extends State<SliverMasonryTestPage> {
  int _crossAxisCount;
  double _crossAxisSpacing;
  double _mainAxisSpacing;
  TextDirection _textDirection;
  double _maxCrossAxisExtent;
  List<Widget> _headerSlivers;
  List<Widget> _footSlivers;
  List<int> _items;
  @override
  void initState() {
    _crossAxisCount = widget.crossAxisCount;
    _mainAxisSpacing = widget.mainAxisSpacing;
    _crossAxisSpacing =widget.crossAxisSpacing;
    _textDirection = widget.textDirection;
    _maxCrossAxisExtent = widget.maxCrossAxisExtent;
    _items = widget.items;
    _headerSlivers = widget.headerSlivers;
    _footSlivers = widget.footSlivers;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: _textDirection,
        child: customScrollViewBoilerplate(
          controller: widget.controller,
          headerSlivers: _headerSlivers,
          footSlivers: _footSlivers,
          sliverMasonryGrid: widget.builder ?
            masonryGridBoilerplate(
              crossAxisCount: _crossAxisCount,
              mainAxisSpacing: _mainAxisSpacing,
              crossAxisSpacing: _crossAxisSpacing,
              maxCrossAxisExtent: _maxCrossAxisExtent,
              items: _items,
              sizeBuilder: widget.sizeBuilder,
            ) :
            sliverMasonryGridWithChildrenBoilerplate(
              crossAxisCount: _crossAxisCount,
              mainAxisSpacing: _mainAxisSpacing,
              crossAxisSpacing: _crossAxisSpacing,
              maxCrossAxisExtent: _maxCrossAxisExtent,
            ),
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            widget.setState?.call(this);
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> setStateBoilerplate(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}