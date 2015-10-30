import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

class TestMultiChildLayoutDelegate extends MultiChildLayoutDelegate {
  BoxConstraints getSizeConstraints;

  Size getSize(BoxConstraints constraints) {
    getSizeConstraints = constraints;
    return new Size(200.0, 300.0);
  }

  Size performLayoutSize;
  BoxConstraints performLayoutConstraints;
  int performLayoutChildCount;
  Size performLayoutSize0;
  Size performLayoutSize1;

  void performLayout(Size size, BoxConstraints constraints, int childCount) {
    performLayoutSize = size;
    performLayoutConstraints = constraints;
    performLayoutChildCount = childCount;
    performLayoutSize0 = layoutChild(0, constraints);
    performLayoutSize1 = layoutChild(1, constraints);
  }
}

void main() {
  test('Control test for CustomMultiChildLayout', () {
    testWidgets((WidgetTester tester) {
      TestMultiChildLayoutDelegate delegate = new TestMultiChildLayoutDelegate();
      tester.pumpWidget(new Center(
        child: new CustomMultiChildLayout([
          new Container(width: 150.0, height: 100.0),
          new Container(width: 100.0, height: 200.0)
        ],
          delegate: delegate
        )
      ));

      expect(delegate.getSizeConstraints.minWidth, 0.0);
      expect(delegate.getSizeConstraints.maxWidth, 800.0);
      expect(delegate.getSizeConstraints.minHeight, 0.0);
      expect(delegate.getSizeConstraints.maxHeight, 600.0);

      expect(delegate.performLayoutSize.width, 200.0);
      expect(delegate.performLayoutSize.height, 300.0);
      expect(delegate.performLayoutConstraints.minWidth, 0.0);
      expect(delegate.performLayoutConstraints.maxWidth, 800.0);
      expect(delegate.performLayoutConstraints.minHeight, 0.0);
      expect(delegate.performLayoutConstraints.maxHeight, 600.0);
      expect(delegate.performLayoutChildCount, 2);
      expect(delegate.performLayoutSize0.width, 150.0);
      expect(delegate.performLayoutSize0.height, 100.0);
      expect(delegate.performLayoutSize1.width, 100.0);
      expect(delegate.performLayoutSize1.height, 200.0);
    });
  });
}
