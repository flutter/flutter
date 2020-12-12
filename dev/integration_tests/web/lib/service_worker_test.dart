// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
Future<void> main() async {
  final html.ServiceWorkerRegistration worker = await html.window.navigator.serviceWorker.ready;
  if (worker.active != null) {
    await Future.delayed(const Duration(seconds: 5));
    await html.HttpRequest.getString('CLOSE');
    return;
  }
  worker.addEventListener('statechange', (event) async {
    if (worker.active != null) {
      await Future.delayed(const Duration(seconds: 5));
      await html.HttpRequest.getString('CLOSE');
    }
  });
}
