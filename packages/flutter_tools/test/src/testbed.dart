// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/process.dart';

import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'common.dart' as tester;
import 'context.dart';
import 'fake_http_client.dart';
import 'throwing_pub.dart';

export 'package:flutter_tools/src/base/context.dart' show Generator;

// A default value should be provided if the vast majority of tests should use
// this provider. For example, [BufferLogger], [MemoryFileSystem].
final Map<Type, Generator> _testbedDefaults = <Type, Generator>{
  // Keeps tests fast by avoiding the actual file system.
  FileSystem: () => MemoryFileSystem(style: globals.platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix),
  ProcessManager: () => FakeProcessManager.any(),
  Logger: () => BufferLogger(
    terminal: AnsiTerminal(stdio: globals.stdio, platform: globals.platform),  // Danger, using real stdio.
    outputPreferences: OutputPreferences.test(),
  ), // Allows reading logs and prevents stdout.
  OperatingSystemUtils: () => FakeOperatingSystemUtils(),
  OutputPreferences: () => OutputPreferences.test(), // configures BufferLogger to avoid color codes.
  Usage: () => NoOpUsage(), // prevent addition of analytics from burdening test mocks
  FlutterVersion: () => FakeFlutterVersion(), // prevent requirement to mock git for test runner.
  Signals: () => FakeSignals(),  // prevent registering actual signal handlers.
  Pub: () => ThrowingPub(), // prevent accidental invocations of pub.
};

/// Manages interaction with the tool injection and runner system.
///
/// The Testbed automatically injects reasonable defaults through the context
/// DI system such as a [BufferLogger] and a [MemoryFileSytem].
///
/// Example:
///
/// Testing that a filesystem operation works as expected:
///
///     void main() {
///       group('Example', () {
///         Testbed testbed;
///
///         setUp(() {
///           testbed = Testbed(setUp: () {
///             globals.fs.file('foo').createSync()
///           });
///         })
///
///         test('Can delete a file', () => testbed.run(() {
///           expect(globals.fs.file('foo').existsSync(), true);
///           globals.fs.file('foo').deleteSync();
///           expect(globals.fs.file('foo').existsSync(), false);
///         }));
///       });
///     }
///
/// For a more detailed example, see the code in test_compiler_test.dart.
class Testbed {
  /// Creates a new [TestBed]
  ///
  /// `overrides` provides more overrides in addition to the test defaults.
  /// `setup` may be provided to apply mocks within the tool managed zone,
  /// including any specified overrides.
  Testbed({FutureOr<void> Function() setup, Map<Type, Generator> overrides})
      : _setup = setup,
        _overrides = overrides;

  final FutureOr<void> Function() _setup;
  final Map<Type, Generator> _overrides;

  /// Runs the `test` within a tool zone.
  ///
  /// Unlike [run], this sets up a test group on its own.
  @isTest
  void test<T>(String name, FutureOr<T> Function() test, {Map<Type, Generator> overrides}) {
    tester.test(name, () {
      return run(test, overrides: overrides);
    });
  }

