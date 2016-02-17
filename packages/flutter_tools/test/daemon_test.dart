// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/commands/daemon.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'src/mocks.dart';

main() => defineTests();

defineTests() {
  Daemon daemon;
  AppContext appContext;
  NotifyingLogger notifyingLogger;

  void _testUsingContext(String description, dynamic testMethod()) {
    test(description, () {
      return appContext.runInZone(testMethod);
    });
  }

  group('daemon', () {
    setUp(() {
      appContext = new AppContext();
      notifyingLogger = new NotifyingLogger();
      appContext[Logger] = notifyingLogger;
    });

    tearDown(() {
      if (daemon != null)
        return daemon.shutdown();
    });

    _testUsingContext('daemon.version', () async {
      StreamController<Map<String, dynamic>> commands = new StreamController();
      StreamController<Map<String, dynamic>> responses = new StreamController();
      daemon = new Daemon(
        commands.stream,
        (Map<String, dynamic> result) => responses.add(result),
        notifyingLogger: notifyingLogger
      );
      commands.add({'id': 0, 'method': 'daemon.version'});
      Map response = await responses.stream.where(_notEvent).first;
      expect(response['id'], 0);
      expect(response['result'], isNotEmpty);
      expect(response['result'] is String, true);
    });

    _testUsingContext('daemon.logMessage', () {
      return appContext.runInZone(() async {
        StreamController<Map<String, dynamic>> commands = new StreamController();
        StreamController<Map<String, dynamic>> responses = new StreamController();
        daemon = new Daemon(
          commands.stream,
          (Map<String, dynamic> result) => responses.add(result),
          notifyingLogger: notifyingLogger
        );
        printError('daemon.logMessage test');
        Map<String, dynamic> response = await responses.stream.where((Map<String, dynamic> map) {
          return map['event'] == 'daemon.logMessage' && map['params']['level'] == 'error';
        }).first;
        expect(response['id'], isNull);
        expect(response['event'], 'daemon.logMessage');
        Map<String, String> logMessage = response['params'];
        expect(logMessage['level'], 'error');
        expect(logMessage['message'], 'daemon.logMessage test');
      });
    });

    _testUsingContext('daemon.shutdown', () async {
      StreamController<Map<String, dynamic>> commands = new StreamController();
      StreamController<Map<String, dynamic>> responses = new StreamController();
      daemon = new Daemon(
        commands.stream,
        (Map<String, dynamic> result) => responses.add(result),
        notifyingLogger: notifyingLogger
      );
      commands.add({'id': 0, 'method': 'daemon.shutdown'});
      return daemon.onExit.then((int code) {
        expect(code, 0);
      });
    });

    _testUsingContext('daemon.stopAll', () async {
      DaemonCommand command = new DaemonCommand();
      applyMocksToCommand(command);

      StreamController<Map<String, dynamic>> commands = new StreamController();
      StreamController<Map<String, dynamic>> responses = new StreamController();
      daemon = new Daemon(
        commands.stream,
        (Map<String, dynamic> result) => responses.add(result),
        daemonCommand: command,
        notifyingLogger: notifyingLogger
      );

      MockDeviceStore mockDevices = command.devices;

      when(mockDevices.android.isConnected()).thenReturn(true);
      when(mockDevices.android.stopApp(any)).thenReturn(true);

      when(mockDevices.iOS.isConnected()).thenReturn(false);
      when(mockDevices.iOS.stopApp(any)).thenReturn(false);

      when(mockDevices.iOSSimulator.isConnected()).thenReturn(false);
      when(mockDevices.iOSSimulator.stopApp(any)).thenReturn(false);

      commands.add({'id': 0, 'method': 'app.stopAll'});
      Map response = await responses.stream.where(_notEvent).first;
      expect(response['id'], 0);
      expect(response['result'], true);
    });

    _testUsingContext('device.getDevices', () async {
      StreamController<Map<String, dynamic>> commands = new StreamController();
      StreamController<Map<String, dynamic>> responses = new StreamController();
      daemon = new Daemon(
        commands.stream,
        (Map<String, dynamic> result) => responses.add(result),
        notifyingLogger: notifyingLogger
      );
      commands.add({'id': 0, 'method': 'device.getDevices'});
      Map response = await responses.stream.where(_notEvent).first;
      expect(response['id'], 0);
      expect(response['result'], isList);
    });
  });
}

bool _notEvent(Map<String, dynamic> map) => map['event'] == null;
