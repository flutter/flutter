// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Can hit test flex children of stacks',
      (WidgetTester tester) async {
    bool didReceiveTap = false;
    await tester.pumpWidget(
      new Container(
        decoration: const BoxDecoration(
          backgroundColor: const Color(0xFF00FF00),
        ),
        child: new Stack(
          children: <Widget>[
            new Positioned(
              top: 10.0,
              left: 10.0,
              child: new Column(
                children: <Widget>[
                  new GestureDetector(
                    onTap: () {
                      didReceiveTap = true;
                    },
                    child: new Container(
                      decoration: const BoxDecoration(
                          backgroundColor: const Color(0xFF0000FF)),
                      width: 100.0,
                      height: 100.0,
                      child: new Center(
                        child: new Text('X'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('X'));
    expect(didReceiveTap, isTrue);
  });

  testWidgets('Flexible defaults to loose', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Row(
        children: <Widget>[
          new Flexible(child: new SizedBox(width: 100.0, height: 200.0)),
        ],
      ),
    );

    RenderBox box = tester.renderObject(find.byType(SizedBox));
    expect(box.size.width, 100.0);
  });

  testWidgets('Can pass null for flex', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Row(
        children: <Widget>[
          new Expanded(flex: null, child: new Text('one')),
          new Flexible(flex: null, child: new Text('two')),
        ],
      ),
    );
  });
}
