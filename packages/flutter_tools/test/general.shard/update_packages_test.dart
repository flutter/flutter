// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/update_packages_pins.dart';

import '../src/common.dart';

void main() {
  testWithoutContext('kManuallyPinnedDependencies pins are actually pins', () {
    expect(
      kManuallyPinnedDependencies.values,
      isNot(contains(anyOf('any', startsWith('^'), startsWith('>'), startsWith('<')))),
      reason: 'Version pins in kManuallyPinnedDependencies must be specific pins, not ranges.',
    );
  });

  testWithoutContext('kManuallyPinnedDependencies explicitly pins archive', () {
    expect(kManuallyPinnedDependencies, containsPair('archive', '3.6.1'));
  });

  testWithoutContext('kExplicitlyExcludedPackages contains macro packages', () {
    expect(kExplicitlyExcludedPackages, containsAll(<String>['_macros', 'macros']));
  });
}
