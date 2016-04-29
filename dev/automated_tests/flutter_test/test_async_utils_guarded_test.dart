// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Null> guardedHelper(WidgetTester tester) {
  return TestAsyncUtils.guard(() async {
    await tester.pumpWidget(new Text('Hello'));
  });
}

void main() {
  testWidgets('TestAsyncUtils - custom guarded sections', (WidgetTester tester) async {
    debugPrint = (String message, { int wrapWidth }) { print(message); };
    await tester.pumpWidget(new Container());
    expect(find.byElementType(Container), isNotNull);
    guardedHelper(tester);
    expect(find.byElementType(Container), isNull);
    // this should fail
  });
}
