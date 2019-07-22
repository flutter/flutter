// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';

// The setting that controls the executable name in the linux makefile.
const String _kBinaryNameVariable = 'BINARY_NAME=';

/// Extracts the `BINARY_NAME` from a linux project Makefile.
///
/// Returns `null` if it cannot be found.
String makefileExecutableName(File makeFile) {
  for (String line in makeFile.readAsLinesSync()) {
    if (line.startsWith(_kBinaryNameVariable)) {
      return line.split(_kBinaryNameVariable).last.trim();
    }
  }
  return null;
}
