// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

/// Utility class for generating Firebase child node keys.
///
/// Since the Flutter plugin API is asynchronous, there's no way for us
/// to use the native SDK to generate the node key synchronously and we
/// have to do it ourselves if we want to be able to reference the
/// newly-created node synchronously.
///
/// This code is based largely on the Android implementation and ported to Dart.

class AutoIdGenerator {
  static const int _AUTO_ID_LENGTH = 20;

  static const String _AUTO_ID_ALPHABET =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  static final Random _random = Random();

  /// Automatically Generates a random new Id
  static String autoId() {
    final StringBuffer stringBuffer = StringBuffer();
    const int maxRandom = _AUTO_ID_ALPHABET.length;

    for (int i = 0; i < _AUTO_ID_LENGTH; ++i) {
      stringBuffer.write(_AUTO_ID_ALPHABET[_random.nextInt(maxRandom)]);
    }

    return stringBuffer.toString();
  }
}
