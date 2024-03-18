// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:web/web.dart' as web;

// Attempt to load CanvasKit resources hosted on gstatic.
Future<void> main() async {
  const String engineVersion = String.fromEnvironment('TEST_FLUTTER_ENGINE_VERSION');
  if (engineVersion.isEmpty) {
    print('--- TEST FAILED ---');
    return;
  }
  try {
    final web.Response response = await web.window.fetch(
      'https://www.gstatic.com/flutter-canvaskit/$engineVersion/canvaskit.js'.toJS,
      web.RequestInit(
        method: 'GET',
      ),
    ).toDart;
    if (response.ok) {
      print('--- TEST SUCCEEDED ---');
    } else {
      print('--- TEST FAILED ---');
    }
  } catch (err) {
    print(err);
    print('--- TEST FAILED ---');
  }
  try {
    final web.Response response = await web.window.fetch(
      'https://www.gstatic.com/flutter-canvaskit/$engineVersion/canvaskit.wasm'.toJS,
      web.RequestInit(
        method: 'GET',
      )
    ).toDart;
    if (response.ok) {
      print('--- TEST SUCCEEDED ---');
    } else {
      print('--- TEST FAILED ---');
    }
  } catch (err) {
    print(err);
    print('--- TEST FAILED ---');
  }
}
