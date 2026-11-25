// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/macos/cocoapods.dart';
import 'package:flutter_tools/src/macos/xcdevice.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/runner/local_engine.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/context_runner.dart';
import '../src/fakes.dart';

void main() {
  // Uses plain `test` + `runInContext` on purpose:
  // `testUsingContext` overrides Analytics, FlutterVersion,
  // XcodeProjectInterpreter, etc., which hid the startup cycle.
  // Only I/O is faked, so Cache, FlutterVersion, LocalEngineLocator, Xcode,
  // XcodeProjectInterpreter, CocoaPods, ... use their real fallbacks.
  test('runInContext resolves fallbacks without a dependency cycle', () async {
    await runInContext<void>(
      () {
        expect(context.get<Analytics>(), isNotNull);
        expect(context.get<FlutterVersion>(), isNotNull);
        expect(context.get<Cache>(), isNotNull);
        expect(context.get<Artifacts>(), isNotNull);
        expect(context.get<LocalEngineLocator>(), isNotNull);
        expect(const DelegatingToolContext().projectFactory, isNotNull);
        expect(context.get<XcodeProjectInterpreter>(), isNotNull);
        expect(context.get<Xcode>(), isNotNull);
        expect(context.get<CocoaPods>(), isNotNull);
        expect(context.get<XCDevice>(), isNotNull);
        expect(context.get<IOSSimulatorUtils>(), isNotNull);
      },
      overrides: <Type, Generator>{
        // The real Analytics fallback only reads FlutterVersion.dartSdkVersion
        // (-> Cache) for non-bot users, then constructs an Analytics that
        // writes to the real $HOME. Make the same read, but stay hermetic.
        Analytics: () {
          expect(context.get<FlutterVersion>()!.dartSdkVersion, isA<String>());
          return const NoOpAnalytics();
        },
        BotDetector: () => const FakeBotDetector(false),
        Config: () => Config.test(),
        FileSystem: () => MemoryFileSystem.test(),
        Logger: () => BufferLogger.test(),
        Platform: () => FakePlatform(
          environment: <String, String>{'FLUTTER_ROOT': '/flutter', 'HOME': '/home'},
        ),
        ProcessManager: () => FakeProcessManager.any(),
        Stdio: () => FakeStdio(),
        // Production override from executable.dart.
        TemplateRenderer: () => const MustacheTemplateRenderer(),
      },
    );
  });

  test(
    'runInContext resolves real Analytics, FlutterVersion, Cache, and LocalEngineLocator fallbacks',
    () async {
      await runInContext<void>(
        () {
          expect(context.get<Analytics>(), isA<NoOpAnalytics>());
          expect(context.get<FlutterVersion>(), isNotNull);
          expect(context.get<Cache>(), isNotNull);
          expect(context.get<LocalEngineLocator>(), isNotNull);
        },
        overrides: <Type, Generator>{
          BotDetector: () => const FakeBotDetector(true),
          Config: () => Config.test(),
          FileSystem: () => MemoryFileSystem.test(),
          Logger: () => BufferLogger.test(),
          Platform: () => FakePlatform(
            environment: <String, String>{'FLUTTER_ROOT': '/flutter', 'HOME': '/home'},
          ),
          ProcessManager: () => FakeProcessManager.any(),
          Stdio: () => FakeStdio(),
          TemplateRenderer: () => const MustacheTemplateRenderer(),
        },
      );
    },
  );
}
