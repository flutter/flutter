// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class _PaintInstructionMatcher extends Matcher {
  _PaintInstructionMatcher(this.instruction);

  final (Symbol, List<Object?>) instruction;

  @override
  Description describe(Description description) {
    return description.add('instruction: $instruction');
  }

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! (Symbol, List<Object?>) || item.$1 != instruction.$1) {
      return false;
    }
    final List<Object?> argList1 = instruction.$2;
    final List<Object?> argList2 = item.$2;
    if (argList1.length != argList2.length) {
      return false;
    }
    for (int i = 0; i < argList1.length; i += 1) {
      final Object? arg1 = argList1[i];
      final Object? arg2 = argList2[i];
      if (arg1 == arg2) {
        continue;
      }
      // Paint currently does not implement `==`.
      if (arg1 is Paint && arg1.toString() != arg2.toString()) {
        return false;
      }
    }
    return true;
  }
}

double? verifyDryBaseline(RenderBox box) {
  assert(!box.debugNeedsLayout);
  final List<(Symbol, List<Object?>)> beforePaintInstructions = <(Symbol, List<Object?>)>[];
  expect(box,
    anyOf(
      paints..everything((Symbol methodName, List<Object?> arguments) {
        beforePaintInstructions.add((methodName, arguments));
        return true;
      }),
      paintsNothing,
    ),
  );

  for (final TextBaseline baseline in TextBaseline.values) {
    expect(
      box.getDryBaseline(box.constraints, baseline),
      box.debugGetDistanceToBaseline(baseline),
      reason: 'getDryBaseline(${box.constraints}, $baseline) should be consistent with getDistanceToBaseline',
    );
  }
  final List<(Symbol, List<Object?>)> afterPaintInstructions = <(Symbol, List<Object?>)>[];
  expect(box,
    anyOf(
      paints..everything((Symbol methodName, List<Object?> arguments) {
        afterPaintInstructions.add((methodName, arguments));
        return true;
      }),
      paintsNothing,
    ),
  );

  expect(beforePaintInstructions, equals(afterPaintInstructions.map(_PaintInstructionMatcher.new)));
  return box.getDryBaseline(box.constraints, TextBaseline.alphabetic);
}
