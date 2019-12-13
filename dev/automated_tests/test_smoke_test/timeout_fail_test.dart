// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('flutter_test timeout logic - addTime - negative', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 3500)); // must be more than 1000ms more than the initial timeout
    }, additionalTime: const Duration(milliseconds: 200));
  }, initialTimeout: const Duration(milliseconds: 2000));
}
