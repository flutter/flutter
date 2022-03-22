// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart=2.9

import 'package:flutter/src/foundation/_isolates_io.dart';

int throwNull(int arg) {
  throw null;
}

void main() async {
  try {
    await compute(throwNull, null);
  } catch (e) {
    if (e is! NullThrownError) {
      throw Exception('compute returned bad result');
    }
  }
}
