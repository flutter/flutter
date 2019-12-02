// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

// Whether the current dart code is running in an environment that was compiled
// to JavaScript.
const bool _kIsCompiledToJavaScript = identical(0, 0.0);

/// Whether the test is running on the Windows operating system.
///
/// This does not include test compiled to JavaScript running in a browser on
/// the Windows operating system.
bool get isWindows {
  if (_kIsCompiledToJavaScript) {
    return false;
  }
  return Platform.isWindows;
}

/// Whether the test is running on the macOS operating system.
///
/// This does not include test compiled to JavaScript running in a browser on
/// the macOS operating system.
bool get isMacOS {
  if (_kIsCompiledToJavaScript) {
    return false;
  }
  return Platform.isMacOS;
}

/// Whether the test is running on the Linux operating system.
///
/// This does not include test compiled to JavaScript running in a browser on
/// the Linux operating system.
bool get isLinux {
  if (_kIsCompiledToJavaScript) {
    return false;
  }
  return Platform.isLinux;
}

/// Whether the test is running in a web browser compiled to JavaScript.
bool get isBrowser {
  return _kIsCompiledToJavaScript;
}
