// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('flutter_test timeout logic - addTime - positive', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 2500)); // must be longer than default timeout.
    }, additionalTime: const Duration(milliseconds: 2000)); // default timeout is 2s, so this makes it 4s.
  });
}
