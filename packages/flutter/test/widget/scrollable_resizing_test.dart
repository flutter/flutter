// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Resizing Scrollables', (WidgetTester tester) async {

    GlobalKey<ScrollableState> key = new GlobalKey<ScrollableState>();

    final Widget scrollable = new Block(
      scrollableKey: key,
      children: <Widget>[
        new Text('a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a'),
        new Text('a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a'),
        new Text('a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a'),
        new Text('a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a'),
        new Text('a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a'),
        new Text('a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a'),
        new Text('a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a'),
        new Text('a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a'),
        new Text('a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a'),
        new Text('a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a'),
      ],
    );

    await tester.pumpWidget(new Center(child: new SizedBox(
      width: 800.0,
      height: 200.0,
      child: scrollable,
    )));
    expect(key.currentState.scrollOffset, 0.0);

    key.currentState.scrollTo(200.0);
    expect(key.currentState.scrollOffset, 200.0);

    await tester.pumpWidget(new Center(child: new SizedBox(
      width: 200.0,
      height: 200.0,
      child: scrollable,
    )));
    expect(key.currentState.scrollOffset, 120.0);

  });
}
