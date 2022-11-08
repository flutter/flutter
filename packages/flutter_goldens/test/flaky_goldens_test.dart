// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See also dev/automated_tests/flutter_test/flutter_gold_test.dart

// flutter_ignore_for_file: golden_tag (see analyze.dart)

import 'package:flutter_goldens/flutter_goldens.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/fakes.dart';

void main() {
  test('Sets flaky flag', () {
    final FakeFlakyLocalFileComparator comparator = FakeFlakyLocalFileComparator();
    // Is not flaky
    expect(comparator.getAndResetFlakyMode(), isFalse);
    comparator.enableFlakyMode();
    // Flaky was set
    expect(comparator.getAndResetFlakyMode(), isTrue);
    // Flaky was unset
    expect(comparator.getAndResetFlakyMode(), isFalse);
  });

  test('Asserts when comparator is missing mixin', (){
    final GoldenFileComparator oldComparator = goldenFileComparator;
    goldenFileComparator = FakeLocalFileComparator();
    expect(
      () {
        expect(
          expectFlakyGolden(<int>[0, 1, 2, 3], 'golden_file.png'),
          throwsAssertionError,
        );
      },
      throwsA(
        isA<AssertionError>().having((AssertionError error) => error.toString(),
          'description', contains('FlakyGoldenMixin')),
      ),
    );
    goldenFileComparator = oldComparator;
  });

  test('top level function sets flag', () {
    final GoldenFileComparator oldComparator = goldenFileComparator;
    goldenFileComparator = FakeFlakyLocalFileComparator();
    expectFlakyGolden(<int>[0, 1, 2, 3], 'golden_file.png');
    final bool wasFlaky = (goldenFileComparator as FakeFlakyLocalFileComparator).getAndResetFlakyMode();
    expect(wasFlaky, isTrue);
    goldenFileComparator = oldComparator;
  });
}
