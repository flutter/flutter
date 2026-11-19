// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'host_agent.dart';
import 'utils.dart';

typedef SimulatorFunction = Future<void> Function(String deviceId);

Future<String> fileType(String pathToBinary) {
  return eval('file', <String>[pathToBinary]);
}

Future<String?> minPhoneOSVersion(String pathToBinary) async {
  final String loadCommands = await eval('otool', <String>['-l', '-arch', 'arm64', pathToBinary]);
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
      final String versionLine = lines.skip(index - 1).take(4).last;
      final versionRegex = RegExp(r'\s*version\s*(\S*)');
      minVersion = versionRegex.firstMatch(versionLine)?.group(1);
    }
  });
  return minVersion;
}

/// An installed, available iOS simulator runtime from `simctl list runtimes`.
@visibleForTesting
final class SimulatorRuntime {
  const SimulatorRuntime({
    required this.identifier,
    required this.build,
    required this.version,
    required this.supportedDeviceTypeIds,
  });

  final String identifier;
  final String build;
  final String version;
  final Set<String> supportedDeviceTypeIds;

  @override
  String toString() => 'iOS $version ($build)';
}

List<SimulatorRuntime> _parseAvailableIOSRuntimes(String simctlListRuntimesJson) {
  if (json.decode(simctlListRuntimesJson) case {'runtimes': final List<Object?> runtimes}) {
    return <SimulatorRuntime>[
      for (final Object? runtime in runtimes)
        if (runtime case {
          'platform': 'iOS',
          'isAvailable': true,
          'identifier': final String identifier,
          'buildversion': final String build,
          'version': final String version,
          'supportedDeviceTypes': final List<Object?> deviceTypes,
        })
          SimulatorRuntime(
            identifier: identifier,
            build: build,
            version: version,
            supportedDeviceTypeIds: <String>{
              for (final Object? deviceType in deviceTypes)
                if (deviceType case {'identifier': final String id}) id,
            },
          ),
    ];
  }
  return const <SimulatorRuntime>[];
}

/// Picks the runtime for a [deviceTypeId] simulator from `simctl list runtimes`
/// and `simctl runtime match list` JSON output.
///
/// Prefers the selected Xcode's runtime if it supports [deviceTypeId],
/// otherwise the last compatible runtime. Throws if none is compatible.
@visibleForTesting
SimulatorRuntime selectIOSSimulatorRuntime({
  required String simctlListRuntimesJson,
  required String simctlRuntimeMatchListJson,
  required String deviceTypeId,
}) {
  // mac_toolchain may set userOverriddenBuild in CI. Otherwise use the build
  // simctl matched to the selected Xcode's iOS SDK, which older simctl versions
  // (Xcode < 27) call "preferredBuild" and newer versions (Xcode >= 27) call
  // "chosenRuntimeBuild".
  final decodeResult = json.decode(simctlRuntimeMatchListJson) as Map<String, Object?>;
  final String? iosKey = decodeResult.keys
      .where((String key) => key.contains('iphoneos'))
      .firstOrNull;
  final String? runtimeBuildForSelectedXcode = switch (decodeResult[iosKey]) {
    {'userOverriddenBuild': final String build} => build,
    {'chosenRuntimeBuild': final String build} => build,
    {'preferredBuild': final String build} => build,
    _ => null,
  };

  // Some runtimes (e.g. iOS 27.1) only support a few device types.
  final List<SimulatorRuntime> compatibleRuntimes = _parseAvailableIOSRuntimes(
    simctlListRuntimesJson,
  ).where((SimulatorRuntime r) => r.supportedDeviceTypeIds.contains(deviceTypeId)).toList();
  if (compatibleRuntimes.isEmpty) {
    throw 'No iOS simulator runtime supports $deviceTypeId. Available runtimes:\n$simctlListRuntimesJson';
  }
  final SimulatorRuntime runtime =
      compatibleRuntimes.firstWhereOrNull(
        (SimulatorRuntime r) => r.build == runtimeBuildForSelectedXcode,
      ) ??
      compatibleRuntimes.last;
  if (runtimeBuildForSelectedXcode != null && runtime.build != runtimeBuildForSelectedXcode) {
    print(
      'Runtime $runtimeBuildForSelectedXcode for the selected Xcode does not '
      'support $deviceTypeId. Falling back to $runtime.',
    );
  }
  return runtime;
}

/// Creates and boots a new simulator, passes the new simulator's identifier to
/// `testFunction`.
///
/// Remember to call removeIOSSimulator in the test teardown.
Future<void> testWithNewIOSSimulator(
  String deviceName,
  SimulatorFunction testFunction, {
  String deviceTypeId = 'com.apple.CoreSimulator.SimDeviceType.iPhone-11',
}) async {
  final String availableRuntimes = await eval('xcrun', <String>[
    'simctl',
    'list',
    'runtimes',
    '--json',
  ], workingDirectory: flutterDirectory.path);

  final String runtimesForSelectedXcode = await eval('xcrun', <String>[
    'simctl',
    'runtime',
    'match',
    'list',
    '--json',
  ], workingDirectory: flutterDirectory.path);

  final SimulatorRuntime runtime = selectIOSSimulatorRuntime(
    simctlListRuntimesJson: availableRuntimes,
    simctlRuntimeMatchListJson: runtimesForSelectedXcode,
    deviceTypeId: deviceTypeId,
  );

  final String deviceId = await eval('xcrun', <String>[
    'simctl',
    'create',
    deviceName,
    deviceTypeId,
    runtime.identifier,
  ], workingDirectory: flutterDirectory.path);
  await eval('xcrun', <String>[
    'simctl',
    'boot',
    deviceId,
  ], workingDirectory: flutterDirectory.path);

  await testFunction(deviceId);
}

