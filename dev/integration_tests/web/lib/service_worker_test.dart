// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
Future<void> main() async {
  await html.window.navigator.serviceWorker?.ready;
  const String response = 'CLOSE?version=1';
  await html.HttpRequest.getString(response);
  html.document.body?.appendHtml(response);
}
