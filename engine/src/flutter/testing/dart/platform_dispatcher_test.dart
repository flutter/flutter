// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:litetest/litetest.dart';

void main() {
  test('A ViewConfiguration asserts that both window and view are not provided', () {
    expectAssertion(() {
      return ViewConfiguration(
      // ignore: deprecated_member_use
        window: PlatformDispatcher.instance.views.first,
        view: PlatformDispatcher.instance.views.first,
      );
    });
  });

  test("A ViewConfiguration's view and window are backed with the same property", () {
    final FlutterView view = PlatformDispatcher.instance.views.first;
    final ViewConfiguration viewConfiguration = ViewConfiguration(view: view);
    // ignore: deprecated_member_use
    expect(viewConfiguration.window, view);
    // ignore: deprecated_member_use
    expect(viewConfiguration.window, viewConfiguration.view);
  });

  test('Initialize a ViewConfiguration with a window', () {
    final FlutterView view = PlatformDispatcher.instance.views.first;
    // ignore: deprecated_member_use
    ViewConfiguration(window: view);
  });

  test("copyWith() on a ViewConfiguration asserts that both a window aren't provided", () {
    final FlutterView view = PlatformDispatcher.instance.views.first;
    expectAssertion(() {
      // ignore: deprecated_member_use
      return ViewConfiguration(view: view)..copyWith(view: view, window: view);
    });
  });
}
