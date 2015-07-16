// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library path.utils;

import 'characters.dart' as chars;

/// Returns whether [char] is the code for an ASCII letter (uppercase or
/// lowercase).
bool isAlphabetic(int char) =>
    (char >= chars.UPPER_A && char <= chars.UPPER_Z) ||
        (char >= chars.LOWER_A && char <= chars.LOWER_Z);

/// Returns whether [char] is the code for an ASCII digit.
bool isNumeric(int char) => char >= chars.ZERO && char <= chars.NINE;
