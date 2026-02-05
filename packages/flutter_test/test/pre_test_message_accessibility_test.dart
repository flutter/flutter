// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Verifies that the pre-test message shown by flutter_test
  /// meets the minimum WCAG text contrast accessibility guideline.
  testWidgets('pre-test message meets text contrast guideline', (WidgetTester tester) async {
    // The pre-test message is already attached to the render tree by the
    // TestWidgetsFlutterBinding before this test runs, so no pumpWidget is needed.
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
