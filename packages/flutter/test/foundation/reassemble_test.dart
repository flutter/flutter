// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import '../flutter_test_alternative.dart';

class TestFoundationFlutterBinding extends BindingBase {
  bool wasLocked;

  @override
  Future<void> performReassemble() async {
    wasLocked = locked;
    return super.performReassemble();
  }
}

TestFoundationFlutterBinding binding = TestFoundationFlutterBinding();

void main() {
  binding ??= TestFoundationFlutterBinding();

  test('Pointer events are locked during reassemble', () async {
    await binding.reassembleApplication();
    expect(binding.wasLocked, isTrue);
  });
}
