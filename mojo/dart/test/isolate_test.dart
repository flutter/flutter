// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

void foo(SendPort sp) {
  var rp = new ReceivePort();
  sp.send(rp.sendPort);
  rp.listen((msg) {
    if ((msg is String) && (msg == "Hello, world!")) {
      print("Hello, world!");
      rp.close();
    }
  });
}

main() {
  var rp = new ReceivePort();
  Isolate.spawn(foo, rp.sendPort).then((isolate) {
    var sp = null;
    rp.listen((msg) {
      if (msg is SendPort) {
        sp = msg;
        sp.send("Hello, world!");
        rp.close();
      }
    });
  });
}
