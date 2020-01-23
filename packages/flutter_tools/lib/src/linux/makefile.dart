// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../project.dart';

// The setting that controls the executable name in the linux makefile.
const String _kBinaryNameVariable = 'BINARY_NAME=';

/// Extracts the `BINARY_NAME` from a linux project Makefile.
///
/// Returns `null` if it cannot be found.
String makefileExecutableName(LinuxProject project) {
  for (final String line in project.makeFile.readAsLinesSync()) {
    if (line.startsWith(_kBinaryNameVariable)) {
      return line.split(_kBinaryNameVariable).last.trim();
    }
  }
  return null;
}
