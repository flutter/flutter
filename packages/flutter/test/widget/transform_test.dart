// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Transform origin', (WidgetTester tester) async {
    bool didReceiveTap = false;
    await tester.pumpWidget(
      new Stack(
        children: <Widget>[
          new Positioned(
            top: 100.0,
            left: 100.0,
            child: new Container(
              width: 100.0,
              height: 100.0,
              decoration: new BoxDecoration(
                backgroundColor: new Color(0xFF0000FF)
              )
            )
          ),
          new Positioned(
            top: 100.0,
            left: 100.0,
            child: new Container(
              width: 100.0,
              height: 100.0,
              child: new Transform(
                transform: new Matrix4.diagonal3Values(0.5, 0.5, 1.0),
                origin: new Offset(100.0, 50.0),
                child: new GestureDetector(
                  onTap: () {
                    didReceiveTap = true;
                  },
                  child: new Container(
                    decoration: new BoxDecoration(
                      backgroundColor: new Color(0xFF00FFFF)
                    )
                  )
                )
              )
            )
          )
        ]
      )
    );

    expect(didReceiveTap, isFalse);
    await tester.tapAt(new Point(110.0, 110.0));
    expect(didReceiveTap, isFalse);
    await tester.tapAt(new Point(190.0, 150.0));
    expect(didReceiveTap, isTrue);
  });

  testWidgets('Transform alignment', (WidgetTester tester) async {
    bool didReceiveTap = false;
    await tester.pumpWidget(
      new Stack(
        children: <Widget>[
          new Positioned(
            top: 100.0,
            left: 100.0,
            child: new Container(
              width: 100.0,
              height: 100.0,
              decoration: new BoxDecoration(
                backgroundColor: new Color(0xFF0000FF)
              )
            )
          ),
          new Positioned(
            top: 100.0,
            left: 100.0,
            child: new Container(
              width: 100.0,
              height: 100.0,
              child: new Transform(
                transform: new Matrix4.diagonal3Values(0.5, 0.5, 1.0),
                alignment: new FractionalOffset(1.0, 0.5),
                child: new GestureDetector(
                  onTap: () {
                    didReceiveTap = true;
                  },
                  child: new Container(
                    decoration: new BoxDecoration(
                      backgroundColor: new Color(0xFF00FFFF)
                    )
                  )
                )
              )
            )
          )
        ]
      )
    );

    expect(didReceiveTap, isFalse);
    await tester.tapAt(new Point(110.0, 110.0));
    expect(didReceiveTap, isFalse);
    await tester.tapAt(new Point(190.0, 150.0));
    expect(didReceiveTap, isTrue);
  });

  testWidgets('Transform offset + alignment', (WidgetTester tester) async {
    bool didReceiveTap = false;
    await tester.pumpWidget(
      new Stack(
        children: <Widget>[
          new Positioned(
            top: 100.0,
            left: 100.0,
            child: new Container(
              width: 100.0,
              height: 100.0,
              decoration: new BoxDecoration(
                backgroundColor: new Color(0xFF0000FF)
              )
            )
          ),
          new Positioned(
            top: 100.0,
            left: 100.0,
            child: new Container(
              width: 100.0,
              height: 100.0,
              child: new Transform(
                transform: new Matrix4.diagonal3Values(0.5, 0.5, 1.0),
                origin: new Offset(100.0, 0.0),
                alignment: new FractionalOffset(0.0, 0.5),
                child: new GestureDetector(
                  onTap: () {
                    didReceiveTap = true;
                  },
                  child: new Container(
                    decoration: new BoxDecoration(
                      backgroundColor: new Color(0xFF00FFFF)
                    )
                  )
                )
              )
            )
          )
        ]
      )
    );

    expect(didReceiveTap, isFalse);
    await tester.tapAt(new Point(110.0, 110.0));
    expect(didReceiveTap, isFalse);
    await tester.tapAt(new Point(190.0, 150.0));
    expect(didReceiveTap, isTrue);
  });
}
