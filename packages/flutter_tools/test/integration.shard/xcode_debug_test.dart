// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import '../src/common.dart';

void main() {
  test('Xcode automation distinguishes destinations sharing the host identifier', () async {
    final String script = File('bin/xcode_debug.js').readAsStringSync();
    final ProcessResult result = await Process.run('osascript', <String>[
      '-l',
      'JavaScript',
      '-e',
      script +
          r'''
function run() {
  function destination(platform, architecture) {
    return {
      device: () => ({ deviceIdentifier: () => 'host-id' }),
      platform: () => platform,
      architecture: () => architecture,
    };
  }
  const nativeMac = destination('macosx', 'arm64');
  const wrongArchitecture = destination('iphoneos', 'x86_64');
  const iPadOnMac = destination('iphoneos', 'arm64');
  const workspace = { runDestinations: () => [nativeMac, wrongArchitecture, iPadOnMac] };
  return JSON.stringify({
    existingCaller: getTargetDestination(workspace, 'host-id').result === nativeMac,
    iPadOnMac: getTargetDestination(workspace, 'host-id', false, 'iphoneos', 'arm64').result === iPadOnMac,
    missing: getTargetDestination(workspace, 'missing', false, 'iphoneos', 'arm64').result === null,
    wrongPlatform: getTargetDestination(workspace, 'host-id', false, 'appletvos', 'arm64').result === null,
  });
}
''',
    ]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(jsonDecode(result.stdout.toString()), <String, bool>{
      'existingCaller': true,
      'iPadOnMac': true,
      'missing': true,
      'wrongPlatform': true,
    });
  }, skip: !Platform.isMacOS); // [intended] requires macOS JavaScript for Automation.
}
