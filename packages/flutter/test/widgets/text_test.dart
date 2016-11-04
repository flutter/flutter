// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Text respects media query', (WidgetTester tester) async {
    await tester.pumpWidget(new MediaQuery(
      data: new MediaQueryData(textScaleFactor: 1.5),
      child: new Center(
        child: new Text('Hello')
      )
    ));

    RichText text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.5);

    await tester.pumpWidget(new Center(
      child: new Text('Hello')
    ));

    text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.0);

    await tester.pumpWidget(new Center(
      child: new Text('Hello', textScaleFactor: 3.0)
    ));

    text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 3.0);
  });
}
