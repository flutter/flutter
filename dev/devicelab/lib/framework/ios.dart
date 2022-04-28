// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'host_agent.dart';
import 'task_result.dart';
import 'utils.dart';

typedef SimulatorFunction = Future<void> Function(String deviceId);

Future<String> fileType(String pathToBinary) {
  return eval('file', <String>[pathToBinary]);
}

Future<String?> minPhoneOSVersion(String pathToBinary) async {
  final String loadCommands = await eval('otool', <String>[
    '-l',
    '-arch',
    'arm64',
    pathToBinary,
  ]);
  if (!loadCommands.contains('LC_VERSION_MIN_IPHONEOS')) {
    return null;
  }

  String? minVersion;
  // Load command 7
  // cmd LC_VERSION_MIN_IPHONEOS
  // cmdsize 16
  // version 9.0
  // sdk 15.2
  //  ...
  final List<String> lines = LineSplitter.split(loadCommands).toList();
  lines.asMap().forEach((int index, String line) {
    if (line.contains('LC_VERSION_MIN_IPHONEOS') && lines.length - index - 1 > 3) {
      final String versionLine = lines
          .skip(index - 1)
          .take(4).last;
      final RegExp versionRegex = RegExp(r'\s*version\s*(\S*)');
      minVersion = versionRegex.firstMatch(versionLine)?.group(1);
    }
  });
  return minVersion;
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

Future<void> checkContainsBitcode(String pathToBinary) async {
  if (!await containsBitcode(pathToBinary)) {
    throw TaskResult.failure('Expected bitcode in $pathToBinary');
  }
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
Future<void> removeIOSimulator(String? deviceId) async {
  if (deviceId != null && deviceId != '') {
    await eval(
      'xcrun',
      <String>[
        'simctl',
        'shutdown',
        deviceId,
      ],
      canFail: true,
      workingDirectory: flutterDirectory.path,
    );
    await eval(
      'xcrun',
      <String>[
        'simctl',
        'delete',
        deviceId,
      ],
      canFail: true,
      workingDirectory: flutterDirectory.path,
    );
  }
}

Future<bool> runXcodeTests({
  required String platformDirectory,
  required String destination,
  required String testName,
  bool skipCodesign = false,
}) async {
  final Map<String, String> environment = Platform.environment;
  String? developmentTeam;
  String? codeSignStyle;
  String? provisioningProfile;
  if (!skipCodesign) {
    // If not running on CI, inject the Flutter team code signing properties.
    developmentTeam = environment['FLUTTER_XCODE_DEVELOPMENT_TEAM'] ?? 'S8QB4VV633';
    codeSignStyle = environment['FLUTTER_XCODE_CODE_SIGN_STYLE'];
    provisioningProfile = environment['FLUTTER_XCODE_PROVISIONING_PROFILE_SPECIFIER'];
  }
  final String resultBundleTemp = Directory.systemTemp.createTempSync('flutter_xcresult.').path;
  final String resultBundlePath = path.join(resultBundleTemp, 'result');
  final int testResultExit = await exec(
    'xcodebuild',
    <String>[
      '-workspace',
      'Runner.xcworkspace',
      '-scheme',
      'Runner',
      '-configuration',
      'Release',
      '-destination',
      destination,
      '-resultBundlePath',
      resultBundlePath,
      'test',
      'COMPILER_INDEX_STORE_ENABLE=NO',
      if (developmentTeam != null)
        'DEVELOPMENT_TEAM=$developmentTeam',
      if (codeSignStyle != null)
        'CODE_SIGN_STYLE=$codeSignStyle',
      if (provisioningProfile != null)
        'PROVISIONING_PROFILE_SPECIFIER=$provisioningProfile',
    ],
    workingDirectory: platformDirectory,
    canFail: true,
  );

  if (testResultExit != 0) {
    final Directory? dumpDirectory = hostAgent.dumpDirectory;
    final Directory xcresultBundle = Directory(path.join(resultBundleTemp, 'result.xcresult'));
    if (dumpDirectory != null) {
      if (xcresultBundle.existsSync()) {
        // Zip the test results to the artifacts directory for upload.
        final String zipPath = path.join(dumpDirectory.path,
            '$testName-${DateTime.now().toLocal().toIso8601String()}.zip');
        await exec(
          'zip',
          <String>[
            '-r',
            '-9',
            zipPath,
            path.basename(xcresultBundle.path),
          ],
          workingDirectory: resultBundleTemp,
          canFail: true, // Best effort to get the logs.
        );
      } else {
        print('xcresult bundle ${xcresultBundle.path} does not exist, skipping upload');
      }
    }
    return false;
  }
  return true;
}
