// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:_testing/expect.dart';
import 'package:mojo/core.dart';

MojoHandle leakMojoHandle() {
  var pipe = new MojoMessagePipe();
  Expect.isNotNull(pipe);

  var endpoint = pipe.endpoints[0];
  Expect.isTrue(endpoint.handle.isValid);

  var eventStream = new MojoEventStream(endpoint.handle);
  // After making a MojoEventStream, the underlying mojo handle will have
  // the native MojoClose called on it when the MojoEventStream is GC'd or the
  // VM shuts down.

  return endpoint.handle;
}

// vmoptions: --new-gen-semi-max-size=1 --old_gen_growth_rate=1
List<int> triggerGC() {
  var l = new List.filled(1000000, 7);
  return l;
}

test() {
  MojoHandle handle = leakMojoHandle();
  triggerGC();

  // The handle will be closed by the MojoHandle finalizer during GC, so the
  // attempt to close it again will fail.
  MojoResult result = handle.close();
  Expect.isTrue(result.isInvalidArgument);
}

main() {
  test();
}
