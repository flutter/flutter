// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

class _NoImplicitViewPlatformDispatcher extends TestPlatformDispatcher {
  _NoImplicitViewPlatformDispatcher() : super(platformDispatcher: PlatformDispatcher.instance);

  @override
  TestFlutterView? get implicitView => null;
}

class _NoImplicitViewTestBinding extends AutomatedTestWidgetsFlutterBinding {
  TestPlatformDispatcher? _testPlatformDispatcher;

  @override
  TestPlatformDispatcher get platformDispatcher =>
      _testPlatformDispatcher ??= _NoImplicitViewPlatformDispatcher();
}

void main() {
  final binding = _NoImplicitViewTestBinding();

  testWidgets('testWidgets supports an application without an implicit view', (
    WidgetTester tester,
  ) async {
    expect(binding.platformDispatcher.implicitView, isNull);
  });
}
