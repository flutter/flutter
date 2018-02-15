// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Can tap a hyperlink', (WidgetTester tester) async {
    bool didTapLeft = false;
    final TapGestureRecognizer tapLeft = new TapGestureRecognizer()
      ..onTap = () {
        didTapLeft = true;
      };

    bool didTapRight = false;
    final TapGestureRecognizer tapRight = new TapGestureRecognizer()
      ..onTap = () {
        didTapRight = true;
      };

    const Key textKey = const Key('text');

    await tester.pumpWidget(
      new Center(
        child: new RichText(
          key: textKey,
          textDirection: TextDirection.ltr,
          text: new TextSpan(
            children: <TextSpan>[
              new TextSpan(
                text: 'xxxxxxxx',
                recognizer: tapLeft
              ),
              const TextSpan(text: 'yyyyyyyy'),
              new TextSpan(
                text: 'zzzzzzzzz',
                recognizer: tapRight
              ),
            ]
          )
        )
      )
    );

    final RenderBox box = tester.renderObject(find.byKey(textKey));

    expect(didTapLeft, isFalse);
    expect(didTapRight, isFalse);

    await tester.tapAt(box.localToGlobal(Offset.zero) + const Offset(2.0, 2.0));

    expect(didTapLeft, isTrue);
    expect(didTapRight, isFalse);

    didTapLeft = false;

    await tester.tapAt(box.localToGlobal(Offset.zero) + const Offset(30.0, 2.0));

    expect(didTapLeft, isTrue);
    expect(didTapRight, isFalse);

    didTapLeft = false;

    await tester.tapAt(box.localToGlobal(new Offset(box.size.width, 0.0)) + const Offset(-2.0, 2.0));

    expect(didTapLeft, isFalse);
    expect(didTapRight, isTrue);
  });
}
