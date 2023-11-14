// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart' as engine;
import 'package:ui/src/engine/window.dart';
import 'package:ui/ui.dart' as ui;

const engine.MethodCodec codec = engine.JSONMethodCodec();

engine.EngineFlutterWindow get implicitView =>
    engine.EnginePlatformDispatcher.instance.implicitView!;

void emptyCallback(ByteData date) {}

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  engine.TestUrlStrategy? strategy;

  setUpAll(() {
    ensureImplicitViewInitialized();
  });

  setUp(() async {
    strategy = engine.TestUrlStrategy();
    await implicitView.debugInitializeHistory(strategy, useSingle: true);
  });

  tearDown(() async {
    strategy = null;
    await implicitView.resetHistory();
  });

  test('Tracks pushed, replaced and popped routes', () async {
    final Completer<void> completer = Completer<void>();
    ui.PlatformDispatcher.instance.sendPlatformMessage(
      'flutter/navigation',
      codec.encodeMethodCall(const engine.MethodCall(
        'routeUpdated',
        <String, dynamic>{'routeName': '/foo'},
      )),
      (_) => completer.complete(),
    );
    await completer.future;
    expect(strategy!.getPath(), '/foo');
  });
}
