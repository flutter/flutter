// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('flutter_test timeout logic - addTime - positive', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 2500)); // must be longer than initial timeout below.
    }, additionalTime: const Duration(milliseconds: 2000)); // initial timeout is 2s, so this makes it 4s.
  }, initialTimeout: const Duration(milliseconds: 2000));
}
