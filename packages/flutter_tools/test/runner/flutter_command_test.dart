// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/usage.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import 'utils.dart';

void main() {
  group('Flutter Command', () {
    MockitoCache cache;
    MockitoUsage usage;
    MockClock clock;
    List<int> mockTimes;

    setUp(() {
      cache = MockitoCache();
      usage = MockitoUsage();
      clock = MockClock();
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
      verify(cache.updateAll(any)).called(1);
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
        <dynamic>['flutter', 'dummy', const Duration(milliseconds: 1000), null],
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
        endTimeOverride: DateTime.fromMillisecondsSinceEpoch(1500),
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
            'fail',
          ],
        );
      }
    },
    overrides: <Type, Generator>{
      SystemClock: () => clock,
      Usage: () => usage,
    });
  });

  group('Development artifacts', () {
    final MockDeviceManager mockDeviceManager = MockDeviceManager();
     testUsingContext('should only request artifacts corresponding to connected devices', () async {
      when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
        return Stream<Device>.fromIterable(<Device>[
          MockDevice(TargetPlatform.android_arm),
        ]);
      });

      expect(await FakeDeviceBasedDevelopmentArtifacts().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.android,
      }));

      when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
        return Stream<Device>.fromIterable(<Device>[
          MockDevice(TargetPlatform.ios),
        ]);
      });

      expect(await FakeDeviceBasedDevelopmentArtifacts().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.iOS,
      }));

      when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
        return Stream<Device>.fromIterable(<Device>[
          MockDevice(TargetPlatform.ios),
          MockDevice(TargetPlatform.android_arm),
        ]);
      });

      expect(await FakeDeviceBasedDevelopmentArtifacts().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.iOS,
        DevelopmentArtifact.android,
      }));

      when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
        return Stream<Device>.fromIterable(<Device>[
          MockDevice(TargetPlatform.web),
        ]);
      });

      expect(await FakeDeviceBasedDevelopmentArtifacts().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.web,
      }));
    }, overrides: <Type, Generator>{
      DeviceManager: () => mockDeviceManager,
    });
  });
}

class MockDeviceManager extends Mock implements DeviceManager {}
class MockDevice extends Mock implements Device {
  MockDevice(this._targetPlatform);

  final TargetPlatform _targetPlatform;

  @override
  Future<TargetPlatform> get targetPlatform async => _targetPlatform;
}

class FakeDeviceBasedDevelopmentArtifacts extends FlutterCommand with DeviceBasedDevelopmentArtifacts {
  @override
  String get description => null;

  @override
  String get name => null;

  @override
  Future<FlutterCommandResult> runCommand() {
    return null;
  }
}
