// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RichText with recognizers without handlers does not throw', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RichText(
          text: TextSpan(text: 'root', children: <InlineSpan>[
            TextSpan(text: 'one', recognizer: TapGestureRecognizer()),
            TextSpan(text: 'two', recognizer: LongPressGestureRecognizer()),
            TextSpan(text: 'three', recognizer: DoubleTapGestureRecognizer()),
          ]),
        ),
      ),
    );

    expect(tester.getSemantics(find.byType(RichText)), matchesSemantics(
      children: <Matcher>[
        matchesSemantics(
          label: 'root',
          hasTapAction: false,
          hasLongPressAction: false,
        ),
        matchesSemantics(
          label: 'one',
          hasTapAction: false,
          hasLongPressAction: false,
        ),
        matchesSemantics(
          label: 'two',
          hasTapAction: false,
          hasLongPressAction: false,
        ),
        matchesSemantics(
          label: 'three',
          hasTapAction: false,
          hasLongPressAction: false,
        ),
      ],
    ));
  });

  testWidgets('WidgetSpan calculate correct intrinsic heights', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/48679.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            color: Colors.green,
            child: IntrinsicHeight(
              child: RichText(
                text: TextSpan(
                  children: <InlineSpan>[
                    const TextSpan(text: 'Start\n', style: TextStyle(height: 1.0, fontSize: 16)),
                    WidgetSpan(
                      child: Row(
                        children: const <Widget>[
                          SizedBox(height: 16, width: 16,),
                        ],
                      ),
                    ),
                    const TextSpan(text: 'End', style: TextStyle(height: 1.0, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(IntrinsicHeight)).height, 3 * 16);
  });
}
