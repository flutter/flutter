// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('start process with missing executable', () async {
    final Future<Process> proc = Process.start('nonexistent-executable', []);
    expect(proc, throwsA(isA<ProcessException>()));
  });
}
