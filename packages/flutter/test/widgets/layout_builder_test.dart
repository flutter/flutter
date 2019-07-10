// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('LayoutBuilder parent size', (WidgetTester tester) async {
    Size layoutBuilderSize;
    final Key childKey = UniqueKey();
    final Key parentKey = UniqueKey();

    await tester.pumpWidget(
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100.0, maxHeight: 200.0),
          child: LayoutBuilder(
            key: parentKey,
            builder: (BuildContext context, BoxConstraints constraints) {
              layoutBuilderSize = constraints.biggest;
              return SizedBox(
                key: childKey,
                width: layoutBuilderSize.width / 2.0,
                height: layoutBuilderSize.height / 2.0,
              );
            },
          ),
        ),
      )
    );

    expect(layoutBuilderSize, const Size(100.0, 200.0));
    final RenderBox parentBox = tester.renderObject(find.byKey(parentKey));
    expect(parentBox.size, equals(const Size(50.0, 100.0)));
    final RenderBox childBox = tester.renderObject(find.byKey(childKey));
    expect(childBox.size, equals(const Size(50.0, 100.0)));
  });

  testWidgets('SliverLayoutBuilder parent geometry', (WidgetTester tester) async {
    SliverConstraints parentConstraints1;
    SliverConstraints parentConstraints2;
    final Key childKey1 = UniqueKey();
    final Key parentKey1 = UniqueKey();
    final Key childKey2 = UniqueKey();
    final Key parentKey2 = UniqueKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverLayoutBuilder(
              key: parentKey1,
              builder: (BuildContext context, SliverConstraints constraint) {
                parentConstraints1 = constraint;
                return SliverPadding(key: childKey1, padding: const EdgeInsets.fromLTRB(1, 2, 3, 4));
              },
            ),
            SliverLayoutBuilder(
              key: parentKey2,
              builder: (BuildContext context, SliverConstraints constraint) {
                parentConstraints2 = constraint;
                return SliverPadding(key: childKey2, padding: const EdgeInsets.fromLTRB(5, 7, 11, 13));
              },
            ),
          ],
        ),
      ),
    );

    expect(parentConstraints1.crossAxisExtent, 800);
    expect(parentConstraints1.remainingPaintExtent, 600);

    expect(parentConstraints2.crossAxisExtent, 800);
    expect(parentConstraints2.remainingPaintExtent, 600 - 2 - 4);
    final RenderSliver parentSliver1 = tester.renderObject(find.byKey(parentKey1));
    final RenderSliver parentSliver2 = tester.renderObject(find.byKey(parentKey2));
    // scrollExtent == top + bottom.
    expect(parentSliver1.geometry.scrollExtent, 2 + 4);
    expect(parentSliver2.geometry.scrollExtent, 7 + 13);

    final RenderSliver childSliver1 = tester.renderObject(find.byKey(childKey1));
    final RenderSliver childSliver2 = tester.renderObject(find.byKey(childKey2));
    expect(childSliver1.geometry, parentSliver1.geometry);
    expect(childSliver2.geometry, parentSliver2.geometry);
  });

  testWidgets('LayoutBuilder stateful child', (WidgetTester tester) async {
    Size layoutBuilderSize;
    StateSetter setState;
    final Key childKey = UniqueKey();
    final Key parentKey = UniqueKey();
    double childWidth = 10.0;
    double childHeight = 20.0;

    await tester.pumpWidget(
      Center(
        child: LayoutBuilder(
          key: parentKey,
          builder: (BuildContext context, BoxConstraints constraints) {
            layoutBuilderSize = constraints.biggest;
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setter) {
                setState = setter;
                return SizedBox(
                  key: childKey,
                  width: childWidth,
                  height: childHeight,
                );
              }
            );
          },
        ),
      ),
    );

    expect(layoutBuilderSize, equals(const Size(800.0, 600.0)));
    RenderBox parentBox = tester.renderObject(find.byKey(parentKey));
    expect(parentBox.size, equals(const Size(10.0, 20.0)));
    RenderBox childBox = tester.renderObject(find.byKey(childKey));
    expect(childBox.size, equals(const Size(10.0, 20.0)));

    setState(() {
      childWidth = 100.0;
      childHeight = 200.0;
    });
    await tester.pump();
    parentBox = tester.renderObject(find.byKey(parentKey));
    expect(parentBox.size, equals(const Size(100.0, 200.0)));
    childBox = tester.renderObject(find.byKey(childKey));
    expect(childBox.size, equals(const Size(100.0, 200.0)));
  });

  testWidgets('SliverLayoutBuilder stateful descendants', (WidgetTester tester) async {
    StateSetter setState;
    double childWidth = 10.0;
    double childHeight = 20.0;
    final Key parentKey = UniqueKey();
    final Key childKey = UniqueKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverLayoutBuilder(
              key: parentKey,
              builder: (BuildContext context, SliverConstraints constraint) {
                return SliverToBoxAdapter(
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setter) {
                      setState = setter;
                      return SizedBox(
                        key: childKey,
                        width: childWidth,
                        height: childHeight,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    RenderBox childBox = tester.renderObject(find.byKey(childKey));
    RenderSliver parentSliver = tester.renderObject(find.byKey(parentKey));
    expect(childBox.size.width, 800);
    expect(childBox.size.height, childHeight);
    expect(parentSliver.geometry.scrollExtent, childHeight);
    expect(parentSliver.geometry.paintExtent, childHeight);

    setState(() {
      childWidth = 100.0;
      childHeight = 200.0;
    });

    await tester.pump();
    childBox = tester.renderObject(find.byKey(childKey));
    parentSliver = tester.renderObject(find.byKey(parentKey));
    expect(childBox.size.width, 800);
    expect(childBox.size.height, childHeight);
    expect(parentSliver.geometry.scrollExtent, childHeight);
    expect(parentSliver.geometry.paintExtent, childHeight);

    setState(() {
        childWidth = 900.0;
        childHeight = 900.0;
    });

    await tester.pump();
    childBox = tester.renderObject(find.byKey(childKey));
    parentSliver = tester.renderObject(find.byKey(parentKey));
    expect(childBox.size.width, 800);
    expect(childBox.size.height, childHeight);
    expect(parentSliver.geometry.scrollExtent, childHeight);
    expect(parentSliver.geometry.paintExtent, 600);
  });


  testWidgets('LayoutBuilder stateful parent', (WidgetTester tester) async {
    Size layoutBuilderSize;
    StateSetter setState;
    final Key childKey = UniqueKey();
    double childWidth = 10.0;
    double childHeight = 20.0;

    await tester.pumpWidget(
      Center(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setter) {
            setState = setter;
            return SizedBox(
              width: childWidth,
              height: childHeight,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  layoutBuilderSize = constraints.biggest;
                  return SizedBox(
                    key: childKey,
                    width: layoutBuilderSize.width,
                    height: layoutBuilderSize.height,
                  );
                }
              ),
            );
          }
        ),
      )
    );

    expect(layoutBuilderSize, equals(const Size(10.0, 20.0)));
    RenderBox box = tester.renderObject(find.byKey(childKey));
    expect(box.size, equals(const Size(10.0, 20.0)));

    setState(() {
      childWidth = 100.0;
      childHeight = 200.0;
    });
    await tester.pump();
    box = tester.renderObject(find.byKey(childKey));
    expect(box.size, equals(const Size(100.0, 200.0)));
  });

  testWidgets('LayoutBuilder and Inherited -- do not rebuild when not using inherited', (WidgetTester tester) async {
    int built = 0;
    final Widget target = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        built += 1;
        return Container();
      }
    );
    expect(built, 0);

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(400.0, 300.0)),
      child: target,
    ));
    expect(built, 1);

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(300.0, 400.0)),
      child: target,
    ));
    expect(built, 1);
  });

  testWidgets('LayoutBuilder and Inherited -- do rebuild when using inherited', (WidgetTester tester) async {
    int built = 0;
    final Widget target = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        built += 1;
        MediaQuery.of(context);
        return Container();
      }
    );
    expect(built, 0);

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(400.0, 300.0)),
      child: target,
    ));
    expect(built, 1);

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(300.0, 400.0)),
      child: target,
    ));
    expect(built, 2);
  });

  testWidgets('SliverLayoutBuilder and Inherited -- do not rebuild when not using inherited',
    (WidgetTester tester) async {

    int built = 0;
    final Widget target = Directionality(
      textDirection: TextDirection.ltr,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverLayoutBuilder(
            builder: (BuildContext context, SliverConstraints constraint) {
              built++;
              return SliverToBoxAdapter(child: Container());
            },
          ),
        ],
      ),
    );

    expect(built, 0);

    await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(400.0, 300.0)),
        child: target,
    ));
    expect(built, 1);

    await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(300.0, 400.0)),
        child: target,
    ));
    expect(built, 1);
  });

  testWidgets('SliverLayoutBuilder and Inherited -- do rebuild when not using inherited',
    (WidgetTester tester) async {

      int built = 0;
      final Widget target = Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverLayoutBuilder(
              builder: (BuildContext context, SliverConstraints constraint) {
                built++;
                MediaQuery.of(context);
                return SliverToBoxAdapter(child: Container());
              },
            ),
          ],
        ),
      );

      expect(built, 0);

      await tester.pumpWidget(MediaQuery(
          data: const MediaQueryData(size: Size(400.0, 300.0)),
          child: target,
      ));
      expect(built, 1);

      await tester.pumpWidget(MediaQuery(
          data: const MediaQueryData(size: Size(300.0, 400.0)),
          child: target,
      ));
      expect(built, 2);
  });
}
