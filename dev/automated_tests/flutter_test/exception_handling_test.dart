// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Exception handling in test harness - string', (WidgetTester tester) async {
    throw 'Who lives, who dies, who tells your story?';
  });
  testWidgets('Exception handling in test harness - FlutterError', (WidgetTester tester) async {
    throw FlutterError('Who lives, who dies, who tells your story?');
  });
  testWidgets('Exception handling in test harness - uncaught Future error', (
    WidgetTester tester,
  ) async {
    Future<void>.error('Who lives, who dies, who tells your story?');
  });
}
