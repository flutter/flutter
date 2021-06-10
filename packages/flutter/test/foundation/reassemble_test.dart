// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class TestFoundationFlutterBinding extends BindingBase {
  bool? wasLocked;

  @override
  Future<void> performReassemble(DebugReassembleConfig reassembleConfig) async {
    wasLocked = locked;
    return super.performReassemble(reassembleConfig);
  }
}

TestFoundationFlutterBinding binding = TestFoundationFlutterBinding();

void main() {
  test('Pointer events are locked during reassemble', () async {
    final DebugReassembleConfig reassembleConfig = DebugReassembleConfig();
    await binding.reassembleApplication(reassembleConfig);
    expect(binding.wasLocked, isTrue);
  });
}
