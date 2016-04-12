// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'flutter_driver_test.dart' as flutter_driver_test;
import 'src/retry_test.dart' as retry_test;
import 'src/timeline_test.dart' as timeline_test;
import 'src/timeline_summary_test.dart' as timeline_summary_test;

void main() {
  flutter_driver_test.main();
  retry_test.main();
  timeline_summary_test.main();
  timeline_test.main();
}
