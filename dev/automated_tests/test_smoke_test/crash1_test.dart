// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as system;

import 'package:flutter_test/flutter_test.dart';

// this is a test to make sure our tests consider engine crashes to be failures
// see //flutter/dev/bots/test.sh

void main() {
  test('test smoke test -- this test should fail', () async {
    system.Process.killPid(system.pid, system.ProcessSignal.SIGSEGV);
  });
}