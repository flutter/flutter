// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> main() async {
  await web.window.navigator.serviceWorker.ready.toDart;
  final JSString response = 'CLOSE?version=1'.toJS;
  await web.window.fetch(response).toDart;
  web.document.body?.append(response);
}
