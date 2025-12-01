// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'setSemanticsTreeEnabled calls when the semantics is enabled before binding initialized',
    () async {
      final binding = SemanticsTestBindingWithInitialEnabled();
      expect(binding.platformDispatcher.semanticsTreeEnabled, isTrue);
    },
  );
}

class SemanticsTestBindingWithInitialEnabled extends AutomatedTestWidgetsFlutterBinding {
  @override
  TestPlatformDispatcherSpy get platformDispatcher => _platformDispatcherSpy;
  static final TestPlatformDispatcherSpy _platformDispatcherSpy = TestPlatformDispatcherSpy(
    platformDispatcher: PlatformDispatcher.instance,
  );
}

class TestPlatformDispatcherSpy extends TestPlatformDispatcher {
  TestPlatformDispatcherSpy({required super.platformDispatcher});
  bool semanticsTreeEnabled = false;
  @override
  void setSemanticsTreeEnabled(bool enabled) {
    semanticsTreeEnabled = enabled;
  }

  @override
  bool get semanticsEnabled => true;
}
