// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups
//
// Checks that the VM throws an appropriate exception when FFI objects are
// passed between isolates.

import 'dart:ffi';
import 'dart:isolate';

import 'expect.dart';

main(args) async {
  try {
    await Isolate.spawn(print, Pointer<Void>.fromAddress(1));
  } catch (e) {
    Expect.type<ArgumentError>(e);
    return;
  }

  throw "Test didn't throw an exception!";
}
