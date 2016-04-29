// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Null> helperFunction(WidgetTester tester) async {
  await tester.pump();
}

void main() {
  testWidgets('TestAsyncUtils - handling unguarded async helper functions', (WidgetTester tester) async {
    debugPrint = (String message, { int wrapWidth }) { print(message); };
    helperFunction(tester);
    helperFunction(tester);
    // this should fail
  });
}
