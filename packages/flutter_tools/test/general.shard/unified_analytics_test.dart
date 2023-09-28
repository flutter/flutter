// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/reporting/unified_analytics.dart';
import 'package:unified_analytics/src/enums.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../src/common.dart';
import '../src/fakes.dart';

void main() {
  const String userBranch = 'abc123';
  const String homeDirectoryName = 'home';
  const DashTool tool = DashTool.flutterTool;

  late FileSystem fs;
  late Directory home;
  late FakeAnalytics analyticsOverride;

  setUp(() {
    fs = MemoryFileSystem.test();
    home = fs.directory(homeDirectoryName);

    // Prepare the tests by "onboarding" the tool into the package
    // by invoking the [clientShowedMessage] method for the provided
    // [tool]
    final FakeAnalytics initialAnalytics = FakeAnalytics(
      tool: tool,
      homeDirectory: home,
      dartVersion: '3.0.0',
      platform: DevicePlatform.macos,
      fs: fs,
      surveyHandler: SurveyHandler(
        homeDirectory: home,
        fs: fs,
      ),
    );
    initialAnalytics.clientShowedMessage();

    analyticsOverride = FakeAnalytics(
      tool: tool,
      homeDirectory: home,
      dartVersion: '3.0.0',
      platform: DevicePlatform.macos,
      fs: fs,
      surveyHandler: SurveyHandler(
        homeDirectory: home,
        fs: fs,
      ),
    );
  });

  group('Unit testing getAnalytics', () {
    testWithoutContext('Successfully creates the instance for standard branch', () {
      final Analytics analytics = getAnalytics(
        runningOnBot: false,
        flutterVersion: FakeFlutterVersion(),
        environment: const <String, String>{},
        analyticsOverride: analyticsOverride,
      );

      expect(analytics.clientId, isNot(NoOpAnalytics.staticClientId),
          reason: 'The CLIENT ID should be a randomly generated id');
      expect(analytics, isNot(isA<NoOpAnalytics>()));
    });

    testWithoutContext('NoOp instance for user branch', () {
      final Analytics analytics = getAnalytics(
        runningOnBot: false,
        flutterVersion: FakeFlutterVersion(
          branch: userBranch,
          frameworkRevision: '3.14.0-14.0.pre.370',
        ),
        environment: const <String, String>{},
        analyticsOverride: analyticsOverride,
      );

      expect(
        analytics.clientId,
        NoOpAnalytics.staticClientId,
        reason: 'The client ID should match the NoOp client id',
      );
      expect(analytics, isA<NoOpAnalytics>());
    });

    testWithoutContext('NoOp instance for unknown branch', () {
      final Analytics analytics = getAnalytics(
        runningOnBot: false,
        flutterVersion: FakeFlutterVersion(
          frameworkRevision: 'unknown',
        ),
        environment: const <String, String>{},
        analyticsOverride: analyticsOverride,
      );

      expect(
        analytics.clientId,
        NoOpAnalytics.staticClientId,
        reason: 'The client ID should match the NoOp client id',
      );
      expect(analytics, isA<NoOpAnalytics>());
    });

    testWithoutContext('NoOp instance when running on bots', () {
      final Analytics analytics = getAnalytics(
        runningOnBot: true,
        flutterVersion: FakeFlutterVersion(),
        environment: const <String, String>{},
        analyticsOverride: analyticsOverride,
      );

      expect(
        analytics.clientId,
        NoOpAnalytics.staticClientId,
        reason: 'The client ID should match the NoOp client id',
      );
      expect(analytics, isA<NoOpAnalytics>());
    });

    testWithoutContext('NoOp instance when suppressing via env variable', () {
      final Analytics analytics = getAnalytics(
        runningOnBot: true,
        flutterVersion: FakeFlutterVersion(),
        environment: const <String, String>{'FLUTTER_SUPPRESS_ANALYTICS': 'true'},
        analyticsOverride: analyticsOverride,
      );

      expect(
        analytics.clientId,
        NoOpAnalytics.staticClientId,
        reason: 'The client ID should match the NoOp client id',
      );
      expect(analytics, isA<NoOpAnalytics>());
    });
  });
}
