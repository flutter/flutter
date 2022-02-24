// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('relayout boundary change does not trigger relayout', (WidgetTester tester) async {
    final LayoutCountWidget layoutCount = LayoutCountWidget();
    final Widget layoutCounter = Center(
      key: GlobalKey(),
      child: layoutCount,
    );

    await tester.pumpWidget(
      Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: Center(
                child: layoutCounter,
              ),
            ),
          ),
        ),
      ),
    );

    expect(layoutCount.layoutCount, 1);

    await tester.pumpWidget(
      Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: layoutCounter,
        ),
      ),
    );

    expect(layoutCount.layoutCount, 1);
  });
}

class LayoutCountWidget extends LeafRenderObjectWidget {
  LayoutCountWidget({ Key? key }) : super(key: key);

  final RenderLayoutCount renderObject = RenderLayoutCount();

  int get layoutCount => renderObject.layoutCount;
  set layoutCount(int newValue) {
    renderObject.layoutCount = newValue;
  }

  @override
  RenderObject createRenderObject(BuildContext context) => renderObject;
}

// This class is needed because LayoutBuilder's RenderObject does not always
// call the builder in its PerformLayout method.
class RenderLayoutCount extends RenderBox {
  int layoutCount = 0;

  @override
  void performLayout() {
    layoutCount += 1;
    size = constraints.biggest;
  }
}
