// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Can access restoration manager without crashing', () {
    final AutomatedTestWidgetsFlutterBinding binding = AutomatedTestWidgetsFlutterBinding();
    expect(binding.restorationManager, isA<RestorationManager>());
  });
}
