// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/commands/daemon.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:test/test.dart';

import 'src/context.dart';
import 'src/mocks.dart';

void main() {
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
      appContext[Doctor] = new Doctor();
      if (Platform.isMacOS)
        appContext[XCode] = new XCode();
      appContext[DeviceManager] = new MockDeviceManager();
    });

    tearDown(() {
      if (daemon != null)
        return daemon.shutdown();
      notifyingLogger.dispose();
    });

    _testUsingContext('daemon.version', () async {
      StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
        commands.stream,
        (Map<String, dynamic> result) => responses.add(result),
        notifyingLogger: notifyingLogger
      );
      commands.add(<String, dynamic>{'id': 0, 'method': 'daemon.version'});
      Map<String, dynamic> response = await responses.stream.where(_notEvent).first;
      expect(response['id'], 0);
      expect(response['result'], isNotEmpty);
      expect(response['result'] is String, true);
      responses.close();
      commands.close();
    });

    _testUsingContext('daemon.logMessage', () {
      return appContext.runInZone(() async {
        StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
        StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
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
        responses.close();
        commands.close();
      });
    });

    _testUsingContext('daemon.shutdown', () async {
      StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
        commands.stream,
        (Map<String, dynamic> result) => responses.add(result),
        notifyingLogger: notifyingLogger
      );
      commands.add(<String, dynamic>{'id': 0, 'method': 'daemon.shutdown'});
      return daemon.onExit.then((int code) {
        responses.close();
        commands.close();
        expect(code, 0);
      });
    });

    _testUsingContext('daemon.start', () async {
      DaemonCommand command = new DaemonCommand();
      applyMocksToCommand(command);

      StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
        commands.stream,
        (Map<String, dynamic> result) => responses.add(result),
        daemonCommand: command,
        notifyingLogger: notifyingLogger
      );

      commands.add(<String, dynamic>{ 'id': 0, 'method': 'app.start' });
      Map<String, dynamic> response = await responses.stream.where(_notEvent).first;
      expect(response['id'], 0);
      expect(response['error'], contains('deviceId is required'));
      responses.close();
      commands.close();
    });

    _testUsingContext('daemon.restart', () async {
      DaemonCommand command = new DaemonCommand();
      applyMocksToCommand(command);

      StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
        commands.stream,
        (Map<String, dynamic> result) => responses.add(result),
        daemonCommand: command,
        notifyingLogger: notifyingLogger
      );

      commands.add(<String, dynamic>{ 'id': 0, 'method': 'app.restart' });
      Map<String, dynamic> response = await responses.stream.where(_notEvent).first;
      expect(response['id'], 0);
      expect(response['error'], contains('appId is required'));
      responses.close();
      commands.close();
    });

    _testUsingContext('daemon.stop', () async {
      DaemonCommand command = new DaemonCommand();
      applyMocksToCommand(command);

      StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
        commands.stream,
        (Map<String, dynamic> result) => responses.add(result),
        daemonCommand: command,
        notifyingLogger: notifyingLogger
      );

      commands.add(<String, dynamic>{ 'id': 0, 'method': 'app.stop' });
      Map<String, dynamic> response = await responses.stream.where(_notEvent).first;
      expect(response['id'], 0);
      expect(response['error'], contains('appId is required'));
      responses.close();
      commands.close();
    });

    _testUsingContext('device.getDevices', () async {
      StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
        commands.stream,
        (Map<String, dynamic> result) => responses.add(result),
        notifyingLogger: notifyingLogger
      );
      commands.add(<String, dynamic>{'id': 0, 'method': 'device.getDevices'});
      Map<String, dynamic> response = await responses.stream.where(_notEvent).first;
      expect(response['id'], 0);
      expect(response['result'], isList);
      responses.close();
      commands.close();
    });
  });
}

bool _notEvent(Map<String, dynamic> map) => map['event'] == null;
