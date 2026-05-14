// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';

const _kMacosAssemblePath = 'bin/macos_assemble.sh';

void main() {
  test('macOS assemble defaults to build with no arguments', () async {
    final ProcessResult result = await Process.run(
      _kMacosAssemblePath,
      <String>[],
      environment: <String, String>{
        'SOURCE_ROOT': '../../examples/hello_world',
        'FLUTTER_ROOT': '../..',
      },
    );
    expect(
      result.stderr,
      isNot(contains('error: Your Xcode project is incompatible with this version of Flutter.')),
    );
    expect(result.stderr, isNot(contains('warning: Unrecognized platform')));
    expect(result.exitCode, isNot(0));
  }, skip: !io.Platform.isMacOS); // [intended] requires macos toolchain.

  test('macOS assemble warns when unable to determine platform', () async {
    final ProcessResult result = await Process.run(
      _kMacosAssemblePath,
      <String>['build', 'asdf'],
      environment: <String, String>{
        'SOURCE_ROOT': '../../examples/hello_world',
        'FLUTTER_ROOT': '../..',
      },
    );
    expect(result.stderr, contains('warning: Unrecognized platform: asdf. Defaulting to iOS.'));
    expect(result.exitCode, isNot(0));
  }, skip: !io.Platform.isMacOS); // [intended] requires macos toolchain.

  test('macOS assemble fails on unexpected build mode', () async {
    final ProcessResult result = await Process.run(
      _kMacosAssemblePath,
      <String>[],
      environment: <String, String>{'CONFIGURATION': 'Custom'},
    );
    expect(result.stderr, contains('ERROR: Unknown FLUTTER_BUILD_MODE: custom.'));
    expect(
      result.stderr,
      contains("Valid values are 'Debug', 'Profile', or 'Release' (case insensitive)"),
    );
    expect(result.exitCode, isNot(0));
  }, skip: !io.Platform.isMacOS); // [intended] requires macos toolchain.
}
