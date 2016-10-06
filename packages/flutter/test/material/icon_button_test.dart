// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('IconButton test constrained size', (WidgetTester tester) async {
    const double kIconSize = 80.0;

    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {},
            icon: new Icon(Icons.ac_unit),
            size: kIconSize,
          )
        )
      )
    );

    RenderBox box = tester.renderObject(find.byType(IconButton));
    expect(box.size.width, equals(kIconSize));
    expect(box.size.height, equals(kIconSize));
  });

  testWidgets('IconButton AppBar size', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Scaffold(
        appBar: new AppBar(
          actions: <Widget>[
            new IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {},
              icon: new Icon(Icons.ac_unit),
            )
          ]
        )
      )
    );

    RenderBox barBox = tester.renderObject(find.byType(AppBar));
    RenderBox iconBox = tester.renderObject(find.byType(IconButton));
    expect(iconBox.size.height, equals(barBox.size.height));
  });
}
