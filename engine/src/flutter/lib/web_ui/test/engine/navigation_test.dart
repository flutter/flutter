// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart' as engine;

engine.TestUrlStrategy _strategy;

const engine.MethodCodec codec = engine.JSONMethodCodec();

void emptyCallback(ByteData date) {}

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUp(() async {
    _strategy = engine.TestUrlStrategy();
    await engine.window.debugInitializeHistory(_strategy, useSingle: true);
  });

  tearDown(() async {
    _strategy = null;
    await engine.window.debugResetHistory();
  });

  test('Tracks pushed, replaced and popped routes', () async {
    final Completer<void> completer = Completer<void>();
    engine.window.sendPlatformMessage(
      'flutter/navigation',
      codec.encodeMethodCall(const engine.MethodCall(
        'routeUpdated',
        <String, dynamic>{'routeName': '/foo'},
      )),
      (_) => completer.complete(),
    );
    await completer.future;
    expect(_strategy.getPath(), '/foo');
  });
}
