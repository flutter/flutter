// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/driver_extension.dart';
import 'package:complex_layout/main.dart' as app;

// Avoid sensitivity to GC timing.
dynamic provokeSemispaceGrowth() {
  dynamic tree(int n) {
    return n == 0 ? null : <dynamic>[tree(n - 1), tree(n - 1)];
  }
  return tree(16);  // 2^16 * 6 words ~= 1.5 MB
}

void main() {
  provokeSemispaceGrowth();
  enableFlutterDriverExtension();
  app.main();
}
