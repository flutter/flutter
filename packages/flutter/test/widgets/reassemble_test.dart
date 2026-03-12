// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets_app_tester.dart';

void main() {
  testWidgets('reassemble does not crash', (WidgetTester tester) async {
    await tester.pumpWidget(const TestWidgetsApp(home: Text('Hello World')));
    await tester.pump();
    tester.binding.reassembleApplication();
    await tester.pump();
  });
}
