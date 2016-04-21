// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  testWidgets('Can tap a hyperlink', (WidgetTester tester) {
      bool didTapLeft = false;
      TapGestureRecognizer tapLeft = new TapGestureRecognizer()
        ..onTap = () {
          didTapLeft = true;
        };

      bool didTapRight = false;
      TapGestureRecognizer tapRight = new TapGestureRecognizer()
        ..onTap = () {
          didTapRight = true;
        };

      Key textKey = new Key('text');

      tester.pumpWidget(
        new Center(
          child: new RichText(
            key: textKey,
            text: new TextSpan(
              children: <TextSpan>[
                new TextSpan(
                  text: 'xxxxxxxx',
                  recognizer: tapLeft
                ),
                new TextSpan(text: 'yyyyyyyy'),
                new TextSpan(
                  text: 'zzzzzzzzz',
                  recognizer: tapRight
                ),
              ]
            )
          )
        )
      );

      RenderBox box = tester.renderObject(find.byKey(textKey));

      expect(didTapLeft, isFalse);
      expect(didTapRight, isFalse);

      tester.tapAt(box.localToGlobal(Point.origin) + new Offset(2.0, 2.0));

      expect(didTapLeft, isTrue);
      expect(didTapRight, isFalse);

      didTapLeft = false;

      tester.tapAt(box.localToGlobal(Point.origin) + new Offset(30.0, 2.0));

      expect(didTapLeft, isTrue);
      expect(didTapRight, isFalse);

      didTapLeft = false;

      tester.tapAt(box.localToGlobal(new Point(box.size.width, 0.0)) + new Offset(-2.0, 2.0));

      expect(didTapLeft, isFalse);
      expect(didTapRight, isTrue);
  });
}
