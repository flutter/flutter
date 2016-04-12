// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

Size _getSize(ElementTreeTester tester, BoxConstraints constraints, double aspectRatio) {
  Key childKey = new UniqueKey();
  tester.pumpWidget(
    new Center(
      child: new ConstrainedBox(
        constraints: constraints,
        child: new AspectRatio(
          aspectRatio: aspectRatio,
          child: new Container(
            key: childKey
          )
        )
      )
    )
  );
  RenderBox box = tester.findElementByKey(childKey).renderObject;
  return box.size;
}

void main() {
  test('Aspect ratio control test', () {
    testElementTree((ElementTreeTester tester) {
      expect(_getSize(tester, new BoxConstraints.loose(new Size(500.0, 500.0)), 2.0), equals(new Size(500.0, 250.0)));
      expect(_getSize(tester, new BoxConstraints.loose(new Size(500.0, 500.0)), 0.5), equals(new Size(250.0, 500.0)));
    });
  });

  test('Aspect ratio infinite width', () {
    testElementTree((ElementTreeTester tester) {
      Key childKey = new UniqueKey();
      tester.pumpWidget(
        new Center(
          child: new Viewport(
            mainAxis: Axis.horizontal,
            child: new AspectRatio(
              aspectRatio: 2.0,
              child: new Container(
                key: childKey
              )
            )
          )
        )
      );
      RenderBox box = tester.findElementByKey(childKey).renderObject;
      expect(box.size, equals(new Size(1200.0, 600.0)));
    });
  });
}
