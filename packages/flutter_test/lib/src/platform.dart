// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// Whether the test is running on the Windows operating system.
///
/// This does not include test compiled to JavaScript running in a browser on
/// the Windows operating system.
bool get isWindows {
  return currentHostPlatform == HostPlatform.windows;
}

/// Whether the test is running on the macOS operating system.
///
/// This does not include test compiled to JavaScript running in a browser on
/// the macOS operating system.
bool get isMacOS {
  return currentHostPlatform == HostPlatform.macOS;
}

/// Whether the test is running on the Linux operating system.
///
/// This does not include test compiled to JavaScript running in a browser on
/// the Linux operating system.
bool get isLinux {
  return currentHostPlatform == HostPlatform.linux;
}

/// Whether the test is running in a web browser compiled to JavaScript.
bool get isBrowser {
  return currentHostPlatform == HostPlatform.browser;
}

