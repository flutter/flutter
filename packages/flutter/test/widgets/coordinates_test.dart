// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Comparing coordinates', (WidgetTester tester) async {
    final Key keyA = new GlobalKey();
    final Key keyB = new GlobalKey();

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new Positioned(
            top: 100.0,
            left: 100.0,
            child: new SizedBox(
              key: keyA,
              width: 10.0,
              height: 10.0,
            ),
          ),
          new Positioned(
            left: 100.0,
            top: 200.0,
            child: new SizedBox(
              key: keyB,
              width: 20.0,
              height: 10.0,
            ),
          ),
        ],
      ),
    );

    final RenderBox boxA = tester.renderObject(find.byKey(keyA));
    expect(boxA.localToGlobal(const Offset(0.0, 0.0)), equals(const Offset(100.0, 100.0)));

    final RenderBox boxB = tester.renderObject(find.byKey(keyB));
    expect(boxB.localToGlobal(const Offset(0.0, 0.0)), equals(const Offset(100.0, 200.0)));
    expect(boxB.globalToLocal(const Offset(110.0, 205.0)), equals(const Offset(10.0, 5.0)));
  });
}
