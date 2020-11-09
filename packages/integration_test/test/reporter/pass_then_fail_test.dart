// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

void main() {
  test('when one test passes, then another fails', () async {
    final Map<String, Object> results = await runAndCollectResults(_testMain);
    expect(results, hasLength(2));
    expect(results, containsPair('Passing test', isSuccess));
    expect(results, containsPair('Failing test', isFailure));
  });
}

void _testMain() {
  testWidgets('Passing test', (WidgetTester tester) async {
    expect(true, true);
  });

  testWidgets('Failing test', (WidgetTester tester) async {
    expect(false, true);
  });
}
