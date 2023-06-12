// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:test_api/src/backend/operating_system.dart'; // ignore: implementation_imports

/// Directories that are specific to OS X.
///
/// This is used to try to distinguish OS X and Linux in [currentOSGuess].
final _macOSDirectories = {
  '/Applications',
  '/Library',
  '/Network',
  '/System',
  '/Users',
};

/// Returns the best guess for the current operating system without using
/// `dart:io`.
///
/// This is useful for running test files directly and skipping tests as
/// appropriate. The only OS-specific information we have is the current path,
/// which we try to use to figure out the OS.
final OperatingSystem currentOSGuess = (() {
  if (p.style == p.Style.url) return OperatingSystem.none;
  if (p.style == p.Style.windows) return OperatingSystem.windows;
  if (_macOSDirectories.any(p.current.startsWith)) return OperatingSystem.macOS;
  return OperatingSystem.linux;
})();
