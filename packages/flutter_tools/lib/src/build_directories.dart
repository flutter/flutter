// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'base/config.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/os.dart';
import 'build_info.dart';
import 'globals.dart' as globals;

/// Returns the top-level build output directory.
String getBuildDirectory([Config config, FileSystem fileSystem]) {
  // TODO(johnmccutchan): Stop calling this function as part of setting
  // up command line argument processing.
  if (context == null) {
    return 'build';
  }
  final Config localConfig = config ?? globals.config;
  final FileSystem localFilesystem = fileSystem ?? globals.fs;
  if (localConfig == null) {
    return 'build';
  }

  final String buildDir = localConfig.getValue('build-dir') as String ?? 'build';
  if (localFilesystem.path.isAbsolute(buildDir)) {
    throw Exception(
        'build-dir config setting in ${globals.config.configPath} must be relative');
  }
  return buildDir;
}

/// Returns the Android build output directory.
String getAndroidBuildDirectory() {
  // TODO(cbracken): move to android subdir.
  return getBuildDirectory();
}

/// Returns the AOT build output directory.
String getAotBuildDirectory() {
  return globals.fs.path.join(getBuildDirectory(), 'aot');
}

/// Returns the asset build output directory.
String getAssetBuildDirectory() {
  return globals.fs.path.join(getBuildDirectory(), 'flutter_assets');
}

/// Returns the iOS build output directory.
String getIosBuildDirectory() {
  return globals.fs.path.join(getBuildDirectory(), 'ios');
}

/// Returns the macOS build output directory.
String getMacOSBuildDirectory() {
  return globals.fs.path.join(getBuildDirectory(), 'macos');
}

/// Returns the web build output directory.
String getWebBuildDirectory() {
  return globals.fs.path.join(getBuildDirectory(), 'web');
}

/// Returns the Linux build output directory.
String getLinuxBuildDirectory([TargetPlatform targetPlatform]) {
  final String arch = (targetPlatform == null) ?
      _getCurrentHostPlatformArchName() :
      getNameForTargetPlatformArch(targetPlatform);
  final String subDirs = 'linux/' + arch;
  return globals.fs.path.join(getBuildDirectory(), subDirs);
}

/// Returns the Windows build output directory.
String getWindowsBuildDirectory() {
  return globals.fs.path.join(getBuildDirectory(), 'windows');
}

/// Returns the Fuchsia build output directory.
String getFuchsiaBuildDirectory() {
  return globals.fs.path.join(getBuildDirectory(), 'fuchsia');
}

String _getCurrentHostPlatformArchName() {
  final HostPlatform hostPlatform = _getCurrentHostPlatform();
  return getNameForHostPlatformArch(hostPlatform);
}

HostPlatform _getCurrentHostPlatform() {
  if (globals.platform.isMacOS) {
    return HostPlatform.darwin_x64;
  }
  if (globals.platform.isLinux) {
    // support x64 and arm64 architecture.
    return globals.os.hostPlatform;
  }
  if (globals.platform.isWindows) {
    return HostPlatform.windows_x64;
  }

  globals.printError('Unsupported host platform, defaulting to Linux');

  return HostPlatform.linux_x64;
}
