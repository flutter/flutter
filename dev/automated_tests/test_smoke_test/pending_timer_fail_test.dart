// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

void main() {
  failingPendingTimerTest();
}

void failingPendingTimerTest() {
  testWidgets('flutter_test pending timer - negative', (WidgetTester tester) async {
    Timer(const Duration(minutes: 10), () {});
  });
}
