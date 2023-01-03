// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Running in unsound null-safety mode is intended to test for potential miscasts
// or invalid assertions.

import 'package:flutter/src/foundation/_isolates_io.dart';

int throwNull(dynamic arg) {
  throw arg as Object;
}

void main() async {
  try {
    await compute(throwNull, null);
  } catch (e) {
    if (e is! TypeError && e is! NullThrownError) { // ignore: deprecated_member_use
      throw Exception('compute returned bad result');
    }
  }
}
