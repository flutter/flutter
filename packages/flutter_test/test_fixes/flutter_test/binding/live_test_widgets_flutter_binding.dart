// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = LiveTestWidgetsFlutterBinding.ensureInitialized();
  binding.runTest(
    () async {
      expect(true, isTrue);
    },
    () { },
    // This timeout will be removed and not replaced since there is no
    // equivalent API at this layer.
    timeout: Duration(minutes: 30),
  );
}