// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tests must restore the value of reportTestException', (WidgetTester tester) async {
    // This test is expected to fail.
    reportTestException = (FlutterErrorDetails details, String testDescription) {};
  });
}
