// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';

void main() {
  // Uses plain `test` + the production `runInContext` on purpose:
  // `testUsingContext` overrides Analytics, FlutterVersion,
  // XcodeProjectInterpreter, etc., which is what hid the startup cycle.
  // Only I/O is faked, so Cache, FlutterVersion, Xcode,
  // XcodeProjectInterpreter, CocoaPods, ... use their real fallbacks.
  test('runInContext resolves production globals without a dependency cycle', () async {
    await runInContext<void>(
      () {
        expect(globals.analytics, isNotNull);
        expect(globals.flutterVersion, isNotNull);
        expect(globals.cache, isNotNull);
        expect(globals.artifacts, isNotNull);
        expect(globals.projectFactory, isNotNull);
        expect(globals.xcodeProjectInterpreter, isNotNull);
        expect(globals.xcode, isNotNull);
        expect(globals.cocoaPods, isNotNull);
        expect(globals.xcdevice, isNotNull);
        expect(globals.iosSimulatorUtils, isNotNull);
      },
      overrides: <Type, Generator>{
        // The real Analytics fallback only reads FlutterVersion.dartSdkVersion
        // (-> Cache) for non-bot users, then constructs an Analytics that
        // writes to the real $HOME. Make the same read, but stay hermetic.
        Analytics: () {
          expect(globals.flutterVersion.dartSdkVersion, isA<String>());
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
}
