// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

class TestOneChildLayoutDelegate extends OneChildLayoutDelegate {
  BoxConstraints constraintsFromGetSize;
  BoxConstraints constraintsFromGetConstraintsForChild;
  Size sizeFromGetPositionForChild;
  Size childSizeFromGetPositionForChild;

  Size getSize(BoxConstraints constraints) {
    constraintsFromGetSize = constraints;
    return new Size(200.0, 300.0);
  }

  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    constraintsFromGetConstraintsForChild = constraints;
    return new BoxConstraints(
      minWidth: 100.0,
      maxWidth: 150.0,
      minHeight: 200.0,
      maxHeight: 400.0
    );
  }

  Point getPositionForChild(Size size, Size childSize) {
    sizeFromGetPositionForChild = size;
    childSizeFromGetPositionForChild = childSize;
    return Point.origin;
  }
}

void main() {
  test('Control test for CustomOneChildLayout', () {
    testWidgets((WidgetTester tester) {
      TestOneChildLayoutDelegate delegate = new TestOneChildLayoutDelegate();
      tester.pumpWidget(new Center(
        child: new CustomOneChildLayout(delegate: delegate, child: new Container())
      ));

      expect(delegate.constraintsFromGetSize.minWidth, 0.0);
      expect(delegate.constraintsFromGetSize.maxWidth, 800.0);
      expect(delegate.constraintsFromGetSize.minHeight, 0.0);
      expect(delegate.constraintsFromGetSize.maxHeight, 600.0);

      expect(delegate.constraintsFromGetConstraintsForChild.minWidth, 0.0);
      expect(delegate.constraintsFromGetConstraintsForChild.maxWidth, 800.0);
      expect(delegate.constraintsFromGetConstraintsForChild.minHeight, 0.0);
      expect(delegate.constraintsFromGetConstraintsForChild.maxHeight, 600.0);

      expect(delegate.sizeFromGetPositionForChild.width, 200.0);
      expect(delegate.sizeFromGetPositionForChild.height, 300.0);

      expect(delegate.childSizeFromGetPositionForChild.width, 150.0);
      expect(delegate.childSizeFromGetPositionForChild.height, 400.0);
    });
  });
}
