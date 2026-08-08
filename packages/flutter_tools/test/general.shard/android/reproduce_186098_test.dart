// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/gradle_errors.dart';
import '../../src/common.dart';

void main() {
  test('kMigrateToBuiltInKotlinDocsUrl points to the correct anchor for reporting unmigrated plugins', () {
    expect(
      kMigrateToBuiltInKotlinDocsUrl,
      'https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers#report-incompatible-kotlin-gradle-plugin-usage-to-plugin-authors',
    );
  });
}
