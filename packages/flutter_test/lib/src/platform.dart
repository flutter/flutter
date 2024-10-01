// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/foundation.dart';
library;

import 'dart:io';

/// Whether the test is running in a web browser compiled to JavaScript or WebAssembly.
///
/// See also:
///
///  * [kIsWeb], the equivalent constant in the `foundation` library.
const bool isBrowser = bool.fromEnvironment('dart.library.js_interop');

/// Whether the test is running on the Windows operating system.
///
/// This does not include tests compiled to JavaScript running in a browser on
/// the Windows operating system.
///
/// See also:
///
///  * [isBrowser], which reports true for tests running in browsers.
bool get isWindows {
  if (isBrowser) {
    return false;
  }
  return Platform.isWindows;
}

/// Whether the test is running on the macOS operating system.
///
/// This does not include tests compiled to JavaScript running in a browser on
/// the macOS operating system.
///
/// See also:
///
///  * [isBrowser], which reports true for tests running in browsers.
bool get isMacOS {
  if (isBrowser) {
    return false;
  }
  return Platform.isMacOS;
}

/// Whether the test is running on the Linux operating system.
///
/// This does not include tests compiled to JavaScript running in a browser on
/// the Linux operating system.
///
/// See also:
///
///  * [isBrowser], which reports true for tests running in browsers.
bool get isLinux {
  if (isBrowser) {
    return false;
  }
  return Platform.isLinux;
}
