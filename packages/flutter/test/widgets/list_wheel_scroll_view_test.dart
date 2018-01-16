// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../rendering/mock_canvas.dart';
import '../rendering/rendering_tester.dart';

void main() {
  testWidgets('ListWheelScrollView needs positive diameter ratio', (WidgetTester tester) async {
    try {
      new ListWheelScrollView(
        diameterRatio: -2.0,
        itemExtent: 20.0,
        children: <Widget>[],
      );
      fail('Expected failure with negative diameterRatio');
    } on AssertionError catch (exception) {
      expect(exception.message, contains("You can't set a diameterRatio of 0"));
    }
  });

  testWidgets('ListWheelScrollView needs positive item extent', (WidgetTester tester) async {
    expect(
      () {
        new ListWheelScrollView(
          itemExtent: null,
          children: <Widget>[new Container()],
        );
      },
      throwsAssertionError,
    );
  });

  testWidgets("ListWheelScrollView takes parent's size with small children", (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListWheelScrollView(
          // Inner children smaller than the outer window.
          itemExtent: 50.0,
          children: <Widget>[
            new Container(
              height: 50.0,
              color: const Color(0xFFFFFFFF),
            ),
          ],
        ),
      ),
    );
    expect(tester.getTopLeft(find.byType(ListWheelScrollView)), const Offset(0.0, 0.0));
    // Standard test screen size.
    expect(tester.getBottomRight(find.byType(ListWheelScrollView)), const Offset(800.0, 600.0));
  });

  testWidgets("ListWheelScrollView takes parent's size with large children", (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListWheelScrollView(
          // Inner children 5000.0px.
          itemExtent: 50.0,
          children: new List<Widget>.generate(100, (int index) {
            return new Container(
              height: 50.0,
              color: const Color(0xFFFFFFFF),
            );
          }),
        ),
      )
    );
    expect(tester.getTopLeft(find.byType(ListWheelScrollView)), const Offset(0.0, 0.0));
    // Still fills standard test screen size.
    expect(tester.getBottomRight(find.byType(ListWheelScrollView)), const Offset(800.0, 600.0));
  });

  testWidgets("ListWheelScrollView children can't be bigger than itemExtent", (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListWheelScrollView(
          itemExtent: 50.0,
          children: <Widget>[
            const SizedBox(
              height: 200.0,
              width: 200.0,
              child: const Center(
                child: const Text('blah'),
              ),
            ),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(SizedBox)), const Size(200.0, 50.0));
    expect(find.text('blah'), findsOneWidget);
  });

  testWidgets('ListWheelScrollView can have zero child', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListWheelScrollView(
          itemExtent: 50.0,
          children: <Widget>[],
        ),
      ),
    );
    expect(tester.getSize(find.byType(ListWheelScrollView)), const Size(800.0, 600.0));
  });

  testWidgets('ListWheelScrollView starts and ends from the middle', (WidgetTester tester) async {
    final ScrollController controller = new ScrollController();
    final List<int> paintedChildren = <int>[];

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListWheelScrollView(
          controller: controller,
          itemExtent: 100.0,
          children: new List<Widget>.generate(100, (int index) {
            return new CustomPaint(
              painter: new TestCallbackPainter(onPaint: () {
                paintedChildren.add(index);
              }),
            );
          }),
        ),
      ),
    );

    // Screen is 600px tall and the first item starts at 250px. The first 4
    // children are visible.
    expect(paintedChildren, <int>[0, 1, 2, 3]);

    controller.jumpTo(1000.0);
    paintedChildren.clear();

    await tester.pump();
    // Item number 10 is now in the middle of the screen at 250px. 9, 8, 7 are
    // visible before it and 11, 12, 13 are visible after it.
    expect(paintedChildren, <int>[7, 8, 9, 10, 11, 12, 13]);

    // Move to the last item.
    controller.jumpTo(9900.0);
    paintedChildren.clear();

    await tester.pump();
    // Item 99 is in the middle at 250px.
    expect(paintedChildren, <int>[96, 97, 98, 99]);
  });

  testWidgets('A child gets painted as soon as its first pixel is in the viewport', (WidgetTester tester) async {
    final ScrollController controller = new ScrollController(initialScrollOffset: 50.0);
    final List<int> paintedChildren = <int>[];

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListWheelScrollView(
          controller: controller,
          itemExtent: 100.0,
          children: new List<Widget>.generate(10, (int index) {
            return new CustomPaint(
              painter: new TestCallbackPainter(onPaint: () {
                paintedChildren.add(index);
              }),
            );
          }),
        ),
      ),
    );

    // Screen is 600px tall and the first item starts at 200px. The first 4
    // children are visible.
    expect(paintedChildren, <int>[0, 1, 2, 3]);

    paintedChildren.clear();
    // Move down by 1px.
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0.0, -1.0));
    await tester.pump();

    // Now the first pixel of item 5 enters the viewport.
    expect(paintedChildren, <int>[0, 1, 2, 3, 4]);
  });

  testWidgets('A child is no longer painted after its last pixel leaves the viewport', (WidgetTester tester) async {
    final ScrollController controller = new ScrollController(initialScrollOffset: 250.0);
    final List<int> paintedChildren = <int>[];

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListWheelScrollView(
          controller: controller,
          itemExtent: 100.0,
          children: new List<Widget>.generate(10, (int index) {
            return new CustomPaint(
              painter: new TestCallbackPainter(onPaint: () {
                paintedChildren.add(index);
              }),
            );
          }),
        ),
      ),
    );

    // The first item is at 0px and the 600px screen is full in the
    // **untransformed plane's viewport painting coordinates**
    expect(paintedChildren, <int>[0, 1, 2, 3, 4, 5]);

    paintedChildren.clear();
    // Go down another 99px.
    controller.jumpTo(349.0);
    await tester.pump();

    // One more item now visible with the last pixel of 0 showing.
    expect(paintedChildren, <int>[0, 1, 2, 3, 4, 5, 6]);

    paintedChildren.clear();
    // Go down one more pixel.
    controller.jumpTo(350.0);
    await tester.pump();

    // Item 0 no longer visible.
    expect(paintedChildren, <int>[1, 2, 3, 4, 5, 6]);
  });

  testWidgets('Default middle transform', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListWheelScrollView(
          itemExtent: 100.0,
          children: <Widget>[
            new Container(
              width: 200.0,
              child: const Center(
                child: const Text('blah'),
              ),
            ),
          ],
        ),
      ),
    );

    final RenderListWheelViewport viewport = tester.firstRenderObject(find.byType(Container)).parent;
    expect(viewport, paints..transform(
      matrix4: equals(<dynamic>[
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        -1.2 /* origin centering multiplied */, -0.9/* origin centering multiplied*/, 1.0, -0.003 /* inverse of perspective */,
        moreOrLessEquals(0.0), moreOrLessEquals(0.0), 0.0, moreOrLessEquals(1.0),
      ]),
    ));
  });

  testWidgets('Scrolling, diameterRatio, perspective all changes matrix', (WidgetTester tester) async {
    final ScrollController controller = new ScrollController(initialScrollOffset: 200.0);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListWheelScrollView(
          controller: controller,
          itemExtent: 100.0,
          children: <Widget>[
            new Container(
              width: 200.0,
              child: const Center(
                child: const Text('blah'),
              ),
            ),
          ],
        ),
      ),
    );

    final RenderListWheelViewport viewport = tester.firstRenderObject(find.byType(Container)).parent;
    expect(viewport, paints..transform(
      matrix4: equals(<dynamic>[
        1.0, 0.0, 0.0, 0.0,
        moreOrLessEquals(-0.41042417199080244), moreOrLessEquals(0.6318744917928065), moreOrLessEquals(0.3420201433256687), moreOrLessEquals(-0.0010260604299770061),
        moreOrLessEquals(-1.12763114494309), moreOrLessEquals(-1.1877435020329863), moreOrLessEquals(0.9396926207859084), moreOrLessEquals(-0.0028190778623577253),
        moreOrLessEquals(166.54856463138663), moreOrLessEquals(-62.20844875763376), moreOrLessEquals(-138.79047052615562), moreOrLessEquals(1.4163714115784667),
      ]),
    ));

    // Increase diameter.
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListWheelScrollView(
          controller: controller,
          diameterRatio: 3.0,
          itemExtent: 100.0,
          children: <Widget>[
            new Container(
              width: 200.0,
              child: const Center(
                child: const Text('blah'),
              ),
            ),
          ],
        ),
      ),
    );

    expect(viewport, paints..transform(
      matrix4: equals(<dynamic>[
        1.0, 0.0, 0.0, 0.0,
        moreOrLessEquals(-0.26954971336161726), moreOrLessEquals(0.7722830529455648), moreOrLessEquals(0.22462476113468105), moreOrLessEquals(-0.0006738742834040432),
        moreOrLessEquals(-1.1693344055601331), moreOrLessEquals(-1.101625565304781), moreOrLessEquals(0.9744453379667777), moreOrLessEquals(-0.002923336013900333),
        moreOrLessEquals(108.46394900436536), moreOrLessEquals(-113.14792465797223), moreOrLessEquals(-90.38662417030434), moreOrLessEquals(1.2711598725109134),
      ]),
    ));

    // Decrease perspective.
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListWheelScrollView(
          controller: controller,
          perspective: 0.0001,
          itemExtent: 100.0,
          children: <Widget>[
            new Container(
              width: 200.0,
              child: const Center(
                child: const Text('blah'),
              ),
            ),
          ],
        ),
      ),
    );

    expect(viewport, paints..transform(
      matrix4: equals(<dynamic>[
        1.0, 0.0, 0.0, 0.0,
        moreOrLessEquals(-0.01368080573302675), moreOrLessEquals(0.9294320164861384), moreOrLessEquals(0.3420201433256687), moreOrLessEquals(-0.000034202014332566874),
        moreOrLessEquals(-0.03758770483143634), moreOrLessEquals(-0.370210921949246), moreOrLessEquals(0.9396926207859084), moreOrLessEquals(-0.00009396926207859085),
        moreOrLessEquals(5.551618821046304), moreOrLessEquals(-182.95615811538906), moreOrLessEquals(-138.79047052615562), moreOrLessEquals(1.0138790470526158),
      ]),
    ));

    // Scroll a bit.
    controller.jumpTo(300.0);
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListWheelScrollView(
          controller: controller,
          itemExtent: 100.0,
          children: <Widget>[
            new Container(
              width: 200.0,
              child: const Center(
                child: const Text('blah'),
              ),
            ),
          ],
        ),
      )
    );

    expect(viewport, paints..transform(
      matrix4: equals(<dynamic>[
        1.0, 0.0, 0.0, 0.0,
        -0.6, moreOrLessEquals(0.41602540378443875), moreOrLessEquals(0.5), moreOrLessEquals(-0.0015),
        moreOrLessEquals(-1.0392304845413265), moreOrLessEquals(-1.2794228634059948), moreOrLessEquals(0.8660254037844387), moreOrLessEquals(-0.0025980762113533163),
        moreOrLessEquals(276.46170927520404), moreOrLessEquals(-52.46133917892857), moreOrLessEquals(-230.38475772933677), moreOrLessEquals(1.69115427318801),
      ]),
    ));
  });
}
