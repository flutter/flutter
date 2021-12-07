// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Initializes httpOverrides and testTextInput', () async {
    expect(HttpOverrides.current, null);
    final TestWidgetsFlutterBinding binding = CustomBindings();
    expect(WidgetsBinding.instance, isA<CustomBindings>());
    expect(binding.testTextInput.isRegistered, false);
    expect(HttpOverrides.current, null);
  });
}

class CustomBindings extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;

  @override
  bool get registerTestTextInput => false;
}
