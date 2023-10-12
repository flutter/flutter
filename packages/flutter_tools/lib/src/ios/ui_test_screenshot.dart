// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:xml/xml_events.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process.dart';
import '../cache.dart';
import 'core_devices.dart';

/// Takes a screenshot of the device by using a UI Test.
///
/// Since this requires the UI Test to be codesigned, it should only be used in
/// Flutter CI and not by a user.
class UITestScreenshot {
  UITestScreenshot({
    required FileSystem fileSystem,
    required ProcessUtils processUtils,
    this.environment,
    IOSCoreDeviceControl? coreDeviceControl,
    String? flutterRoot,
  }) : _fileSystem = fileSystem,
       _processUtils = processUtils,
       _coreDeviceControl = coreDeviceControl,
       _flutterRoot = flutterRoot;


  final FileSystem _fileSystem;
  final ProcessUtils _processUtils;
  final String? _flutterRoot;
  final IOSCoreDeviceControl? _coreDeviceControl;
  final Map<String, String>? environment;

  String get uiTestScreenshotXcodeProject {
    final String flutterRoot = _flutterRoot ?? Cache.flutterRoot!;

    final String projectPath = '$flutterRoot/dev/tools/UITestScreenshot';
    if (!_fileSystem.directory(projectPath).existsSync()) {
      throwToolExit('Unable to find UI Test Screenshot Xcode project at $projectPath');
    }
    return projectPath;
  }

  Future<void> takeScreenshot(
    File outputFile, {
    required UITestScreenshotCompatibleTargets target,
    String? deviceId,
  }) async {
    if (target == UITestScreenshotCompatibleTargets.ios && deviceId == null) {
      throwToolExit('A device id must be supplied for iOS devices.');
    }

    if (target == UITestScreenshotCompatibleTargets.ios && _coreDeviceControl == null) {
      throwToolExit('CoreDeviceControl is required for iOS devices.');
    }

    final String resultBundleTemp = _fileSystem.systemTempDirectory.createTempSync('flutter_xcresult.').path;
    final String resultBundlePath = _fileSystem.path.join(resultBundleTemp, 'result');

    String? developmentTeam;
    String? codeSignStyle;
    String? provisioningProfile;
    if (environment != null) {
      developmentTeam = environment!['FLUTTER_XCODE_DEVELOPMENT_TEAM'];
      codeSignStyle = environment!['FLUTTER_XCODE_CODE_SIGN_STYLE'];
      provisioningProfile = environment!['FLUTTER_XCODE_PROVISIONING_PROFILE_SPECIFIER'];
    }

    final RunResult result = await _processUtils.run(
      <String>[
        'xcrun',
        'xcodebuild',
        '-scheme',
        'UITestScreenshot',
        '-destination',
        if (target == UITestScreenshotCompatibleTargets.ios)
          'id=$deviceId',
        if (target == UITestScreenshotCompatibleTargets.macos)
          'platform=macOS',
        '-resultBundlePath',
        resultBundlePath,
        '-only-testing:UITestScreenshotUITests',
        'test',
        'COMPILER_INDEX_STORE_ENABLE=NO',
        if (developmentTeam != null)
          'DEVELOPMENT_TEAM=$developmentTeam',
        if (codeSignStyle != null)
          'CODE_SIGN_STYLE=$codeSignStyle',
        if (provisioningProfile != null)
          'PROVISIONING_PROFILE_SPECIFIER=$provisioningProfile',
      ],
      workingDirectory: uiTestScreenshotXcodeProject,
    );

    if (result.exitCode != 0) {
      throwToolExit('Failed to take screenshot: ${result.stderr}');
    }

    final RunResult resultJson = await _processUtils.run(
      <String>[
        'xcrun',
        'xcresulttool',
        'get',
        '--path',
        resultBundlePath,
        '--format',
        'json'
      ],
    );

    if (resultJson.exitCode != 0) {
      throwToolExit('Failed to get test results: ${resultJson.stderr}');
    }

    final String testsRefId = _parseRef('testsRef', resultJson.stdout);
    final RunResult testsResult = await _getRefResults(testsRefId, resultBundlePath);

    final String summaryRefId = _parseRef('summaryRef', testsResult.stdout);
    final RunResult summaryResult = await _getRefResults(summaryRefId, resultBundlePath);

    final String payloadRefId = _parseRef('payloadRef', summaryResult.stdout);

    final Process payloadProcess = await _processUtils.start(
      <String>[
        'xcrun',
        'xcresulttool',
        'get',
        '--path',
        resultBundlePath,
        '--id',
        payloadRefId,
      ],
    );

    final List<int> imageBytes = await payloadProcess.stdout.flatten().toList();

    await outputFile.writeAsBytes(imageBytes);

    if (target == UITestScreenshotCompatibleTargets.ios && deviceId != null && _coreDeviceControl != null) {
      await _coreDeviceControl.uninstallApp(deviceId: deviceId, bundleId: 'com.example.UITestScreenshotUITests.xctrunner');
    }
  }

  String _parseRef(String refType, String resultContents) {
    final RegExp refRegex = RegExp('$refType[\\S\\s]*?"_value" : "(.*)"');

    final Match? refMatch = refRegex.firstMatch(resultContents);
    if (refMatch == null) {
      throwToolExit('Failed to parse $refType: $resultContents');
    }
    final String? refId = refMatch.group(1);

    if (refId == null) {
      throwToolExit('Failed to parse $refType: $resultContents');
    }

    return refId;
  }

  Future<RunResult> _getRefResults(String refId, String resultBundlePath) async {
    final RunResult results = await _processUtils.run(
      <String>[
        'xcrun',
        'xcresulttool',
        'get',
        '--path',
        resultBundlePath,
        '--id',
        refId,
        '--format',
        'json'
      ],
    );

    if (results.exitCode != 0) {
      throwToolExit('Failed to get results for $refId: ${results.stderr}');
    }

    return results;
  }
}

enum UITestScreenshotCompatibleTargets {
  ios,
  macos,
}
