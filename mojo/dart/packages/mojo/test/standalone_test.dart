// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Test that an import of 'package:mojo' doesn't fail on the VM.
import 'package:mojo/core.dart';

shouldThrowUnsupported(description, f) {
  try {
    f();
    throw "$description did not throw as expected.";
  } catch (e) {
    if (e is! UnsupportedError) {
      throw "$description error is not an UnsupportedError $e.";
    }
  }
}

main() {
  var invalid = new MojoHandle.invalid();
  shouldThrowUnsupported("getTimeTicksNow()", () => getTimeTicksNow());
  shouldThrowUnsupported(
      "MojoMessagePipe allocation", () => new MojoMessagePipe());
  shouldThrowUnsupported("MojoDataPipe allocation", () => new MojoDataPipe());
  shouldThrowUnsupported(
      "MojoSharedBuffer allocation", () => new MojoSharedBuffer.create(1024));
}
