// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

TestLocationStrategy _strategy;
TestLocationStrategy get strategy => _strategy;
set strategy(TestLocationStrategy newStrategy) {
  window.locationStrategy = _strategy = newStrategy;
}

void main() {
  test('window.defaultRouteName should not change', () {
    strategy = TestLocationStrategy.fromEntry(TestHistoryEntry('initial state', null, '/initial'));
    expect(window.defaultRouteName, '/initial');

    strategy.replaceState(null, null, '/newpath');
    expect(window.defaultRouteName, '/initial');
  });
}
