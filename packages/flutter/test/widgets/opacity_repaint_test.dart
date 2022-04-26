// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RenderOpacity acts as a repaint boundary for changes above the widget when partially opaque', (WidgetTester tester) async {
    RenderTestObject.paintCount = 0;
    await tester.pumpWidget(
      Container(
        color: Colors.red,
        child: const Opacity(
          opacity: 0.5,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);

    await tester.pumpWidget(
      Container(
        color: Colors.blue,
        child: const Opacity(
          opacity: 0.5,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);
  });

  testWidgets('RenderOpacity acts as a repaint boundary for changes above the widget when fully opaque', (WidgetTester tester) async {
    RenderTestObject.paintCount = 0;
    await tester.pumpWidget(
      Container(
        color: Colors.red,
        child: const Opacity(
          opacity: 1,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);

    await tester.pumpWidget(
      Container(
        color: Colors.blue,
        child: const Opacity(
          opacity: 1,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);
  });

  testWidgets('RenderOpacity can update its opacity without repainting its child - partially opaque to partially opaque', (WidgetTester tester) async {
    RenderTestObject.paintCount = 0;
    await tester.pumpWidget(
      Container(
        color: Colors.red,
        child: const Opacity(
          opacity: 0.5,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);

    await tester.pumpWidget(
      Container(
        color: Colors.blue,
        child: const Opacity(
          opacity: 0.9,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);
  });

  testWidgets('RenderOpacity can update its opacity without repainting its child - partially opaque to fully opaque', (WidgetTester tester) async {
    RenderTestObject.paintCount = 0;
    await tester.pumpWidget(
      Container(
        color: Colors.red,
        child: const Opacity(
          opacity: 0.5,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);

    await tester.pumpWidget(
      Container(
        color: Colors.blue,
        child: const Opacity(
          opacity: 1,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);
  });

  testWidgets('RenderOpacity can update its opacity without repainting its child - fully opaque to partially opaque', (WidgetTester tester) async {
    RenderTestObject.paintCount = 0;
    await tester.pumpWidget(
      Container(
        color: Colors.red,
        child: const Opacity(
          opacity: 1,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);

    await tester.pumpWidget(
      Container(
        color: Colors.blue,
        child: const Opacity(
          opacity: 0.5,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);
  });

  testWidgets('RenderOpacity can update its opacity without repainting its child - fully opaque to fully transparent', (WidgetTester tester) async {
    RenderTestObject.paintCount = 0;
    await tester.pumpWidget(
      Container(
        color: Colors.red,
        child: const Opacity(
          opacity: 1,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);

    await tester.pumpWidget(
      Container(
        color: Colors.blue,
        child: const Opacity(
          opacity: 0,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);
  });

  testWidgets('RenderOpacity must paint child - fully transparent to partially opaque', (WidgetTester tester) async {
    RenderTestObject.paintCount = 0;
    await tester.pumpWidget(
      Container(
        color: Colors.red,
        child: const Opacity(
          opacity: 0,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 0);

    await tester.pumpWidget(
      Container(
        color: Colors.blue,
        child: const Opacity(
          opacity: 0.5,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);
  });

  testWidgets('RenderOpacity allows child to update without updating parent', (WidgetTester tester) async {
    RenderTestObject.paintCount = 0;
    await tester.pumpWidget(
      TestWidget(
        child: Opacity(
          opacity: 0.5,
          child: Container(
            color: Colors.red,
          ),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);

    await tester.pumpWidget(
      TestWidget(
        child: Opacity(
          opacity: 0.5,
          child: Container(
            color: Colors.blue,
          ),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);
  });

  testWidgets('RenderOpacity disposes of opacity layer when opacity is updated to 0', (WidgetTester tester) async {
    RenderTestObject.paintCount = 0;
    await tester.pumpWidget(
      Container(
        color: Colors.red,
        child: const Opacity(
          opacity: 0.5,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);
    expect(tester.layers, contains(isA<OpacityLayer>()));

    await tester.pumpWidget(
      Container(
        color: Colors.blue,
        child: const Opacity(
          opacity: 0,
          child: TestWidget(),
        ),
      )
    );

    expect(RenderTestObject.paintCount, 1);
    expect(tester.layers, isNot(contains(isA<OpacityLayer>())));
  });
}

class TestWidget extends SingleChildRenderObjectWidget {
  const TestWidget({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTestObject();
  }
}

class RenderTestObject extends RenderProxyBox {
  static int paintCount = 0;

  @override
  void paint(PaintingContext context, Offset offset) {
    paintCount += 1;
    super.paint(context, offset);
  }
}
