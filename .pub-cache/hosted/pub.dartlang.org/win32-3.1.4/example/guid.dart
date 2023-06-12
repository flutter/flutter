// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Creates a globally unique identifier (GUID)

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void main() {
  final guid = calloc<GUID>();

  final hr = CoCreateGuid(guid);
  if (SUCCEEDED(hr)) {
    print(guid.ref);
  }

  free(guid);
}
