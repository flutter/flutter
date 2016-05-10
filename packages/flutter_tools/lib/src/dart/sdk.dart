// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import '../artifacts.dart';

/// Locate the Dart SDK.
String get dartSdkPath {
  return path.join(ArtifactStore.flutterRoot, 'bin', 'cache', 'dart-sdk');
}

/// Return the platform specific name for the given Dart SDK binary. So, `pub`
/// ==> `pub.bat`.  The default SDK location can be overridden with a specified
/// [sdkLocation].
String sdkBinaryName(String name, { String sdkLocation }) {
  return path.absolute(path.join(sdkLocation ?? dartSdkPath, 'bin', Platform.isWindows ? '$name.bat' : name));
}
