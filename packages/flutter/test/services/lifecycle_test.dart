// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/scheduler.dart';

void main() {
  test('handleAppLifecycleStateChanged fires for lifecycle messages', () async {
    final TestServicesBinding binding = TestServicesBinding();
    expect(binding.states, isEmpty);
    await _sendLifecycle(AppLifecycleState.inactive);
    expect(binding.states, <AppLifecycleState>[AppLifecycleState.inactive]);
    await _sendLifecycle(AppLifecycleState.detached);
    expect(binding.states, <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.detached,
    ]);
  });
}

Future<void> _sendLifecycle(AppLifecycleState state) {
  return ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.lifecycle.name,
    SystemChannels.lifecycle.codec.encodeMessage(state?.toString()),
    (ByteData data) {},
  );
}

class TestServicesBinding extends BindingBase with ServicesBinding {
  final List<AppLifecycleState> states = <AppLifecycleState>[];

  @override
  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    super.handleAppLifecycleStateChanged(state);
    states.add(state);
  }
}
