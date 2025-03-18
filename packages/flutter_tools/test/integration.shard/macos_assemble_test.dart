// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';

const String _kMacosAssemblePath = 'bin/macos_assemble.sh';
const String _kMacosAssembleErrorHeader =
    '========================================================================';

void main() {
  test('macOS assemble fails with no arguments', () async {
    final ProcessResult result = await Process.run(
      _kMacosAssemblePath,
      <String>[],
      environment: <String, String>{
        'SOURCE_ROOT': '../../examples/hello_world',
        'FLUTTER_ROOT': '../..',
      },
    );
    expect(result.stderr, startsWith(_kMacosAssembleErrorHeader));
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