  /// Runs `test` within a tool zone.
  ///
  /// `overrides` may be used to provide new context values for the single test
  /// case or override any context values from the setup.
  Future<T> run<T>(FutureOr<T> Function() test, {Map<Type, Generator> overrides}) {
    final Map<Type, Generator> testOverrides = <Type, Generator>{
      ..._testbedDefaults,
      // Add the initial setUp overrides
      ...?_overrides,
      // Add the test-specific overrides
      ...?overrides,
    };
    if (testOverrides.containsKey(ProcessUtils)) {
      throw StateError('Do not inject ProcessUtils for testing, use ProcessManager instead.');
    }
    // Cache the original flutter root to restore after the test case.
    final String originalFlutterRoot = Cache.flutterRoot;
    // Track pending timers to verify that they were correctly cleaned up.
    final Map<Timer, StackTrace> timers = <Timer, StackTrace>{};

    return HttpOverrides.runZoned(() {
      return runInContext<T>(() {
        return context.run<T>(
          name: 'testbed',
          overrides: testOverrides,
          zoneSpecification: ZoneSpecification(
            createTimer: (Zone self, ZoneDelegate parent, Zone zone, Duration duration, void Function() timer) {
              final Timer result = parent.createTimer(zone, duration, timer);
              timers[result] = StackTrace.current;
              return result;
            },
            createPeriodicTimer: (Zone self, ZoneDelegate parent, Zone zone, Duration period, void Function(Timer) timer) {
              final Timer result = parent.createPeriodicTimer(zone, period, timer);
              timers[result] = StackTrace.current;
              return result;
            },
          ),
          body: () async {
            Cache.flutterRoot = '';
            if (_setup != null) {
              await _setup();
            }
            await test();
            Cache.flutterRoot = originalFlutterRoot;
            for (final MapEntry<Timer, StackTrace> entry in timers.entries) {
              if (entry.key.isActive) {
                throw StateError('A Timer was active at the end of a test: ${entry.value}');
              }
            }
            return null;
          });
      });
    }, createHttpClient: (SecurityContext c) => FakeHttpClient.any());
  }
}

/// A no-op implementation of [Usage] for testing.
class NoOpUsage implements Usage {
  @override
  bool enabled = false;

  @override
  bool suppressAnalytics = true;

  @override
  String get clientId => 'test';

  @override
  Future<void> ensureAnalyticsSent() {
    return null;
  }

  @override
  Stream<Map<String, Object>> get onSend => const Stream<Map<String, Object>>.empty();

  @override
  void printWelcome() {}

  @override
  void sendCommand(String command, {Map<String, String> parameters}) {}

  @override
  void sendEvent(String category, String parameter, {
    String label,
    int value,
    Map<String, String> parameters,
  }) {}

  @override
  void sendException(dynamic exception) {}

  @override
  void sendTiming(String category, String variableName, Duration duration, { String label }) {}
}

class FakeFlutterVersion implements FlutterVersion {
  @override
  void fetchTagsAndUpdate() {  }

  @override
  String get channel => 'master';

  @override
  Future<void> checkFlutterVersionFreshness() async { }

  @override
  bool checkRevisionAncestry({String tentativeDescendantRevision, String tentativeAncestorRevision}) {
    throw UnimplementedError();
  }

  @override
  String get dartSdkVersion => '12';

  @override
  String get engineRevision => '42.2';

  @override
  String get engineRevisionShort => '42';

  @override
  Future<void> ensureVersionFile() async { }

  @override
  String get frameworkAge => null;

  @override
  String get frameworkCommitDate => null;

  @override
  String get frameworkDate => null;

  @override
  String get frameworkRevision => null;

  @override
  String get frameworkRevisionShort => null;

  @override
  String get frameworkVersion => null;

  @override
  GitTagVersion get gitTagVersion => null;

  @override
  String getBranchName({bool redactUnknownBranches = false}) {
    return 'master';
  }

  @override
  String getVersionString({bool redactUnknownBranches = false}) {
    return 'v0.0.0';
  }

  @override
  String get repositoryUrl => null;

  @override
  Map<String, Object> toJson() {
    return null;
  }
}

// A test implementation of [FeatureFlags] that allows enabling without reading
// config. If not otherwise specified, all values default to false.
class TestFeatureFlags implements FeatureFlags {
  TestFeatureFlags({
    this.isLinuxEnabled = false,
    this.isMacOSEnabled = false,
    this.isWebEnabled = false,
    this.isWindowsEnabled = false,
    this.isSingleWidgetReloadEnabled = false,
    this.isAndroidEnabled = true,
    this.isIOSEnabled = true,
    this.isFuchsiaEnabled = false,
    this.isExperimentalInvalidationStrategyEnabled = false,
  });

  @override
  final bool isLinuxEnabled;

  @override
  final bool isMacOSEnabled;

