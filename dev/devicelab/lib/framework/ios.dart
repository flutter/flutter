// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'utils.dart';

typedef SimulatorFunction = Future<void> Function(String deviceId);

Future<String> fileType(String pathToBinary) {
  return eval('file', <String>[pathToBinary]);
}

Future<bool> containsBitcode(String pathToBinary) async {
  // See: https://stackoverflow.com/questions/32755775/how-to-check-a-static-library-is-built-contain-bitcode
  final String loadCommands = await eval('otool', <String>[
    '-l',
    '-arch',
    'arm64',
    pathToBinary,
  ]);
  if (!loadCommands.contains('__LLVM')) {
    return false;
  }
  // Presence of the section may mean a bitcode marker was embedded (size=1), but there is no content.
  if (!loadCommands.contains('size 0x0000000000000001')) {
    return true;
  }
  // Check the false positives: size=1 wasn't referencing the __LLVM section.

  bool emptyBitcodeMarkerFound = false;
  //  Section
  //  sectname __bundle
  //  segname __LLVM
  //  addr 0x003c4000
  //  size 0x0042b633
  //  offset 3932160
  //  ...
  final List<String> lines = LineSplitter.split(loadCommands).toList();
  lines.asMap().forEach((int index, String line) {
    if (line.contains('segname __LLVM') && lines.length - index - 1 > 3) {
      emptyBitcodeMarkerFound |= lines
        .skip(index - 1)
        .take(4)
        .any((String line) => line.contains(' size 0x0000000000000001'));
    }
  });
  return !emptyBitcodeMarkerFound;
}

/// Creates and boots a new simulator, passes the new simulator's identifier to
/// `testFunction`.
///
/// Remember to call removeIOSimulator in the test teardown.
Future<void> testWithNewIOSSimulator(
  String deviceName,
  SimulatorFunction testFunction, {
  String deviceTypeId = 'com.apple.CoreSimulator.SimDeviceType.iPhone-11',
}) async {
  // Xcode 11.4 simctl create makes the runtime argument optional, and defaults to latest.
  // TODO(jmagman): Remove runtime parsing when devicelab upgrades to Xcode 11.4 https://github.com/flutter/flutter/issues/54889
  final String availableRuntimes = await eval(
    'xcrun',
    <String>[
      'simctl',
      'list',
      'runtimes',
    ],
    workingDirectory: flutterDirectory.path,
  );

  String? iOSSimRuntime;

  final RegExp iOSRuntimePattern = RegExp(r'iOS .*\) - (.*)');

  for (final String runtime in LineSplitter.split(availableRuntimes)) {
    // These seem to be in order, so allow matching multiple lines so it grabs
    // the last (hopefully latest) one.
    final RegExpMatch? iOSRuntimeMatch = iOSRuntimePattern.firstMatch(runtime);
    if (iOSRuntimeMatch != null) {
      iOSSimRuntime = iOSRuntimeMatch.group(1)!.trim();
      continue;
    }
  }
  if (iOSSimRuntime == null) {
    throw 'No iOS simulator runtime found. Available runtimes:\n$availableRuntimes';
  }

  final String deviceId = await eval(
    'xcrun',
    <String>[
      'simctl',
      'create',
      deviceName,
      deviceTypeId,
      iOSSimRuntime,
    ],
    workingDirectory: flutterDirectory.path,
  );
  await eval(
    'xcrun',
    <String>[
      'simctl',
      'boot',
      deviceId,
    ],
    workingDirectory: flutterDirectory.path,
  );

  await testFunction(deviceId);
}

/// Shuts down and deletes simulator with deviceId.
Future<void> removeIOSimulator(String deviceId) async {
  if (deviceId != null && deviceId != '') {
    await eval(
      'xcrun',
      <String>[
        'simctl',
        'shutdown',
        deviceId
      ],
      canFail: true,
      workingDirectory: flutterDirectory.path,
    );
    await eval(
      'xcrun',
      <String>[
        'simctl',
        'delete',
        deviceId],
      canFail: true,
      workingDirectory: flutterDirectory.path,
    );
  }
}
