// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as system;

// this is a test to make sure our tests consider engine crashes to be failures
// see //flutter/dev/bots/test.dart

void main() {
  system.Process.killPid(system.pid, system.ProcessSignal.sigsegv);
}
