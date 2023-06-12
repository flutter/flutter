// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

class OSUtilities {
  static String LINE_SEPARATOR = isWindows() ? '\r\n' : '\n';
  static bool isMac() => Platform.operatingSystem == 'macos';
  static bool isWindows() => Platform.operatingSystem == 'windows';
}
