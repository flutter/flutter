// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

const MethodCodec codec = JSONMethodCodec();

void emptyCallback(ByteData date) {}

TestLocationStrategy _strategy;
TestLocationStrategy get strategy => _strategy;
set strategy(TestLocationStrategy newStrategy) {
  window.locationStrategy = _strategy = newStrategy;
}

void main() {
  test('window.defaultRouteName should not change', () {
    strategy = TestLocationStrategy.fromEntry(TestHistoryEntry('initial state', null, '/initial'));
    expect(window.defaultRouteName, '/initial');

    // Changing the URL in the address bar later shouldn't affect [window.defaultRouteName].
    strategy.replaceState(null, null, '/newpath');
    expect(window.defaultRouteName, '/initial');
  });

  test('window.defaultRouteName should reset after navigation platform message', () {
    strategy = TestLocationStrategy.fromEntry(TestHistoryEntry('initial state', null, '/initial'));
    // Reading it multiple times should return the same value.
    expect(window.defaultRouteName, '/initial');
    expect(window.defaultRouteName, '/initial');

    window.sendPlatformMessage(
      'flutter/navigation',
      JSONMethodCodec().encodeMethodCall(MethodCall(
        'routePushed',
        <String, dynamic>{'previousRouteName': '/foo', 'routeName': '/bar'},
      )),
      emptyCallback,
    );
    // After a navigation platform message, [window.defaultRouteName] should
    // reset to "/".
    expect(window.defaultRouteName, '/');
  });
}
