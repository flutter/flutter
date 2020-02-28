// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:web_integration/a.dart'
  if (dart.library.io) 'package:web_integration/b.dart' as message1;
import 'package:web_integration/c.dart'
  if (dart.library.html) 'package:web_integration/d.dart' as message2;

void main() {
  String message;
  if (message1.message == 'a' && message2.message == 'd')  {
    message = '--- TEST SUCCEEDED ---';
  } else {
    message = '--- TEST FAILED ---';
  }
  print(message);
  html.HttpRequest.request(
    '/test-result',
    method: 'POST',
    sendData: message,
  );
}
