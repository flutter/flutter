// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/usage.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
void main() {

  group('Flutter Command', () {

    MockCache cache;
    MockClock clock;
    MockUsage usage;
    List<int> mockTimes;

    setUp(() {
      cache = MockCache();
      clock = MockClock();
      usage = MockUsage();
      when(usage.isFirstRun).thenReturn(false);
      when(clock.now()).thenAnswer(
        (Invocation _) => DateTime.fromMillisecondsSinceEpoch(mockTimes.removeAt(0))
      );
    });

    testUsingContext('honors shouldUpdateCache false', () async {
      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(shouldUpdateCache: false);
      await flutterCommand.run();
      verifyZeroInteractions(cache);
    },
    overrides: <Type, Generator>{
      Cache: () => cache,
    });

    testUsingContext('honors shouldUpdateCache true', () async {
      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(shouldUpdateCache: true);
      await flutterCommand.run();
      verify(cache.updateAll()).called(1);
    },
    overrides: <Type, Generator>{
      Cache: () => cache,
    });

    testUsingContext('report execution timing by default', () async {
      // Crash if called a third time which is unexpected.
      mockTimes = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand();
      await flutterCommand.run();
      verify(clock.now()).called(2);

      expect(
        verify(usage.sendTiming(
                captureAny, captureAny, captureAny,
                label: captureAnyNamed('label'))).captured,
        <dynamic>['flutter', 'dummy', const Duration(milliseconds: 1000), null]
      );
    },
    overrides: <Type, Generator>{
      SystemClock: () => clock,
      Usage: () => usage,
    });

    testUsingContext('no timing report without usagePath', () async {
      // Crash if called a third time which is unexpected.
      mockTimes = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand =
          DummyFlutterCommand(noUsagePath: true);
      await flutterCommand.run();
      verify(clock.now()).called(2);
      verifyNever(usage.sendTiming(
                   any, any, any,
                   label: anyNamed('label')));
    },
    overrides: <Type, Generator>{
      SystemClock: () => clock,
      Usage: () => usage,
    });

    testUsingContext('report additional FlutterCommandResult data', () async {
      // Crash if called a third time which is unexpected.
      mockTimes = <int>[1000, 2000];

      final FlutterCommandResult commandResult = FlutterCommandResult(
        ExitStatus.success,
        // nulls should be cleaned up.
        timingLabelParts: <String> ['blah1', 'blah2', null, 'blah3'],
        endTimeOverride: DateTime.fromMillisecondsSinceEpoch(1500)
      );

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async => commandResult
      );
      await flutterCommand.run();
      verify(clock.now()).called(2);
      expect(
        verify(usage.sendTiming(
                captureAny, captureAny, captureAny,
                label: captureAnyNamed('label'))).captured,
        <dynamic>[
          'flutter',
          'dummy',
          const Duration(milliseconds: 500), // FlutterCommandResult's end time used instead.
          'success-blah1-blah2-blah3',
        ],
      );
    },
    overrides: <Type, Generator>{
      SystemClock: () => clock,
      Usage: () => usage,
    });

    testUsingContext('report failed execution timing too', () async {
      // Crash if called a third time which is unexpected.
      mockTimes = <int>[1000, 2000];

      final DummyFlutterCommand flutterCommand = DummyFlutterCommand(
        commandFunction: () async {
          throwToolExit('fail');
          return null; // unreachable
        },
      );

      try {
        await flutterCommand.run();
        fail('Mock should make this fail');
      } on ToolExit {
        // Should have still checked time twice.
        verify(clock.now()).called(2);

        expect(
          verify(usage.sendTiming(
                  captureAny, captureAny, captureAny,
                  label: captureAnyNamed('label'))).captured,
          <dynamic>[
            'flutter',
            'dummy',
            const Duration(milliseconds: 1000),
            'fail'
          ]
        );
      }
    },
    overrides: <Type, Generator>{
      SystemClock: () => clock,
      Usage: () => usage,
    });

  });

}

typedef CommandFunction = Future<FlutterCommandResult> Function();

class DummyFlutterCommand extends FlutterCommand {

  DummyFlutterCommand({
    this.shouldUpdateCache  = false,
    this.noUsagePath  = false,
    this.commandFunction,
  });

  final bool noUsagePath;
  final CommandFunction commandFunction;

  @override
  final bool shouldUpdateCache;

  @override
  String get description => 'does nothing';

  @override
  Future<String> get usagePath => noUsagePath ? null : super.usagePath;

  @override
  String get name => 'dummy';

  @override
  Future<FlutterCommandResult> runCommand() async {
    return commandFunction == null ? null : await commandFunction();
  }
}

class MockCache extends Mock implements Cache {}

class MockUsage extends Mock implements Usage {}
