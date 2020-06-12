// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:package_config/package_config.dart';

final RegExp _languageVersion = RegExp('/\/\\s*@dart');

/// Attempts to read the language version of a dart [file].
///
/// If this is not present, falls back to the language version defined in
/// [package]. If [package] is not provided and there is no
/// language version header, returns `null`.
String determineLanguageVersion(File file, Package package) {
  for (final String line in file.readAsLinesSync()) {
    final Match match = _languageVersion.matchAsPrefix(line);
    if (match != null) {
      return line;
    }
    if (line.startsWith('import')) {
      break;
    }
  }
  if (package != null) {
    return '// @dart = ${package.languageVersion}';
  }
  return null;
}
