// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:html' as html;

Future<bool> onFlutterFirstFrameEvent() {
  final Completer<bool> completer = Completer<bool>();
  html.window.addEventListener('flutter-first-frame', (html.Event event) {
    completer.complete(true);
  });
  return completer.future;
}
