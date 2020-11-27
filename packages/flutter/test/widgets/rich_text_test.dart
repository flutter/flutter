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
}
