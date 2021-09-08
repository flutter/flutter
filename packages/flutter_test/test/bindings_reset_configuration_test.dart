// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// This file contains tests for [testWidgets]. It is separated from bindings_test.dart
// because it relies on a persistent side effect (altered view configuration).

void main() {
  final AutomatedTestWidgetsFlutterBinding binding = AutomatedTestWidgetsFlutterBinding();
  group('testWidgets does not override pre-test viewConfiguration', () {
    // Many tests are written in this way that a view configuration is set at
    // the beginning of the file and is expected to take effect throughout the
    // file.
    binding.renderView.configuration = TestViewConfiguration(size: const Size(900, 900));

    // Run the same test twice to ensure that the view configuration is as
    // expected after a test.

    for (int times = 1; times <= 2; times += 1) {
      testWidgets('test $times', (WidgetTester tester) async {
        expect(binding.renderView.configuration.size, const Size(900, 900));
      });
    }
  });
}
