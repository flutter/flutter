// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/reporting/unified_analytics.dart';
import 'package:package_config/package_config.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../src/common.dart';
import '../src/fakes.dart';

void main() {
  const String userBranch = 'abc123';
  const String clientIde = 'VSCode';

  late FileSystem fs;
  late FakeAnalytics analyticsOverride;

  setUp(() {
    fs = MemoryFileSystem.test();

    analyticsOverride = getInitializedFakeAnalyticsInstance(
      fs: fs,
      fakeFlutterVersion: FakeFlutterVersion(
        branch: userBranch,
      ),
      clientIde: clientIde,
    );
  });

  group('Unit testing getAnalytics', () {
    testWithoutContext('Successfully creates the instance for standard branch', () {
      final Analytics analytics = getAnalytics(
        runningOnBot: false,
        flutterVersion: FakeFlutterVersion(),
        environment: const <String, String>{},
        analyticsOverride: analyticsOverride,
        clientIde: clientIde,
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
        clientIde: clientIde,
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
        clientIde: clientIde,
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
        clientIde: clientIde,
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
        runningOnBot: false,
        flutterVersion: FakeFlutterVersion(),
        environment: const <String, String>{'FLUTTER_SUPPRESS_ANALYTICS': 'true'},
        analyticsOverride: analyticsOverride,
        clientIde: clientIde,
      );

      expect(
        analytics.clientId,
        NoOpAnalytics.staticClientId,
        reason: 'The client ID should match the NoOp client id',
      );
      expect(analytics, isA<NoOpAnalytics>());
    });

    testWithoutContext('Suppression prevents events from being sent', () {
      expect(analyticsOverride.okToSend, true);
      analyticsOverride.send(Event.surveyShown(surveyId: 'surveyId'));
      expect(analyticsOverride.sentEvents, hasLength(1));

      analyticsOverride.suppressTelemetry();
      expect(analyticsOverride.okToSend, false);
      analyticsOverride.send(Event.surveyShown(surveyId: 'surveyId'));

      expect(analyticsOverride.sentEvents, hasLength(1));
    });

    testWithoutContext('Client IDE is passed and found in events', () {
      final Analytics analytics = getAnalytics(
        runningOnBot: false,
        flutterVersion: FakeFlutterVersion(),
        environment: const <String, String>{},
        analyticsOverride: analyticsOverride,
        clientIde: clientIde,
      );
      analytics as FakeAnalytics;

      expect(analytics.userProperty.clientIde, 'VSCode');
    });

    testWithoutContext('getNullSafetyAnalysisInfo returns null correctly', () {
      final FakePackageConfig fakePackageConfig = FakePackageConfig(
        providedPackages: <Package>[],
      );
      const NullSafetyMode nullSafetyMode = NullSafetyMode.sound;
      const String currentPackage = 'my-package';

      final Map<String, Object>? analysisInfo = getNullSafetyAnalysisInfo(
        packageConfig: fakePackageConfig,
        nullSafetyMode: nullSafetyMode,
        currentPackage: currentPackage,
      );

      expect(analysisInfo, isNull);
    });

    testWithoutContext('getNullSafetyAnalysisInfo returns map correctly', () {
      final FakePackage fakePackage = FakePackage(
        name: 'my-package',
        languageVersion: LanguageVersion(2, 15),
      );

      final FakePackageConfig fakePackageConfig = FakePackageConfig(
        providedPackages: <Package>[fakePackage],
      );
      const NullSafetyMode nullSafetyMode = NullSafetyMode.sound;
      const String currentPackage = 'my-package';

      final Map<String, Object>? analysisInfo = getNullSafetyAnalysisInfo(
        packageConfig: fakePackageConfig,
        nullSafetyMode: nullSafetyMode,
        currentPackage: currentPackage,
      );

      expect(analysisInfo, isNotNull);
      expect(analysisInfo!['runtimeMode'], 'NullSafetyMode.sound');
      expect(analysisInfo['nullSafeMigratedLibraries'], 1);
      expect(analysisInfo['nullSafeTotalLibraries'], 1);
      expect(analysisInfo['languageVersion'], '2.15');
    });

    testWithoutContext('getNullSafetyAnalysisInfo returns map correctly when package name is different', () {
      final FakePackage fakePackage = FakePackage(
        name: 'my-different-package', // Different package name from [currentPackage]
        languageVersion: LanguageVersion(2, 15),
      );

      final FakePackageConfig fakePackageConfig = FakePackageConfig(
        providedPackages: <Package>[fakePackage],
      );
      const NullSafetyMode nullSafetyMode = NullSafetyMode.sound;
      const String currentPackage = 'my-package';

      final Map<String, Object>? analysisInfo = getNullSafetyAnalysisInfo(
        packageConfig: fakePackageConfig,
        nullSafetyMode: nullSafetyMode,
        currentPackage: currentPackage,
      );

      expect(analysisInfo, isNotNull);
      expect(analysisInfo!['runtimeMode'], 'NullSafetyMode.sound');
      expect(analysisInfo['nullSafeMigratedLibraries'], 1);
      expect(analysisInfo['nullSafeTotalLibraries'], 1);
      expect(analysisInfo['languageVersion'], isNull);
    });

    testWithoutContext('getNullSafetyAnalysisInfo returns correctly identifies non-migrated packages', () {
      final FakePackage fakePackage = FakePackage(
        name: 'my-package',
        languageVersion: LanguageVersion(2, 10),
      );

      final FakePackageConfig fakePackageConfig = FakePackageConfig(
        providedPackages: <Package>[fakePackage],
      );
      const NullSafetyMode nullSafetyMode = NullSafetyMode.sound;
      const String currentPackage = 'my-package';

      final Map<String, Object>? analysisInfo = getNullSafetyAnalysisInfo(
        packageConfig: fakePackageConfig,
        nullSafetyMode: nullSafetyMode,
        currentPackage: currentPackage,
      );

      expect(analysisInfo, isNotNull);
      expect(analysisInfo!['runtimeMode'], 'NullSafetyMode.sound');
      expect(analysisInfo['nullSafeMigratedLibraries'], 0);
      expect(analysisInfo['nullSafeTotalLibraries'], 1);
      expect(analysisInfo['languageVersion'], '2.10');
    });
  });
}

class FakePackageConfig extends Fake implements PackageConfig {

  FakePackageConfig({required Iterable<Package> providedPackages,}): _packages = providedPackages;
  
  @override
  Iterable<Package> get packages => _packages;

  final Iterable<Package> _packages;
}

class FakePackage extends Fake implements Package {
  FakePackage({
    required this.name,
    required this.languageVersion,
  });

  @override
  final String name;

  @override
  final LanguageVersion languageVersion;
}
