// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show Random;

/// Returns a unique ID in the format:
///
///     f47ac10b-58cc-4372-a567-0e02b2c3d479
///
/// The generated uuids are 128 bit numbers encoded in a specific string format.
/// For more information, see
/// [en.wikipedia.org/wiki/Universally_unique_identifier](http://en.wikipedia.org/wiki/Universally_unique_identifier).
String generateUuidV4() {
  final random = Random();

  int _generateBits(int bitCount) => random.nextInt(1 << bitCount);

  String _printDigits(int value, int count) =>
      value.toRadixString(16).padLeft(count, '0');
  String _bitsDigits(int bitCount, int digitCount) =>
      _printDigits(_generateBits(bitCount), digitCount);

  // Generate xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx / 8-4-4-4-12.
  var special = 8 + random.nextInt(4);

  return '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}-'
      '${_bitsDigits(16, 4)}-'
      '4${_bitsDigits(12, 3)}-'
      '${_printDigits(special, 1)}${_bitsDigits(12, 3)}-'
      '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}';
}
