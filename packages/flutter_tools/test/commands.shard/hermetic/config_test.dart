// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/config.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  MockAndroidStudio mockAndroidStudio;
  MockAndroidSdk mockAndroidSdk;
  MockFlutterVersion mockFlutterVersion;
  MockUsage mockUsage;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    mockAndroidStudio = MockAndroidStudio();
    mockAndroidSdk = MockAndroidSdk();
    mockFlutterVersion = MockFlutterVersion();
    mockUsage = MockUsage();

    when(mockUsage.isFirstRun).thenReturn(false);
  });

  void verifyNoAnalytics() {
    verifyNever(mockUsage.sendCommand(
      any,
      parameters: anyNamed('parameters'),
    ));
    verifyNever(mockUsage.sendEvent(
      any,
      any,
      label: anyNamed('label'),
      value: anyNamed('value'),
      parameters: anyNamed('parameters'),
    ));
    verifyNever(mockUsage.sendTiming(
      any,
      any,
      any,
      label: anyNamed('label'),
    ));
  }

  group('config', () {
    testUsingContext('machine flag', () async {
      final ConfigCommand command = ConfigCommand();
      await command.handleMachine();

      expect(testLogger.statusText, isNotEmpty);
      final dynamic jsonObject = json.decode(testLogger.statusText);
      expect(jsonObject, isMap);

      expect(jsonObject.containsKey('android-studio-dir'), true);
      expect(jsonObject['android-studio-dir'], isNotNull);

      expect(jsonObject.containsKey('android-sdk'), true);
      expect(jsonObject['android-sdk'], isNotNull);
      verifyNoAnalytics();
    }, overrides: <Type, Generator>{
      AndroidStudio: () => mockAndroidStudio,
      AndroidSdk: () => mockAndroidSdk,
      Usage: () => mockUsage,
    });

    testUsingContext('Can set build-dir', () async {
      final ConfigCommand configCommand = ConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      await commandRunner.run(<String>[
        'config',
        '--build-dir=foo',
      ]);

      expect(getBuildDirectory(), 'foo');
      verifyNoAnalytics();
    }, overrides: <Type, Generator>{
      Usage: () => mockUsage,
    });

    testUsingContext('throws error on absolute path to build-dir', () async {
      final ConfigCommand configCommand = ConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      expect(() => commandRunner.run(<String>[
        'config',
        '--build-dir=/foo',
      ]), throwsToolExit());
      verifyNoAnalytics();
    }, overrides: <Type, Generator>{
      Usage: () => mockUsage,
    });

    testUsingContext('allows setting and removing feature flags', () async {
      final ConfigCommand configCommand = ConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      await commandRunner.run(<String>[
        'config',
        '--enable-web',
        '--enable-linux-desktop',
        '--enable-windows-desktop',
        '--enable-macos-desktop',
      ]);

      expect(globals.config.getValue('enable-web'), true);
      expect(globals.config.getValue('enable-linux-desktop'), true);
      expect(globals.config.getValue('enable-windows-desktop'), true);
      expect(globals.config.getValue('enable-macos-desktop'), true);

      await commandRunner.run(<String>[
        'config', '--clear-features',
      ]);

      expect(globals.config.getValue('enable-web'), null);
      expect(globals.config.getValue('enable-linux-desktop'), null);
      expect(globals.config.getValue('enable-windows-desktop'), null);
      expect(globals.config.getValue('enable-macos-desktop'), null);

      await commandRunner.run(<String>[
        'config',
        '--no-enable-web',
        '--no-enable-linux-desktop',
        '--no-enable-windows-desktop',
        '--no-enable-macos-desktop',
      ]);

      expect(globals.config.getValue('enable-web'), false);
      expect(globals.config.getValue('enable-linux-desktop'), false);
      expect(globals.config.getValue('enable-windows-desktop'), false);
      expect(globals.config.getValue('enable-macos-desktop'), false);
      verifyNoAnalytics();
    }, overrides: <Type, Generator>{
      AndroidStudio: () => mockAndroidStudio,
      AndroidSdk: () => mockAndroidSdk,
      Usage: () => mockUsage,
    });

    testUsingContext('warns the user to reload IDE', () async {
      final ConfigCommand configCommand = ConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      await commandRunner.run(<String>[
        'config',
        '--enable-web'
      ]);

      expect(
        testLogger.statusText,
        containsIgnoringWhitespace('You may need to restart any open editors'),
      );
    }, overrides: <Type, Generator>{
      Usage: () => mockUsage,
    });

    testUsingContext('displays which config settings are available on stable', () async {
      when(mockFlutterVersion.channel).thenReturn('stable');
      final ConfigCommand configCommand = ConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      await commandRunner.run(<String>[
        'config',
        '--enable-web',
        '--enable-linux-desktop',
        '--enable-windows-desktop',
        '--enable-macos-desktop',
      ]);

      await commandRunner.run(<String>[
        'config',
      ]);

      expect(
        testLogger.statusText,
        containsIgnoringWhitespace('enable-web: true (Unavailable)'),
      );
      expect(
        testLogger.statusText,
        containsIgnoringWhitespace('enable-linux-desktop: true (Unavailable)'),
      );
      expect(
        testLogger.statusText,
        containsIgnoringWhitespace('enable-windows-desktop: true (Unavailable)'),
      );
      expect(
        testLogger.statusText,
        containsIgnoringWhitespace('enable-macos-desktop: true (Unavailable)'),
      );
      verifyNoAnalytics();
    }, overrides: <Type, Generator>{
      AndroidStudio: () => mockAndroidStudio,
      AndroidSdk: () => mockAndroidSdk,
      FlutterVersion: () => mockFlutterVersion,
      Usage: () => mockUsage,
    });

    testUsingContext('no-analytics flag flips usage flag and sends event', () async {
      final ConfigCommand configCommand = ConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      when(mockUsage.sendEvent(
        captureAny,
        captureAny,
        label: captureAnyNamed('label'),
        value: anyNamed('value'),
        parameters: anyNamed('parameters'),
      )).thenAnswer((Invocation invocation) async {
        expect(mockUsage.enabled, true);
        expect(invocation.positionalArguments, <String>['analytics', 'enabled']);
        expect(invocation.namedArguments[#label], 'false');
      });

      await commandRunner.run(<String>[
        'config',
        '--no-analytics',
      ]);

      expect(mockUsage.enabled, false);

      // Verify that we flushed the analytics queue.
      verify(mockUsage.ensureAnalyticsSent());

      // Verify that we only send the analytics disable event, and no other
      // info.
      verifyNever(mockUsage.sendCommand(
        any,
        parameters: anyNamed('parameters'),
      ));
      verifyNever(mockUsage.sendTiming(
        any,
        any,
        any,
        label: anyNamed('label'),
      ));
    }, overrides: <Type, Generator>{
      Usage: () => mockUsage,
    });

    testUsingContext('analytics flag flips usage flag and sends event', () async {
      final ConfigCommand configCommand = ConfigCommand();
      final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

      await commandRunner.run(<String>[
        'config',
        '--analytics',
      ]);

      expect(mockUsage.enabled, true);

      // Verify that we only send the analytics disable event, and no other
      // info.
      verifyNever(mockUsage.sendCommand(
        any,
        parameters: anyNamed('parameters'),
      ));
      verifyNever(mockUsage.sendTiming(
        any,
        any,
        any,
        label: anyNamed('label'),
      ));

      expect(verify(mockUsage.sendEvent(
        captureAny,
        captureAny,
        label: captureAnyNamed('label'),
        value: anyNamed('value'),
        parameters: anyNamed('parameters'),
      )).captured,
        <dynamic>['analytics', 'enabled', 'true'],
      );
    }, overrides: <Type, Generator>{
      Usage: () => mockUsage,
    });
  });
}

class MockAndroidStudio extends Mock implements AndroidStudio, Comparable<AndroidStudio> {
  @override
  String get directory => 'path/to/android/stdio';
}

class MockAndroidSdk extends Mock implements AndroidSdk {
  @override
  String get directory => 'path/to/android/sdk';
}

class MockFlutterVersion extends Mock implements FlutterVersion {}

class MockUsage extends Mock implements Usage {
  @override
  bool enabled = true;
}
