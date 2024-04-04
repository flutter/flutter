// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:litetest/litetest.dart' as litetest;

// A group of tests that must be run without concurrency.
// This is useful for tests that modify global state.
class SerializedTestSuite {
  Completer<void>? _previousTestCompleter;

  void test(String name, Future<void> Function() body) {
    final Completer<void>? lastTestCompleter = _previousTestCompleter;
    final Completer<void> currentTestCompleter = Completer<void>();
    _previousTestCompleter = currentTestCompleter;
    Future<void> wrappedBody() async {
      if (lastTestCompleter != null) {
        await lastTestCompleter.future;
      }
      await body();
      currentTestCompleter.complete();
    }
    litetest.test(name, wrappedBody);
  }
}
