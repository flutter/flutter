// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Intrinsic box', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(width: 100, height: 100),
              IntrinsicBox(width: 0, child: SizedBox(width: 200, height: 100)),
            ],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(IntrinsicWidth)), const Size(100, 200));

    expect(() {
      IntrinsicBox(width: -1);
    }, throwsAssertionError);
    expect(() {
      IntrinsicBox(height: -1);
    }, throwsAssertionError);
  });
}
