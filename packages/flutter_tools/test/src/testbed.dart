// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show HttpOverrides, SecurityContext;

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/flutter_cache.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'context.dart';
import 'fake_http_client.dart';
import 'fakes.dart';
import 'throwing_pub.dart';

export 'package:flutter_tools/src/base/context.dart' show Generator;

Platform _contextPlatform() => context.get<Platform>() ?? const LocalPlatform();

FileSystem _contextFileSystem() =>
    ErrorHandlingFileSystem(delegate: context.get<FileSystem>()!, platform: _contextPlatform());

FlutterProjectFactory _contextProjectFactory() =>
    context.get<FlutterProjectFactory>() ??
    FlutterProjectFactory(
      config: context.get<Config>()!,
      featureFlagsBuilder: () => featureFlags,
      fileSystem: _contextFileSystem(),
      logger: context.get<Logger>()!,
      plistParser:
          context.get<PlistParser>() ??
          PlistParser(
            fileSystem: _contextFileSystem(),
            processManager: context.get<ProcessManager>() ?? const LocalProcessManager(),
            logger: context.get<Logger>()!,
          ),
      xcodeBuilder: () => context.get<Xcode>(),
      xcodeProjectInterpreterBuilder: () => context.get<XcodeProjectInterpreter>(),
    );

// A default value should be provided if the vast majority of tests should use
// this provider. For example, [BufferLogger], [MemoryFileSystem].
final _testbedDefaults = <Type, Generator>{
  // Keeps tests fast by avoiding the actual file system.
  FileSystem: () => MemoryFileSystem(
    style: _contextPlatform().isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
  ),
  ProcessManager: () => FakeProcessManager.any(),
  Logger: () => BufferLogger(
    terminal: AnsiTerminal(
      stdio: context.get<Stdio>() ?? Stdio(),
      platform: _contextPlatform(),
    ), // Danger, using real stdio.
    outputPreferences: OutputPreferences.test(),
  ), // Allows reading logs and prevents stdout.
  OperatingSystemUtils: () => FakeOperatingSystemUtils(),
  OutputPreferences: () =>
      OutputPreferences.test(), // configures BufferLogger to avoid color codes.
  Analytics: () => const NoOpAnalytics(),
  FlutterVersion: () => FakeFlutterVersion(), // prevent requirement to mock git for test runner.
  Signals: () => FakeSignals(), // prevent registering actual signal handlers.
  PlistParser: () => FakePlistParser(),
  Pub: () => const ThrowingPub(), // prevent accidental invocations of pub.
  BotDetector: () => const FakeBotDetector(true),
  Cache: () => FlutterCache(
    flutterRoot: '',
    fileSystem: _contextFileSystem(),
    logger: context.get<Logger>()!,
    platform: _contextPlatform(),
    osUtils: context.get<OperatingSystemUtils>()!,
    projectFactory: _contextProjectFactory(),
  ),
  Config: () => Config.test(
    name: Config.kFlutterSettings,
    directory: _contextFileSystem().systemTempDirectory.createTempSync('flutter_config_dir_test.'),
    logger: context.get<Logger>(),
  ),
  PersistentToolState: () => PersistentToolState.test(
    directory: _contextFileSystem().systemTempDirectory.createTempSync('flutter_config_dir_test.'),
    logger: context.get<Logger>()!,
  ),
};

/// Manages interaction with the tool injection and runner system.
///
/// The Testbed automatically injects reasonable defaults through the context
/// DI system such as a [BufferLogger] and a [MemoryFileSystem].
///
/// Example:
///
/// Testing that a filesystem operation works as expected:
///
/// ```dart
/// void main() {
///   group('Example', () {
///     late TestBed testbed;
///
///     setUp(() {
///       testbed = TestBed(setUp: () {
///         context.get<FileSystem>()!.file('foo').createSync();
///       });
///     });
///
///     test('Can delete a file', () => testbed.run(() {
///       final FileSystem fs = context.get<FileSystem>()!;
///       expect(fs.file('foo').existsSync(), true);
///       fs.file('foo').deleteSync();
///       expect(fs.file('foo').existsSync(), false);
///     }));
///   });
/// }
/// ```
///
/// For a more detailed example, see the code in test_compiler_test.dart.
class TestBed {
  /// Creates a new [TestBed]
  ///
  /// `overrides` provides more overrides in addition to the test defaults.
  /// `setup` may be provided to apply mocks within the tool managed zone,
  /// including any specified overrides.
  TestBed({this._setup, this._overrides});

  static final Object _inTestBedKey = Object();

  /// Returns a [ToolContext] backed by the active [TestBed] zone, or `null`
  /// when called outside [TestBed.run].
  static ToolContext? createToolContext() {
    if (Zone.current[_inTestBedKey] != true || Zone.current[contextKey] == null) {
      return null;
    }
    final Platform platform = _contextPlatform();
    return FakeToolContext(
      artifacts: context.get<Artifacts>(),
      cache: context.get<Cache>(),
      config: context.get<Config>(),
      fs: _contextFileSystem(),
      flutterVersion: context.get<FlutterVersion>(),
      logger: context.get<Logger>(),
      platform: platform,
      processManager: context.get<ProcessManager>(),
    );
  }

  final FutureOr<void> Function()? _setup;
  final Map<Type, Generator>? _overrides;

  /// Runs `test` within a tool zone.
  ///
  /// `overrides` may be used to provide new context values for the single test
  /// case or override any context values from the setup.
  Future<T?> run<T>(FutureOr<T> Function() test, {Map<Type, Generator>? overrides}) {
    final testOverrides = <Type, Generator>{
      ..._testbedDefaults,
      // Add the initial setUp overrides
      ...?_overrides,
      // Add the test-specific overrides
      ...?overrides,
    };
    if (testOverrides.containsKey(ProcessUtils)) {
      throw StateError('Do not inject ProcessUtils for testing, use ProcessManager instead.');
    }
    // Track pending timers to verify that they were correctly cleaned up.
    final timers = <Timer, StackTrace>{};

    return runZoned(
      () => HttpOverrides.runZoned(() {
        return runInContext<T?>(() {
          return context.run<T?>(
            name: 'testbed-zone',
            zoneSpecification: ZoneSpecification(
              createTimer:
                  (
                    Zone self,
                    ZoneDelegate parent,
                    Zone zone,
                    Duration duration,
                    void Function() timer,
                  ) {
                    final Timer result = parent.createTimer(zone, duration, timer);
                    timers[result] = StackTrace.current;
                    return result;
                  },
              createPeriodicTimer:
                  (
                    Zone self,
                    ZoneDelegate parent,
                    Zone zone,
                    Duration period,
                    void Function(Timer) timer,
                  ) {
                    final Timer result = parent.createPeriodicTimer(zone, period, timer);
                    timers[result] = StackTrace.current;
                    return result;
                  },
            ),
            body: () async {
              if (_setup != null) {
                await _setup.call();
              }
              await test();
              for (final MapEntry(:Timer key, :StackTrace value) in timers.entries) {
                if (key.isActive) {
                  throw StateError('A Timer was active at the end of a test: $value');
                }
              }
              return null;
            },
          );
        }, overrides: testOverrides);
      }, createHttpClient: (SecurityContext? c) => FakeHttpClient.any()),
      zoneValues: <Object?, Object?>{_inTestBedKey: true},
    );
  }
}
