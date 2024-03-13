// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi' as ffi show Abi;

import 'package:path/path.dart' as p;
import 'environment.dart';

String _getAbiSubdirectory(ffi.Abi abi) {
  switch (abi) {
    case ffi.Abi.macosArm64:
      return 'macos-arm64';
    case ffi.Abi.macosX64:
      return 'macos-x64';
    case ffi.Abi.windowsArm64:
      return 'windows-arm64';
    case ffi.Abi.windowsX64:
      return 'windows-x64';
    case ffi.Abi.linuxArm:
      return 'linux-arm';
    case ffi.Abi.linuxArm64:
      return 'linux-arm64';
    case ffi.Abi.linuxIA32:
      return 'linux-x86';
    case ffi.Abi.linuxX64:
      return 'linux-x64';
    case ffi.Abi.androidArm:
    case ffi.Abi.androidArm64:
    case ffi.Abi.androidIA32:
    case ffi.Abi.androidX64:
    case ffi.Abi.androidRiscv64:
    case ffi.Abi.fuchsiaArm64:
    case ffi.Abi.fuchsiaX64:
    case ffi.Abi.fuchsiaRiscv64:
    case ffi.Abi.iosArm:
    case ffi.Abi.iosArm64:
    case ffi.Abi.iosX64:
    case ffi.Abi.linuxRiscv32:
    case ffi.Abi.linuxRiscv64:
    case ffi.Abi.windowsIA32:
    default:
      throw UnsupportedError('Unsupported Abi $abi');
  }
}

/// Returns a dart-sdk/bin directory path that is compatible with the host.
String findDartBinDirectory(Environment env) {
  return p.join(env.engine.flutterDir.path, 'prebuilts',
      _getAbiSubdirectory(env.abi), 'dart-sdk', 'bin');
}

/// Returns a dart-sdk/bin/dart file pthat that is executable on the host.
String findDartBinary(Environment env) {
  return p.join(findDartBinDirectory(env), 'dart');
}
