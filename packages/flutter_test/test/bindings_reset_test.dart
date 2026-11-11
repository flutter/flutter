// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Disposes restoration manager on reset.', () {
    final AutomatedTestWidgetsFlutterBinding binding =
        AutomatedTestWidgetsFlutterBinding.ensureInitialized();
    var oldCounter = 0;
    final TestRestorationManager oldRestorationManager = binding.restorationManager;
    oldRestorationManager.addListener(() => oldCounter++);

    oldRestorationManager.notifyListeners();
    expect(oldCounter, 1);

    binding.reset();
    expect(
      oldRestorationManager.notifyListeners,
      throwsA((Object e) => e.toString().contains('disposed')),
    );
  });

  test('Clears pending messages on reset.', () {
    final AutomatedTestWidgetsFlutterBinding binding =
        AutomatedTestWidgetsFlutterBinding.ensureInitialized();
    expect(binding.defaultBinaryMessenger.pendingMessageCount, 0);

    unawaited(binding.defaultBinaryMessenger.send('unanswered_channel', null));
    expect(binding.defaultBinaryMessenger.pendingMessageCount, 1);

    binding.reset();
    expect(binding.defaultBinaryMessenger.pendingMessageCount, 0);
  });
}
