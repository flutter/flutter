// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../project.dart';

// The setting that controls the executable name in the linux makefile.
const String _kBinaryName = 'BINARY_NAME=';

/// Extracts the `BINARY_NAME` from a linux project Makefile.
///
/// Returns `null` if it cannot be found.
String makefileExecutableName(LinuxProject project) {
  for (String line in project.makeFile.readAsLinesSync()) {
    if (line.startsWith(_kBinaryName)) {
      return line.split(_kBinaryName).last.trim();
    }
  }
  return null;
}