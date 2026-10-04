// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appBuildName matches the FLUTTER_BUILD_NAME environment declaration', () {
    expect(
      appBuildName,
      const bool.hasEnvironment('FLUTTER_BUILD_NAME')
          ? const String.fromEnvironment('FLUTTER_BUILD_NAME')
          : null,
    );
  });

  test('appBuildNumber matches the FLUTTER_BUILD_NUMBER environment declaration', () {
    expect(
      appBuildNumber,
      const bool.hasEnvironment('FLUTTER_BUILD_NUMBER')
          ? const String.fromEnvironment('FLUTTER_BUILD_NUMBER')
          : null,
    );
  });
}
