// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:mojo/core.dart' as core;

main() {
  var pipe = new core.MojoMessagePipe();
  assert(pipe != null);

  var endpoint = pipe.endpoints[0];
  assert(endpoint.handle.isValid);

  var eventStream = new core.MojoEventStream(endpoint.handle);
  var completer = new Completer();
  int numEvents = 0;

  eventStream.listen((_) {
    numEvents++;
    eventStream.close();
  }, onDone: () {
    completer.complete(numEvents);
  });
  eventStream.enableWriteEvents();

  completer.future.then((int numEvents) {
    assert(numEvents == 1);
  });
}
