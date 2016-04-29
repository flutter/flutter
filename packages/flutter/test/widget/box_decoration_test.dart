// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  testWidgets('Circles can have uniform borders', (WidgetTester tester) {
    tester.pumpWidget(
      new Container(
        padding: new EdgeInsets.all(50.0),
        decoration: new BoxDecoration(
          shape: BoxShape.circle,
          border: new Border.all(width: 10.0, color: const Color(0x80FF00FF)),
          backgroundColor: Colors.teal[600]
        )
      )
    );
  });

  testWidgets('Bordered Container insets its child', (WidgetTester tester) {
    Key key = new Key('outerContainer');
    tester.pumpWidget(
      new Center(
        child: new Container(
          key: key,
          decoration: new BoxDecoration(border: new Border.all(width: 10.0)),
          child: new Container(
            width: 25.0,
            height: 25.0
          )
        )
      )
    );
    expect(tester.getSize(find.byKey(key)), equals(const Size(45.0, 45.0)));
  });
}
