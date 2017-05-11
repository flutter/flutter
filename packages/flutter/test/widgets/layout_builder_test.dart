// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('LayoutBuilder parent size', (WidgetTester tester) async {
    Size layoutBuilderSize;
    final Key childKey = new UniqueKey();
    final Key parentKey = new UniqueKey();

    await tester.pumpWidget(
      new Center(
        child: new ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100.0, maxHeight: 200.0),
          child: new LayoutBuilder(
            key: parentKey,
            builder: (BuildContext context, BoxConstraints constraints) {
              layoutBuilderSize = constraints.biggest;
              return new SizedBox(
                key: childKey,
                width: layoutBuilderSize.width / 2.0,
                height: layoutBuilderSize.height / 2.0
              );
            }
          )
        )
      )
    );

    expect(layoutBuilderSize, const Size(100.0, 200.0));
    final RenderBox parentBox = tester.renderObject(find.byKey(parentKey));
    expect(parentBox.size, equals(const Size(50.0, 100.0)));
    final RenderBox childBox = tester.renderObject(find.byKey(childKey));
    expect(childBox.size, equals(const Size(50.0, 100.0)));
  });

  testWidgets('LayoutBuilder stateful child', (WidgetTester tester) async {
    Size layoutBuilderSize;
    StateSetter setState;
    final Key childKey = new UniqueKey();
    final Key parentKey = new UniqueKey();
    double childWidth = 10.0;
    double childHeight = 20.0;

    await tester.pumpWidget(
      new Center(
        child: new LayoutBuilder(
          key: parentKey,
          builder: (BuildContext context, BoxConstraints constraints) {
            layoutBuilderSize = constraints.biggest;
            return new StatefulBuilder(
              builder: (BuildContext context, StateSetter setter) {
                setState = setter;
                return new SizedBox(
                  key: childKey,
                  width: childWidth,
                  height: childHeight
                );
              }
            );
          }
        )
      )
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

  testWidgets('LayoutBuilder stateful parent', (WidgetTester tester) async {
    Size layoutBuilderSize;
    StateSetter setState;
    final Key childKey = new UniqueKey();
    double childWidth = 10.0;
    double childHeight = 20.0;

    await tester.pumpWidget(
      new Center(
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setter) {
            setState = setter;
            return new SizedBox(
              width: childWidth,
              height: childHeight,
              child: new LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  layoutBuilderSize = constraints.biggest;
                  return new SizedBox(
                    key: childKey,
                    width: layoutBuilderSize.width,
                    height: layoutBuilderSize.height
                  );
                }
              )
            );
          }
        )
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
    final Widget target = new LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        built += 1;
        return new Container();
      }
    );
    expect(built, 0);

    await tester.pumpWidget(new MediaQuery(
      data: const MediaQueryData(size: const Size(400.0, 300.0)),
      child: target
    ));
    expect(built, 1);

    await tester.pumpWidget(new MediaQuery(
      data: const MediaQueryData(size: const Size(300.0, 400.0)),
      child: target
    ));
    expect(built, 1);
  });

  testWidgets('LayoutBuilder and Inherited -- do rebuild when using inherited', (WidgetTester tester) async {
    int built = 0;
    final Widget target = new LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        built += 1;
        MediaQuery.of(context);
        return new Container();
      }
    );
    expect(built, 0);

    await tester.pumpWidget(new MediaQuery(
      data: const MediaQueryData(size: const Size(400.0, 300.0)),
      child: target
    ));
    expect(built, 1);

    await tester.pumpWidget(new MediaQuery(
      data: const MediaQueryData(size: const Size(300.0, 400.0)),
      child: target
    ));
    expect(built, 2);
  });
}
