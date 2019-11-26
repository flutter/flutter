// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/runner.dart' as runner;
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/reporting/github_template.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('runner', () {
    MockGitHubTemplateCreator mockGitHubTemplateCreator;
    setUp(() {
      mockGitHubTemplateCreator = MockGitHubTemplateCreator();
      runner.crashFileSystem = MemoryFileSystem();
      // Instead of exiting with dart:io exit(), this causes an exception to
      // be thrown, which we catch with the onError callback in the zone below.
      io.setExitFunctionForTests((int _) { throw 'test exit';});
      Cache.disableLocking();
    });

    tearDown(() {
      runner.crashFileSystem = const LocalFileSystem();
      io.restoreExitFunction();
      Cache.enableLocking();
    });

    testUsingContext('error handling crash report', () async {
      final Completer<void> completer = Completer<void>();
      // runner.run() asynchronously calls the exit function set above, so we
      // catch it in a zone.
      unawaited(runZoned<Future<void>>(
        () {
          unawaited(runner.run(
            <String>['test'],
            <FlutterCommand>[
              CrashingFlutterCommand(),
            ],
            // This flutterVersion disables crash reporting.
            flutterVersion: '[user-branch]/',
            reportCrashes: true,
          ));
          return null;
        },
        onError: (Object error) {
          expect(error, 'test exit');
          completer.complete();
        },
      ));
      await completer.future;

      // This is the main check of this test.
      //
      // We are checking that, even though crash reporting failed with an
      // exception on the first attempt, the second attempt tries to report the
      // *original* crash, and not the crash from the first crash report
      // attempt.
      final CrashingUsage crashingUsage = flutterUsage as CrashingUsage;
      expect(crashingUsage.sentException, 'an exception % --');
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(environment: <String, String>{
        'FLUTTER_ANALYTICS_LOG_FILE': 'test',
        'FLUTTER_ROOT': '/',
      }),
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
      Usage: () => CrashingUsage(),
    });

    testUsingContext('GitHub issue template', () async {
      const String similarURL = 'https://example.com/1';
      when(mockGitHubTemplateCreator.toolCrashSimilarIssuesGitHubURL(any))
        .thenAnswer((_) async => similarURL);
      const String templateURL = 'https://example.com/2';
      when(mockGitHubTemplateCreator.toolCrashIssueTemplateGitHubURL(any, any, any, any, any))
        .thenAnswer((_) async => templateURL);
      final Completer<void> completer = Completer<void>();
      // runner.run() asynchronously calls the exit function set above, so we
      // catch it in a zone.
      unawaited(runZoned<Future<void>>(
        () {
        unawaited(runner.run(
          <String>['test'],
          <FlutterCommand>[
            CrashingFlutterCommand(),
          ],
          // This flutterVersion disables crash reporting.
          flutterVersion: '[user-branch]/',
          reportCrashes: true,
        ));
        return null;
        },
        onError: (Object error) {
          expect(error, 'test exit');
          completer.complete();
        },
      ));
      await completer.future;

      final String errorText = testLogger.errorText;
      expect(errorText, contains('A crash report has been written to /flutter_01.log.'));
      expect(errorText, contains('Oops; flutter has exited unexpectedly: "an exception % --".\n'));

      final String statusText = testLogger.statusText;
      expect(statusText, contains(similarURL));
      expect(statusText, contains('https://flutter.dev/docs/resources/bug-reports'));
      expect(statusText, contains(templateURL));

    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(
        environment: <String, String>{
          'FLUTTER_ANALYTICS_LOG_FILE': 'test',
          'FLUTTER_ROOT': '/',
        },
        operatingSystem: 'linux'
      ),
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
      GitHubTemplateCreator: () => mockGitHubTemplateCreator,
    });
  });
}

class CrashingFlutterCommand extends FlutterCommand {
  @override
  String get description => null;

  @override
  String get name => 'test';

  @override
  Future<FlutterCommandResult> runCommand() async {
    throw 'an exception % --'; // Test URL encoding.
  }
}

class CrashingUsage implements Usage {
  CrashingUsage() : _impl = Usage(versionOverride: '[user-branch]');

  final Usage _impl;

  dynamic get sentException => _sentException;
  dynamic _sentException;

  bool _firstAttempt = true;

  // Crash while crashing.
  @override
  void sendException(dynamic exception) {
    if (_firstAttempt) {
      _firstAttempt = false;
      throw 'sendException';
    }
    _sentException = exception;
  }

  @override
  bool get isFirstRun => _impl.isFirstRun;

  @override
  bool get suppressAnalytics => _impl.suppressAnalytics;

  @override
  set suppressAnalytics(bool value) {
    _impl.suppressAnalytics = value;
  }

  @override
  bool get enabled => _impl.enabled;

  @override
  set enabled(bool value) {
    _impl.enabled = value;
  }

  @override
  String get clientId => _impl.clientId;

  @override
  void sendCommand(String command, {Map<String, String> parameters}) =>
      _impl.sendCommand(command, parameters: parameters);

  @override
  void sendEvent(
    String category,
    String parameter, {
    String label,
    int value,
    Map<String, String> parameters,
  }) => _impl.sendEvent(
    category,
    parameter,
    label: label,
    value: value,
    parameters: parameters,
  );

  @override
  void sendTiming(
    String category,
    String variableName,
    Duration duration, {
    String label,
  }) => _impl.sendTiming(category, variableName, duration, label: label);

  @override
  Stream<Map<String, dynamic>> get onSend => _impl.onSend;

  @override
  Future<void> ensureAnalyticsSent() => _impl.ensureAnalyticsSent();

  @override
  void printWelcome() => _impl.printWelcome();
}
