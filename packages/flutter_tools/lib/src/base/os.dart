// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

final OperatingSystemUtils os = new OperatingSystemUtils._();

abstract class OperatingSystemUtils {
  factory OperatingSystemUtils._() {
    if (Platform.isWindows) {
      return new _WindowsUtils();
    } else {
      return new _PosixUtils();
    }
  }

  /// Make the given file executable. This may be a no-op on some platforms.
  ProcessResult makeExecutable(File file);
}

class _PosixUtils implements OperatingSystemUtils {
  ProcessResult makeExecutable(File file) {
    return Process.runSync('chmod', ['u+x', file.path]);
  }
}

class _WindowsUtils implements OperatingSystemUtils {
  // This is a no-op.
  ProcessResult makeExecutable(File file) {
    return new ProcessResult(0, 0, null, null);
  }
}
