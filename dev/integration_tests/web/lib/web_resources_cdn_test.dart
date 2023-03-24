// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

// Attempt to load CanvasKit resources hosted on gstatic.
Future<void> main() async {
  const String engineVersion = String.fromEnvironment('TEST_FLUTTER_ENGINE_VERSION');
  if (engineVersion.isEmpty) {
    print('--- TEST FAILED ---');
    return;
  }
  try {
    final html.HttpRequest request = await html.HttpRequest.request(
      'https://www.gstatic.com/flutter-canvaskit/$engineVersion/canvaskit.js',
      method: 'GET',
    );
    final dynamic response = request.response;
    if (response != null) {
      print('--- TEST SUCCEEDED ---');
    } else {
      print('--- TEST FAILED ---');
    }
  } catch (err) {
    print(err);
    print('--- TEST FAILED ---');
  }
  try {
    final html.HttpRequest request = await html.HttpRequest.request(
      'https://www.gstatic.com/flutter-canvaskit/$engineVersion/canvaskit.wasm',
      method: 'GET',
    );
    final dynamic response = request.response;
    if (response != null) {
      print('--- TEST SUCCEEDED ---');
    } else {
      print('--- TEST FAILED ---');
    }
  } catch (err) {
    print(err);
    print('--- TEST FAILED ---');
  }
}
