// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// The EOL character to be used for source code in tests.
final platformEol = Platform.isWindows ? '\r\n' : '\n';

/// Normalizes content to use platform-specific newlines to ensure that
/// when running on Windows \r\n is used even though source files are checked
/// out using \n.
String normalizeNewlinesForPlatform(String input) {
  // Skip normalising for other platforms, as the gitattributes for the SDK
  // will ensure all files are \n.
  if (!Platform.isWindows) {
    return input;
  }

  final newlinePattern = RegExp(r'\r?\n'); // either \r\n or \n
  return input.replaceAll(newlinePattern, platformEol);
}
