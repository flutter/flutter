// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'host_agent.dart';
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
  String configuration = 'Release',
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
    '/usr/bin/arch',
    <String>[
      '-arm64e',
      'xcrun',
      'xcodebuild',
      '-workspace',
      'Runner.xcworkspace',
      '-scheme',
      'Runner',
      '-configuration',
      configuration,
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
            '-q',
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

Future<bool> runMacOSXcodeTests({
  required String platformDirectory,
  required String destination,
  required String testName,
  String configuration = 'Release',
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
  final File output = File(path.join(resultBundleTemp, 'output.txt'));
  final File exitCodeOutput = File(path.join(resultBundleTemp, 'exit_code_output.txt'));

  final List<String> arguments = <String>[
    'xcodebuild',
    '-workspace',
    'Runner.xcworkspace',
    '-scheme',
    'Runner',
    '-configuration',
    configuration,
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
    '>',
    output.path,
    '2>&1'
  ];

  final String command = arguments.join(' ');
  final File runFile = File(path.join(resultBundleTemp, 'run_test.sh'));
  runFile.createSync();
  // Script to run the xcodebuild test, save the exit code to a file, and then kill its parent Terminal process.
  runFile.writeAsStringSync(
    'cd "$platformDirectory"\n'
    '$command\n'
    'echo \$? > ${exitCodeOutput.path}\n'
    r'''
pid=$$
command=$(ps -p $pid -c -o command=)
for i in {1..5}
do
  if [[ "$command" == "Terminal" ]]
  then
    kill $pid
  fi
  pid=$(ps -o ppid= $pid)
  command=$(ps -p $pid -c -o command=)
done
'''
  );

  print('Creating run_test.sh: \n ${runFile.readAsStringSync()}');

  final int updatePermissions = await exec(
    'chmod',
    <String>[
      '+x',
      runFile.path,
    ],
    canFail: true,
  );

  if (updatePermissions != 0) {
    print('Failed to update permissions of ${runFile.path}');
    return false;
  }

  final int testExecutation = await exec(
    'open',
    <String>[
      '-a',
      'Terminal.app',
      '-W',
      '-n',
      runFile.path,
    ],
    canFail: true,
  );

  if (testExecutation != 0) {
    print('Failed to open ${runFile.path} in the Terminal');
    return false;
  }

  print(output.readAsStringSync());

  final String exitCodeString = exitCodeOutput.readAsStringSync().trim();
  print('xcodebuild test exited with code $exitCodeString');
  final int testResultExit = int.parse(exitCodeString);

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
            '-q',
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

Future<bool> runXcodeTestsInScript({
  required String platformDirectory,
  required String destination,
  required String testName,
  String configuration = 'Release',
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

  final String flutterRoot = path.dirname(path.dirname(path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))))));
  print('Flutter root at $flutterRoot');

  final File output = File(path.join(resultBundleTemp, 'output.txt'));
  final File exitCodeOutput = File(path.join(resultBundleTemp, 'exit_code_output.txt'));

  const String executable = 'xcodebuild';
  final List<String> arguments = <String>[
    '-workspace',
    'Runner.xcworkspace',
    '-scheme',
    'Runner',
    '-configuration',
    configuration,
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
    '>',
    output.path,
    '2>&1'
  ];

  final String command = '$executable ${arguments.join(" ")}';

  final String exitCodeCommand = 'echo \$? > ${exitCodeOutput.path}';
  final int testExecutation = await exec(
    'osascript',
    <String>[
      '-l',
      'JavaScript',
      '$flutterRoot/packages/flutter_tools/bin/run_in_terminal.js',
      platformDirectory,
      command,
      exitCodeCommand
    ],
    canFail: true,
  );

  print(output.readAsStringSync());

  final String exitCodeString = exitCodeOutput.readAsStringSync().trim();
  print('xcodebuild test exited with code $exitCodeString');
  final int testResultExit = int.parse(exitCodeString);

  if (testExecutation != 0 || testResultExit != 0) {
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
            '-q',
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
