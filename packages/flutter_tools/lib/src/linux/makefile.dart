// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../project.dart';

// The setting that controls the executable name in the linux makefile.
const String _kBinaryNameVariable = 'BINARY_NAME=';

/// Extracts the `BINARY_NAME` from a linux project Makefile.
///
/// Returns `null` if it cannot be found.
String makefileExecutableName(LinuxProject project) {
  // Support the binary name being set either in the Makefile, or in the
  // separate configution include file used by the template.
  final List<File> makeFiles = <File>[
    project.makeFile.parent.childFile('app_configuration.mk'),
    project.makeFile,
  ];
  for (final File file in makeFiles) {
    if (!file.existsSync()) {
      continue;
    }
    for (final String line in file.readAsLinesSync()) {
      if (line.startsWith(_kBinaryNameVariable)) {
        return line.split(_kBinaryNameVariable).last.trim();
      }
    }
  }
  return null;
}
