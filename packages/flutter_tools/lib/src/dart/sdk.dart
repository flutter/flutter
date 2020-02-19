// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../cache.dart';
import '../globals.dart' as globals;

/// Locate the Dart SDK.
String get dartSdkPath {
  return globals.fs.path.join(Cache.flutterRoot, 'bin', 'cache', 'dart-sdk');
}

/// The required Dart language flags
const List<String> dartVmFlags = <String>[];

/// Return the platform specific name for the given Dart SDK binary. So, `pub`
/// ==> `pub.bat`. The default SDK location can be overridden with a specified
/// [sdkLocation].
String sdkBinaryName(String name, { String sdkLocation }) {
  return globals.fs.path.absolute(
    globals.fs.path.join(sdkLocation ?? dartSdkPath, 'bin', globals.platform.isWindows ? '$name.bat' : name));
}
