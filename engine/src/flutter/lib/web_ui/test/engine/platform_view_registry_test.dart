// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui_web/src/ui_web.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('platformViewRegistry can be overridden', () {
    final PlatformViewRegistry defaultRegistry = platformViewRegistry;
    final PlatformViewRegistry overrideRegistry = MockPlatformViewRegistry();

    debugOverridePlatformViewRegistry(overrideRegistry);
    expect(platformViewRegistry, overrideRegistry);

    debugOverridePlatformViewRegistry(null);
    expect(platformViewRegistry, defaultRegistry);
  });
}

/// A fake implementation of [PlatformViewRegistry] for testing.
class MockPlatformViewRegistry implements PlatformViewRegistry {
  MockPlatformViewRegistry();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
