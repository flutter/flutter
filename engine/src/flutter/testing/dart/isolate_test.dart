// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';

void main() {
  test('Invalid isolate URI', () async {
    var threw = false;
    try {
      await Isolate.spawnUri(Uri.parse('http://127.0.0.1/foo.dart'), <String>[], null);
    } on IsolateSpawnException {
      threw = true;
    }
    expect(threw, true);
  });

  test('UI isolate API throws in a background isolate', () async {
    void callUiApi(void message) {
      PlatformDispatcher.instance.onReportTimings = (_) {};
    }

    final errorPort = ReceivePort();
    await Isolate.spawn<void>(callUiApi, null, onError: errorPort.sendPort);
    final isolateError = await errorPort.first as List<dynamic>;
    expect(isolateError[0], 'UI actions are only available on root isolate.');
  });

  // Regression test: this used to crash the engine instead of throwing.
  test('loadFontFromList throws in a background isolate', () async {
    final Object? error = await Isolate.run(() async {
      try {
        await loadFontFromList(Uint8List(0));
      } catch (e) {
        return e;
      }
      return null;
    });
    expect(error, 'UI actions are only available on root isolate.');
  });

  test('loadFontFromList throws in a registered background isolate', () async {
    final RootIsolateToken token = RootIsolateToken.instance!;
    final Object? error = await Isolate.run(() async {
      PlatformDispatcher.instance.registerBackgroundIsolate(token);
      try {
        await loadFontFromList(Uint8List(0));
      } catch (e) {
        return e;
      }
      return null;
    });
    expect(error, 'UI actions are only available on root isolate.');
  });
}