/// Shuts down and deletes simulator with deviceId.
Future<void> removeIOSSimulator(String? deviceId) async {
  if (deviceId != null && deviceId != '') {
    await eval(
      'xcrun',
      <String>['simctl', 'shutdown', deviceId],
      canFail: true,
      workingDirectory: flutterDirectory.path,
    );
    await eval(
      'xcrun',
      <String>['simctl', 'delete', deviceId],
      canFail: true,
      workingDirectory: flutterDirectory.path,
    );
  }
}

Future<bool> runXcodeTests({
  required String platformDirectory,
  required String destination,
  required String testName,
  List<String> actions = const <String>['test'],
  String configuration = 'Release',
  List<String> extraOptions = const <String>[],
  String scheme = 'Runner',
  bool skipCodesign = false,
}) {
  return runXcodeBuild(
    platformDirectory: platformDirectory,
    destination: destination,
    testName: testName,
    actions: actions,
    configuration: configuration,
    extraOptions: extraOptions,
    scheme: scheme,
    skipCodesign: skipCodesign,
  );
}

Future<bool> runXcodeBuild({
  required String platformDirectory,
  required String destination,
  required String testName,
  List<String> actions = const <String>['build'],
  String configuration = 'Release',
  List<String> extraOptions = const <String>[],
  String scheme = 'Runner',
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
  File? disabledSandboxEntitlementFile;
  if (platformDirectory.endsWith('macos')) {
    disabledSandboxEntitlementFile = _createDisabledSandboxEntitlementFile(
      platformDirectory,
      configuration,
    );
  }
  final String resultBundleTemp = Directory.systemTemp.createTempSync('flutter_xcresult.').path;
  final String resultBundlePath = path.join(resultBundleTemp, 'result');
  final int testResultExit = await exec(
    'xcodebuild',
    <String>[
      '-workspace',
      'Runner.xcworkspace',
      '-scheme',
      scheme,
      '-configuration',
      configuration,
      '-destination',
      destination,
      '-resultBundlePath',
      resultBundlePath,
      ...actions,
      ...extraOptions,
      'COMPILER_INDEX_STORE_ENABLE=NO',
      if (developmentTeam != null) 'DEVELOPMENT_TEAM=$developmentTeam',
      if (codeSignStyle != null) 'CODE_SIGN_STYLE=$codeSignStyle',
      if (provisioningProfile != null) 'PROVISIONING_PROFILE_SPECIFIER=$provisioningProfile',
      if (disabledSandboxEntitlementFile != null)
        'CODE_SIGN_ENTITLEMENTS=${disabledSandboxEntitlementFile.path}',
    ],
    workingDirectory: platformDirectory,
    canFail: true,
  );

  if (testResultExit != 0) {
    final Directory? dumpDirectory = hostAgent.dumpDirectory;
    final xcresultBundle = Directory(path.join(resultBundleTemp, 'result.xcresult'));
    if (dumpDirectory != null) {
      if (xcresultBundle.existsSync()) {
        // Zip the test results to the artifacts directory for upload.
        final String zipPath = path.join(
          dumpDirectory.path,
          '$testName-${DateTime.now().toLocal().toIso8601String()}.zip',
        );
        await exec(
          'zip',
          <String>['-r', '-9', '-q', zipPath, path.basename(xcresultBundle.path)],
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

/// Finds and copies macOS entitlements file. In the copy, disables sandboxing.
/// If entitlements file is not found, returns null.
///
/// As of macOS 14, testing a macOS sandbox app may prompt the user to grant
/// access to the app. To workaround this in CI, we create and use a entitlements
/// file with sandboxing disabled. See
/// https://developer.apple.com/documentation/security/app_sandbox/accessing_files_from_the_macos_app_sandbox.
File? _createDisabledSandboxEntitlementFile(String platformDirectory, String configuration) {
  String entitlementDefaultFileName;
  if (configuration == 'Release') {
    entitlementDefaultFileName = 'Release';
  } else {
    entitlementDefaultFileName = 'DebugProfile';
  }

  final String entitlementFilePath = path.join(
    platformDirectory,
    'Runner',
    '$entitlementDefaultFileName.entitlements',
  );
  final entitlementFile = File(entitlementFilePath);

  if (!entitlementFile.existsSync()) {
    print('Unable to find entitlements file at ${entitlementFile.path}');
    return null;
  }

  final String originalEntitlementFileContents = entitlementFile.readAsStringSync();
  final String tempEntitlementPath = Directory.systemTemp
      .createTempSync('flutter_disable_sandbox_entitlement.')
      .path;
  final disabledSandboxEntitlementFile = File(
    path.join(
      tempEntitlementPath,
      '${entitlementDefaultFileName}WithDisabledSandboxing.entitlements',
    ),
  );
  disabledSandboxEntitlementFile.createSync(recursive: true);
  disabledSandboxEntitlementFile.writeAsStringSync(
    originalEntitlementFileContents.replaceAll(
      RegExp(r'<key>com\.apple\.security\.app-sandbox<\/key>[\S\s]*?<true\/>'),
      '''
<key>com.apple.security.app-sandbox</key>
	<false/>''',
    ),
  );

  return disabledSandboxEntitlementFile;
}

/// Returns global (external) symbol table entries, delimited by new lines.
Future<String> dumpSymbolTable(String filePath) {
  return eval('nm', <String>['--extern-only', '--just-symbol-name', filePath, '-arch', 'arm64']);
}
