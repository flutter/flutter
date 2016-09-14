// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'adb_test.dart' as adb_test;
import 'manifest_test.dart' as manifest_test;
import 'run_test.dart' as run_test;

void main() {
  adb_test.main();
  manifest_test.main();
  run_test.main();
}
