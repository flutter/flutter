// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = LiveTestWidgetsFlutterBinding.ensureInitialized();
  binding.runTest(
    () async {},
    () {},
    // Changes made in https://github.com/flutter/flutter/pull/89952
    timeout: Duration(minutes: 30),
  );
}
