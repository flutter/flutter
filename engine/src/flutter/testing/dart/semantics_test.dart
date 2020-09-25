// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:ui';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

/// Verifies Semantics flags and actions.
void main() {
  // This must match the number of flags in lib/ui/semantics.dart
  const int numSemanticsFlags = 24;
  test('SemanticsFlag.values refers to all flags.', () async {
    expect(SemanticsFlag.values.length, equals(numSemanticsFlags));
    for (int index = 0; index < numSemanticsFlags; ++index) {
      final int flag = 1 << index;
      expect(SemanticsFlag.values[flag], isNotNull);
      expect(SemanticsFlag.values[flag].toString(), startsWith('SemanticsFlag.'));
    }
  });

  // This must match the number of actions in lib/ui/semantics.dart
  const int numSemanticsActions = 21;
  test('SemanticsAction.values refers to all actions.', () async {
    expect(SemanticsAction.values.length, equals(numSemanticsActions));
    for (int index = 0; index < numSemanticsActions; ++index) {
      final int flag = 1 << index;
      expect(SemanticsAction.values[flag], isNotNull);
      expect(SemanticsAction.values[flag].toString(), startsWith('SemanticsAction.'));
    }
  });
}
