// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart' show ListEquality, MapEquality;

import 'package:flutter_devicelab/framework/adb.dart';

import 'common.dart';

void main() {
  group('device', () {
    Device device;

    setUp(() {
      FakeDevice.resetLog();
      device = null;
      device = FakeDevice();
    });

    tearDown(() {
    });

    group('isAwake/isAsleep', () {
      test('reads Awake', () async {
        FakeDevice.pretendAwake();
        expect(await device.isAwake(), isTrue);
        expect(await device.isAsleep(), isFalse);
      });

      test('reads Asleep', () async {
        FakeDevice.pretendAsleep();
        expect(await device.isAwake(), isFalse);
        expect(await device.isAsleep(), isTrue);
      });
    });

    group('togglePower', () {
      test('sends power event', () async {
        await device.togglePower();
        expectLog(<CommandArgs>[
          cmd(command: 'input', arguments: <String>['keyevent', '26']),
        ]);
      });
    });

    group('wakeUp', () {
      test('when awake', () async {
        FakeDevice.pretendAwake();
        await device.wakeUp();
        expectLog(<CommandArgs>[
          cmd(command: 'dumpsys', arguments: <String>['power']),
        ]);
      });

      test('when asleep', () async {
        FakeDevice.pretendAsleep();
        await device.wakeUp();
        expectLog(<CommandArgs>[
          cmd(command: 'dumpsys', arguments: <String>['power']),
          cmd(command: 'input', arguments: <String>['keyevent', '26']),
        ]);
      });
    });

    group('sendToSleep', () {
      test('when asleep', () async {
        FakeDevice.pretendAsleep();
        await device.sendToSleep();
        expectLog(<CommandArgs>[
          cmd(command: 'dumpsys', arguments: <String>['power']),
        ]);
      });

      test('when awake', () async {
        FakeDevice.pretendAwake();
        await device.sendToSleep();
        expectLog(<CommandArgs>[
          cmd(command: 'dumpsys', arguments: <String>['power']),
          cmd(command: 'input', arguments: <String>['keyevent', '26']),
        ]);
      });
    });

    group('unlock', () {
      test('sends unlock event', () async {
        FakeDevice.pretendAwake();
        await device.unlock();
        expectLog(<CommandArgs>[
          cmd(command: 'dumpsys', arguments: <String>['power']),
          cmd(command: 'input', arguments: <String>['keyevent', '82']),
        ]);
      });
    });

    group('adb', () {
      test('tap', () async {
        await device.tap(100, 200);
        expectLog(<CommandArgs>[
          cmd(command: 'input', arguments: <String>['tap', '100', '200']),
        ]);
      });
    });
  });
}

void expectLog(List<CommandArgs> log) {
  expect(FakeDevice.commandLog, log);
}

CommandArgs cmd({
  String command,
  List<String> arguments,
  Map<String, String> environment,
}) {
  return CommandArgs(
    command: command,
    arguments: arguments,
    environment: environment,
  );
}

typedef ExitErrorFactory = dynamic Function();

class CommandArgs {
  CommandArgs({ this.command, this.arguments, this.environment });

  final String command;
  final List<String> arguments;
  final Map<String, String> environment;

  @override
  String toString() => 'CommandArgs(command: $command, arguments: $arguments, environment: $environment)';

  @override
  bool operator==(Object other) {
    if (other.runtimeType != CommandArgs)
      return false;

    final CommandArgs otherCmd = other;
    return otherCmd.command == command &&
      const ListEquality<String>().equals(otherCmd.arguments, arguments) &&
      const MapEquality<String, String>().equals(otherCmd.environment, environment);
  }

  @override
  int get hashCode => 17 * (17 * command.hashCode + _hashArguments) + _hashEnvironment;

  int get _hashArguments => arguments != null
    ? const ListEquality<String>().hash(arguments)
    : null.hashCode;

  int get _hashEnvironment => environment != null
    ? const MapEquality<String, String>().hash(environment)
    : null.hashCode;
}

class FakeDevice extends AndroidDevice {
  FakeDevice({String deviceId}) : super(deviceId: deviceId);

  static String output = '';
  static ExitErrorFactory exitErrorFactory = () => null;

  static List<CommandArgs> commandLog = <CommandArgs>[];

  static void resetLog() {
    commandLog.clear();
  }

  static void pretendAwake() {
    output = '''
      mWakefulness=Awake
    ''';
  }

  static void pretendAsleep() {
    output = '''
      mWakefulness=Asleep
    ''';
  }

  @override
  Future<String> shellEval(String command, List<String> arguments, { Map<String, String> environment }) async {
    commandLog.add(CommandArgs(
      command: command,
      arguments: arguments,
      environment: environment,
    ));
    return output;
  }

  @override
  Future<void> shellExec(String command, List<String> arguments, { Map<String, String> environment }) async {
    commandLog.add(CommandArgs(
      command: command,
      arguments: arguments,
      environment: environment,
    ));
    final dynamic exitError = exitErrorFactory();
    if (exitError != null)
      throw exitError;
  }
}
