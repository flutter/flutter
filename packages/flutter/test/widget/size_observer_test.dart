// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  test('SizeObserver notices zero size', () {
    testWidgets((WidgetTester tester) {
      List<Size> results = <Size>[];
      tester.pumpWidget(new Center(
        child: new SizeObserver(
          onSizeChanged: (Size size) { results.add(size); },
          child: new Container(width:0.0, height:0.0)
        )
      ));
      expect(results, equals([Size.zero]));
      tester.pump();
      expect(results, equals([Size.zero]));
      tester.pumpWidget(new Center(
        child: new SizeObserver(
          onSizeChanged: (Size size) { results.add(size); },
          child: new Container(width:100.0, height:0.0)
        )
      ));
      expect(results, equals([Size.zero, const Size(100.0, 0.0)]));
      tester.pump();
      expect(results, equals([Size.zero, const Size(100.0, 0.0)]));
      tester.pumpWidget(new Center(
        child: new SizeObserver(
          onSizeChanged: (Size size) { results.add(size); },
          child: new Container(width:0.0, height:0.0)
        )
      ));
      expect(results, equals([Size.zero, const Size(100.0, 0.0), Size.zero]));
      tester.pump();
      expect(results, equals([Size.zero, const Size(100.0, 0.0), Size.zero]));
      tester.pumpWidget(new Center(
        child: new SizeObserver(
          onSizeChanged: (Size size) { results.add(size); },
          child: new Container(width:0.0, height:0.0)
        )
      ));
      expect(results, equals([Size.zero, const Size(100.0, 0.0), Size.zero]));
    });
  });
}
