// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Can size according to aspect ratio', (WidgetTester tester) async {
    final Key outside = UniqueKey();
    final Key inside = UniqueKey();

    await tester.pumpWidget(
      Center(
        child: Container(
          width: 200.0,
          child: FittedBox(
            key: outside,
            child: Container(
              key: inside,
              width: 100.0,
              height: 50.0,
            )
          )
        )
      )
    );

    final RenderBox outsideBox = tester.firstRenderObject(find.byKey(outside));
    expect(outsideBox.size.width, 200.0);
    expect(outsideBox.size.height, 100.0);

    final RenderBox insideBox = tester.firstRenderObject(find.byKey(inside));
    expect(insideBox.size.width, 100.0);
    expect(insideBox.size.height, 50.0);

    final Offset insidePoint = insideBox.localToGlobal(const Offset(100.0, 50.0));
    final Offset outsidePoint = outsideBox.localToGlobal(const Offset(200.0, 100.0));

    expect(outsidePoint, equals(const Offset(500.0, 350.0)));
    expect(insidePoint, equals(outsidePoint));
  });

  testWidgets('Can contain child', (WidgetTester tester) async {
    final Key outside = UniqueKey();
    final Key inside = UniqueKey();

    await tester.pumpWidget(
      Center(
        child: Container(
          width: 200.0,
          height: 200.0,
          child: FittedBox(
            key: outside,
            child: Container(
              key: inside,
              width: 100.0,
              height: 50.0,
            )
          )
        )
      )
    );

    final RenderBox outsideBox = tester.firstRenderObject(find.byKey(outside));
    expect(outsideBox.size.width, 200.0);
    expect(outsideBox.size.height, 200.0);

    final RenderBox insideBox = tester.firstRenderObject(find.byKey(inside));
    expect(insideBox.size.width, 100.0);
    expect(insideBox.size.height, 50.0);

    final Offset insidePoint = insideBox.localToGlobal(const Offset(100.0, 0.0));
    final Offset outsidePoint = outsideBox.localToGlobal(const Offset(200.0, 50.0));

    expect(insidePoint, equals(outsidePoint));
  });

  testWidgets('Child can conver', (WidgetTester tester) async {
    final Key outside = UniqueKey();
    final Key inside = UniqueKey();

    await tester.pumpWidget(
      Center(
        child: Container(
          width: 200.0,
          height: 200.0,
          child: FittedBox(
            key: outside,
            fit: BoxFit.cover,
            child: Container(
              key: inside,
              width: 100.0,
              height: 50.0,
            )
          )
        )
      )
    );

    final RenderBox outsideBox = tester.firstRenderObject(find.byKey(outside));
    expect(outsideBox.size.width, 200.0);
    expect(outsideBox.size.height, 200.0);

    final RenderBox insideBox = tester.firstRenderObject(find.byKey(inside));
    expect(insideBox.size.width, 100.0);
    expect(insideBox.size.height, 50.0);

    final Offset insidePoint = insideBox.localToGlobal(const Offset(50.0, 25.0));
    final Offset outsidePoint = outsideBox.localToGlobal(const Offset(100.0, 100.0));

    expect(insidePoint, equals(outsidePoint));
  });

  testWidgets('FittedBox with no child', (WidgetTester tester) async {
    final Key key = UniqueKey();
    await tester.pumpWidget(
      Center(
        child: FittedBox(
          key: key,
          fit: BoxFit.cover,
        ),
      ),
    );

    final RenderBox box = tester.firstRenderObject(find.byKey(key));
    expect(box.size.width, 0.0);
    expect(box.size.height, 0.0);
  });

  testWidgets('Child can be aligned multiple ways in a row', (WidgetTester tester) async {
    final Key outside = UniqueKey();
    final Key inside = UniqueKey();

    { // align RTL

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: Container(
              width: 100.0,
              height: 100.0,
              child: FittedBox(
                key: outside,
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.bottomEnd,
                child: Container(
                  key: inside,
                  width: 10.0,
                  height: 10.0,
                ),
              ),
            ),
          ),
        ),
      );

      final RenderBox outsideBox = tester.firstRenderObject(find.byKey(outside));
      expect(outsideBox.size.width, 100.0);
      expect(outsideBox.size.height, 100.0);

      final RenderBox insideBox = tester.firstRenderObject(find.byKey(inside));
      expect(insideBox.size.width, 10.0);
      expect(insideBox.size.height, 10.0);

      final Offset insideTopLeft = insideBox.localToGlobal(const Offset(0.0, 0.0));
      final Offset outsideTopLeft = outsideBox.localToGlobal(const Offset(0.0, 90.0));
      final Offset insideBottomRight = insideBox.localToGlobal(const Offset(10.0, 10.0));
      final Offset outsideBottomRight = outsideBox.localToGlobal(const Offset(10.0, 100.0));

      expect(insideTopLeft, equals(outsideTopLeft));
      expect(insideBottomRight, equals(outsideBottomRight));
    }

    { // change direction

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Container(
              width: 100.0,
              height: 100.0,
              child: FittedBox(
                key: outside,
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.bottomEnd,
                child: Container(
                  key: inside,
                  width: 10.0,
                  height: 10.0,
                ),
              ),
            ),
          ),
        ),
      );

      final RenderBox outsideBox = tester.firstRenderObject(find.byKey(outside));
      expect(outsideBox.size.width, 100.0);
      expect(outsideBox.size.height, 100.0);

      final RenderBox insideBox = tester.firstRenderObject(find.byKey(inside));
      expect(insideBox.size.width, 10.0);
      expect(insideBox.size.height, 10.0);

      final Offset insideTopLeft = insideBox.localToGlobal(const Offset(0.0, 0.0));
      final Offset outsideTopLeft = outsideBox.localToGlobal(const Offset(90.0, 90.0));
      final Offset insideBottomRight = insideBox.localToGlobal(const Offset(10.0, 10.0));
      final Offset outsideBottomRight = outsideBox.localToGlobal(const Offset(100.0, 100.0));

      expect(insideTopLeft, equals(outsideTopLeft));
      expect(insideBottomRight, equals(outsideBottomRight));
    }

    { // change alignment

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Container(
              width: 100.0,
              height: 100.0,
              child: FittedBox(
                key: outside,
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.center,
                child: Container(
                  key: inside,
                  width: 10.0,
                  height: 10.0,
                ),
              ),
            ),
          ),
        ),
      );

      final RenderBox outsideBox = tester.firstRenderObject(find.byKey(outside));
      expect(outsideBox.size.width, 100.0);
      expect(outsideBox.size.height, 100.0);

      final RenderBox insideBox = tester.firstRenderObject(find.byKey(inside));
      expect(insideBox.size.width, 10.0);
      expect(insideBox.size.height, 10.0);

      final Offset insideTopLeft = insideBox.localToGlobal(const Offset(0.0, 0.0));
      final Offset outsideTopLeft = outsideBox.localToGlobal(const Offset(45.0, 45.0));
      final Offset insideBottomRight = insideBox.localToGlobal(const Offset(10.0, 10.0));
      final Offset outsideBottomRight = outsideBox.localToGlobal(const Offset(55.0, 55.0));

      expect(insideTopLeft, equals(outsideTopLeft));
      expect(insideBottomRight, equals(outsideBottomRight));
    }

    { // change size

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Container(
              width: 100.0,
              height: 100.0,
              child: FittedBox(
                key: outside,
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.center,
                child: Container(
                  key: inside,
                  width: 30.0,
                  height: 10.0,
                ),
              ),
            ),
          ),
        ),
      );

      final RenderBox outsideBox = tester.firstRenderObject(find.byKey(outside));
      expect(outsideBox.size.width, 100.0);
      expect(outsideBox.size.height, 100.0);

      final RenderBox insideBox = tester.firstRenderObject(find.byKey(inside));
      expect(insideBox.size.width, 30.0);
      expect(insideBox.size.height, 10.0);

      final Offset insideTopLeft = insideBox.localToGlobal(const Offset(0.0, 0.0));
      final Offset outsideTopLeft = outsideBox.localToGlobal(const Offset(35.0, 45.0));
      final Offset insideBottomRight = insideBox.localToGlobal(const Offset(30.0, 10.0));
      final Offset outsideBottomRight = outsideBox.localToGlobal(const Offset(65.0, 55.0));

      expect(insideTopLeft, equals(outsideTopLeft));
      expect(insideBottomRight, equals(outsideBottomRight));
    }

    { // change fit

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Container(
              width: 100.0,
              height: 100.0,
              child: FittedBox(
                key: outside,
                fit: BoxFit.fill,
                alignment: AlignmentDirectional.center,
                child: Container(
                  key: inside,
                  width: 30.0,
                  height: 10.0,
                ),
              ),
            ),
          ),
        ),
      );

      final RenderBox outsideBox = tester.firstRenderObject(find.byKey(outside));
      expect(outsideBox.size.width, 100.0);
      expect(outsideBox.size.height, 100.0);

      final RenderBox insideBox = tester.firstRenderObject(find.byKey(inside));
      expect(insideBox.size.width, 30.0);
      expect(insideBox.size.height, 10.0);

      final Offset insideTopLeft = insideBox.localToGlobal(const Offset(0.0, 0.0));
      final Offset outsideTopLeft = outsideBox.localToGlobal(const Offset(0.0, 0.0));
      final Offset insideBottomRight = insideBox.localToGlobal(const Offset(30.0, 10.0));
      final Offset outsideBottomRight = outsideBox.localToGlobal(const Offset(100.0, 100.0));

      expect(insideTopLeft, equals(outsideTopLeft));
      expect(insideBottomRight, equals(outsideBottomRight));
    }
  });

  testWidgets('FittedBox layers - contain', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          width: 100.0,
          height: 10.0,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 50.0,
              height: 50.0,
              child: RepaintBoundary(
                child: Placeholder(),
              ),
            ),
          ),
        ),
      ),
    );
    expect(getLayers(), <Type>[TransformLayer, TransformLayer, OffsetLayer]);
  });

  testWidgets('FittedBox layers - cover - horizontal', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          width: 100.0,
          height: 10.0,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 10.0,
              height: 50.0,
              child: RepaintBoundary(
                child: Placeholder(),
              ),
            ),
          ),
        ),
      ),
    );
    expect(getLayers(), <Type>[TransformLayer, ClipRectLayer, TransformLayer, OffsetLayer]);
  });

  testWidgets('FittedBox layers - cover - vertical', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          width: 10.0,
          height: 100.0,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 50.0,
              height: 10.0,
              child: RepaintBoundary(
                child: Placeholder(),
              ),
            ),
          ),
        ),
      ),
    );
    expect(getLayers(), <Type>[TransformLayer, ClipRectLayer, TransformLayer, OffsetLayer]);
  });

  testWidgets('FittedBox layers - none - clip', (WidgetTester tester) async {
    final List<double> values = <double>[10.0, 50.0, 100.0];
    for (double a in values) {
      for (double b in values) {
        for (double c in values) {
          for (double d in values) {
            await tester.pumpWidget(
              Center(
                child: SizedBox(
                  width: a,
                  height: b,
                  child: FittedBox(
                    fit: BoxFit.none,
                    child: SizedBox(
                      width: c,
                      height: d,
                      child: const RepaintBoundary(
                        child: Placeholder(),
                      ),
                    ),
                  ),
                ),
              ),
            );
            if (a < c || b < d) {
              expect(getLayers(), <Type>[TransformLayer, ClipRectLayer, OffsetLayer]);
            } else {
              expect(getLayers(), <Type>[TransformLayer, OffsetLayer]);
            }
          }
        }
      }
    }
  });

  testWidgets('Big child into small fitted box - hit testing', (WidgetTester tester) async {
    final GlobalKey key1 = GlobalKey();
    bool _pointerDown = false;
    await tester.pumpWidget(
      Center(
        child: SizedBox(
          width: 100.0,
          height: 100.0,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: FractionalOffset.center,
            child: SizedBox(
              width: 1000.0,
              height: 1000.0,
              child: Listener(
                onPointerDown: (PointerDownEvent event) {
                  _pointerDown = true;
                },
                child: Container(
                  key: key1,
                  color: const Color(0xFF000000),
                )
              )
            )
          )
        )
      )
    );
    expect(_pointerDown, isFalse);
    await tester.tap(find.byKey(key1));
    expect(_pointerDown, isTrue);
  });
}

List<Type> getLayers() {
  final List<Type> layers = <Type>[];
  Layer layer = RendererBinding.instance.renderView.debugLayer;
  while (layer is ContainerLayer) {
    final ContainerLayer container = layer;
    layers.add(container.runtimeType);
    expect(container.firstChild, same(container.lastChild));
    layer = container.firstChild;
  }
  return layers;
}
