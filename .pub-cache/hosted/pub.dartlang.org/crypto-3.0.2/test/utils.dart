// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

/// Asserts that an HMAC using [hash] returns [mac] for [input] and [key].
void expectHmacEquals(Hash hash, List<int> input, List<int> key, String mac) {
  var hmac = Hmac(hash, key);
  expect(hmac.convert(input).toString(), startsWith(mac));
}

final toupleMatch = RegExp('([0-9a-fA-F]{2})');

Uint8List bytesFromHexString(String message) {
  var bytes = <int>[];
  for (var match in toupleMatch.allMatches(message)) {
    bytes.add(int.parse(match.group(0)!, radix: 16));
  }
  return Uint8List.fromList(bytes);
}
