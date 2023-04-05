// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/os.dart';
import '../base/platform.dart';
import 'android_studio.dart';

const String _javaHomeEnvironmentVariable = 'JAVA_HOME';
const String _javaExecutable = 'java';

/// Attempts to find the home directory of the local Java installation used
/// by the flutter tool.
///
/// First tries Java bundled with Android Studio, then sniffs JAVA_HOME, then falls back to PATH.
String? findJavaHome({
  required AndroidStudio? androidStudio,
  required FileSystem fileSystem,
  required OperatingSystemUtils operatingSystemUtils,
  required Platform platform,
}) {
  if (androidStudio?.javaHomePath != null) {
    return androidStudio!.javaHomePath;
  }

  final String? javaHomeEnv = platform.environment[_javaHomeEnvironmentVariable];

  if (javaHomeEnv != null) {
    // Trust JAVA_HOME.
    return javaHomeEnv;
  }

  // Fallback to PATH based lookup.
  final String? binaryPath = operatingSystemUtils.which(_javaExecutable)?.path;
  return binaryPath == null ? null : fileSystem.file(binaryPath).parent.parent.path;
}

/// Attempts to find the java binary of the local Java installation used by
/// the flutter tool.
///
/// See [findJavaHome].
String? findJavaBinary({
  required AndroidStudio? androidStudio,
  required FileSystem fileSystem,
  required OperatingSystemUtils operatingSystemUtils,
  required Platform platform,
}) {
  final String? javaHome = findJavaHome(
    androidStudio: androidStudio,
    fileSystem: fileSystem,
    operatingSystemUtils: operatingSystemUtils,
    platform: platform
  );

  return javaHome == null ? null : fileSystem.path.join(javaHome, 'bin', 'java');
}
