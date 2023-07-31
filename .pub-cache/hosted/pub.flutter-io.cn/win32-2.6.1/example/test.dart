// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Scratch file for testing various ideas.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void main() {
  final sh = calloc<SHITEMID>();
  sh.ref.cb = 0x0102;
  print(sh.ref.cb == 0x0102);
}
