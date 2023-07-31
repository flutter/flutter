// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Returns a random base64 string containing [bytes] bytes of data.
///
/// [seed] is passed to [math.Random].
String randomBase64(int bytes, {int? seed}) {
  var random = math.Random(seed);
  var data = Uint8List(bytes);
  for (var i = 0; i < bytes; i++) {
    data[i] = random.nextInt(256);
  }
  return base64Encode(data);
}
