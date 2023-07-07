// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'string_scanner.dart';

/// Validates the arguments passed to [StringScanner.error].
void validateErrorArgs(
    String string, Match? match, int? position, int? length) {
  if (match != null && (position != null || length != null)) {
    throw ArgumentError("Can't pass both match and position/length.");
  }

  if (position != null) {
    if (position < 0) {
      throw RangeError('position must be greater than or equal to 0.');
    } else if (position > string.length) {
      throw RangeError('position must be less than or equal to the '
          'string length.');
    }
  }

  if (length != null && length < 0) {
    throw RangeError('length must be greater than or equal to 0.');
  }

  if (position != null && length != null && position + length > string.length) {
    throw RangeError('position plus length must not go beyond the end of '
        'the string.');
  }
}
