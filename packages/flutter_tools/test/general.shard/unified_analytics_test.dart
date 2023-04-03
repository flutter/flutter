// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../src/common.dart';

void main() {
  late Analytics analytics;
  late FileSystem fs;
  late Directory home;
  late File clientIdFile;
  late File configFile;

  const String homeDirName = 'home';
  const String dartToolDirectory = '.dart-tool';
  const String clientIdFileName = 'CLIENT_ID';
  const String configFileName = 'dart-flutter-telemetry.config';

  const DashTool dashTool = DashTool.flutterTool;

  setUp(() {
    // Provide the override values
    final FileSystemStyle fsStyle =
        io.Platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix;
    fs = MemoryFileSystem.test(style: fsStyle);
    home = fs.directory(homeDirName);

    analytics = Analytics(
      tool: dashTool,
      flutterChannel: 'flutterVersion.channel',
      flutterVersion: 'flutterVersion.frameworkVersion',
      dartVersion: 'flutterVersion.dartSdkVersion',
      fsOverride: fs,
      homeOverride: home,
    );

    // The 3 files that should have been generated
    clientIdFile =
        home.childDirectory(dartToolDirectory).childFile(clientIdFileName);
    configFile =
        home.childDirectory(dartToolDirectory).childFile(configFileName);
  });

  testWithoutContext('Initialization works properly', () {
    expect(clientIdFile.existsSync(), true,
        reason: 'Client ID file will be generated on initialization');
    expect(configFile.existsSync(), true);
    expect(analytics.shouldShowMessage, true);
    expect(analytics.parsedTools.containsKey(dashTool.label), false);

    // Simulates showing the message
    analytics.clientShowedMessage();

    // Check that the flutter tool has been added
    expect(analytics.parsedTools.containsKey(dashTool.label), true);
  });

  testWithoutContext('Setting telemetry is successful', () async {
    expect(analytics.shouldShowMessage, true);
    expect(analytics.telemetryEnabled, true);

    // This is required for a newly added tool
    analytics.clientShowedMessage();

    await analytics.setTelemetry(false);

    expect(analytics.telemetryEnabled, false);

    // Simulate a new instance disabling analytics
    final Analytics secondAnalytics = Analytics(
      tool: dashTool,
      flutterChannel: 'flutterVersion.channel',
      flutterVersion: 'flutterVersion.frameworkVersion',
      dartVersion: 'flutterVersion.dartSdkVersion',
      fsOverride: fs,
      homeOverride: home,
    );
    expect(secondAnalytics.telemetryEnabled, false);

    await secondAnalytics.setTelemetry(true);

    expect(analytics.telemetryEnabled, true);
    expect(secondAnalytics.telemetryEnabled, true);
  });
}
