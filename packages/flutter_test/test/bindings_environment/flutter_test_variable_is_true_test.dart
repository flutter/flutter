// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '$WidgetsBinding initializes with $AutomatedTestWidgetsFlutterBinding when FLUTTER_TEST = "true"',
    () {
      TestWidgetsFlutterBinding.ensureInitialized(<String, String>{'FLUTTER_TEST': 'true'});
      expect(WidgetsBinding.instance, isA<AutomatedTestWidgetsFlutterBinding>());
    },
  );
}