  @override
  final bool isWebEnabled;

  @override
  final bool isWindowsEnabled;

  @override
  final bool isSingleWidgetReloadEnabled;

  @override
  final bool isAndroidEnabled;

  @override
  final bool isIOSEnabled;

  @override
  final bool isFuchsiaEnabled;

  @override
  final bool isExperimentalInvalidationStrategyEnabled;

  @override
  bool isEnabled(Feature feature) {
    switch (feature) {
      case flutterWebFeature:
        return isWebEnabled;
      case flutterLinuxDesktopFeature:
        return isLinuxEnabled;
      case flutterMacOSDesktopFeature:
        return isMacOSEnabled;
      case flutterWindowsDesktopFeature:
        return isWindowsEnabled;
      case singleWidgetReload:
        return isSingleWidgetReloadEnabled;
      case flutterAndroidFeature:
        return isAndroidEnabled;
      case flutterIOSFeature:
        return isIOSEnabled;
      case flutterFuchsiaFeature:
        return isFuchsiaEnabled;
      case experimentalInvalidationStrategy:
        return isExperimentalInvalidationStrategyEnabled;
    }
    return false;
  }
}

class FakeStatusLogger extends DelegatingLogger {
  FakeStatusLogger(Logger delegate) : super(delegate);

  Status status;

  @override
  Status startProgress(String message, {Duration timeout, String progressId, bool multilineOutput = false, int progressIndicatorPadding = kDefaultStatusPadding}) {
    return status;
  }
}

/// An implementation of the Cache which does not download or require locking.
class FakeCache implements Cache {
  @override
  bool includeAllPlatforms;

  @override
  Set<String> platformOverrideArtifacts;

  @override
  bool useUnsignedMacBinaries;

  @override
  Future<bool> areRemoteArtifactsAvailable({String engineVersion, bool includeAllPlatforms = true}) async {
    return true;
  }

  @override
  String get dartSdkVersion => null;

  @override
  String get storageBaseUrl => null;

  @override
  MapEntry<String, String> get dyLdLibEntry => const MapEntry<String, String>('DYLD_LIBRARY_PATH', '');

  @override
  String get engineRevision => null;

  @override
  Directory getArtifactDirectory(String name) {
    return globals.fs.currentDirectory;
  }

  @override
  Directory getCacheArtifacts() {
    return globals.fs.currentDirectory;
  }

  @override
  Directory getCacheDir(String name) {
    return globals.fs.currentDirectory;
  }

  @override
  Directory getDownloadDir() {
    return globals.fs.currentDirectory;
  }

  @override
  Directory getRoot() {
    return globals.fs.currentDirectory;
  }

  @override
  String getHostPlatformArchName() => 'x64';

  @override
  File getLicenseFile() {
    return globals.fs.currentDirectory.childFile('LICENSE');
  }

  @override
  File getStampFileFor(String artifactName) {
    throw UnsupportedError('Not supported in the fake Cache');
  }

  @override
  String getStampFor(String artifactName) {
    throw UnsupportedError('Not supported in the fake Cache');
  }

  @override
  String getVersionFor(String artifactName) {
    throw UnsupportedError('Not supported in the fake Cache');
  }

  @override
  Directory getWebSdkDirectory() {
    return globals.fs.currentDirectory;
  }

  @override
  bool isOlderThanToolsStamp(FileSystemEntity entity) {
    return false;
  }

  @override
  Future<bool> isUpToDate() async {
    return true;
  }

  @override
  void setStampFor(String artifactName, String version) {
    throw UnsupportedError('Not supported in the fake Cache');
  }

  @override
  Future<void> updateAll(Set<DevelopmentArtifact> requiredArtifacts) async {
  }

  @override
  Future<bool> doesRemoteExist(String message, Uri url) async {
    return true;
  }

  @override
  void clearStampFiles() { }

  @override
  void checkLockAcquired() { }

  @override
  Future<void> lock() async { }

  @override
  void releaseLock() { }
}
