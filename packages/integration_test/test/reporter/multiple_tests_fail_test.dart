// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/common.dart';

import 'utils.dart';

void main() {
  test('When multiple tests fail', () async {
    final List<TestResult> results = await runAndCollectResults(_testMain);

    expect(results, <dynamic>[
      isFailure('Failing testWidgets()'),
      isFailure('Failing test()')
    ]);
  });
}

void _testMain() {
  testWidgets('Failing testWidgets()', (WidgetTester tester) async {
    expect(false, true);
  });

  test('Failing test()', () {
    expect(false, true);
  });
}
