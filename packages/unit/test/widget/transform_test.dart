// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  test('Transform origin', () {
    testWidgets((WidgetTester tester) {
      bool didReceiveTap = false;
      tester.pumpWidget(
        new Stack(<Widget>[
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
                transform: new Matrix4.identity().scale(0.5, 0.5),
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
        ])
      );

      expect(didReceiveTap, isFalse);
      tester.tapAt(new Point(110.0, 110.0));
      expect(didReceiveTap, isFalse);
      tester.tapAt(new Point(190.0, 150.0));
      expect(didReceiveTap, isTrue);
    });
  });

  test('Transform alignment', () {
    testWidgets((WidgetTester tester) {
      bool didReceiveTap = false;
      tester.pumpWidget(
        new Stack(<Widget>[
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
                transform: new Matrix4.identity().scale(0.5, 0.5),
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
        ])
      );

      expect(didReceiveTap, isFalse);
      tester.tapAt(new Point(110.0, 110.0));
      expect(didReceiveTap, isFalse);
      tester.tapAt(new Point(190.0, 150.0));
      expect(didReceiveTap, isTrue);
    });
  });

  test('Transform offset + alignment', () {
    testWidgets((WidgetTester tester) {
      bool didReceiveTap = false;
      tester.pumpWidget(
        new Stack(<Widget>[
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
                transform: new Matrix4.identity().scale(0.5, 0.5),
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
        ])
      );

      expect(didReceiveTap, isFalse);
      tester.tapAt(new Point(110.0, 110.0));
      expect(didReceiveTap, isFalse);
      tester.tapAt(new Point(190.0, 150.0));
      expect(didReceiveTap, isTrue);
    });
  });
}
