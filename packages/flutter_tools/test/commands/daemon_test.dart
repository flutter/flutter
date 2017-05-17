// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/commands/daemon.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:test/test.dart';

import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  Daemon daemon;
  AppContext appContext;
  NotifyingLogger notifyingLogger;

  group('daemon', () {
    setUp(() {
      appContext = new AppContext();
      notifyingLogger = new NotifyingLogger();
      appContext.setVariable(Logger, notifyingLogger);
    });

    tearDown(() {
      if (daemon != null)
        return daemon.shutdown();
      notifyingLogger.dispose();
    });

    testUsingContext('daemon.version command should succeed', () async {
      final StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      final StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
        commands.stream,
        responses.add,
        notifyingLogger: notifyingLogger
      );
      commands.add(<String, dynamic>{'id': 0, 'method': 'daemon.version'});
      final Map<String, dynamic> response = await responses.stream.firstWhere(_notEvent);
      expect(response['id'], 0);
      expect(response['result'], isNotEmpty);
      expect(response['result'] is String, true);
      responses.close();
      commands.close();
    });

    testUsingContext('printError should send daemon.logMessage event', () {
      return appContext.runInZone(() async {
        final StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
        final StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
        daemon = new Daemon(
          commands.stream,
          responses.add,
          notifyingLogger: notifyingLogger
        );
        printError('daemon.logMessage test');
        final Map<String, dynamic> response = await responses.stream.firstWhere((Map<String, dynamic> map) {
          return map['event'] == 'daemon.logMessage' && map['params']['level'] == 'error';
        });
        expect(response['id'], isNull);
        expect(response['event'], 'daemon.logMessage');
        final Map<String, String> logMessage = response['params'];
        expect(logMessage['level'], 'error');
        expect(logMessage['message'], 'daemon.logMessage test');
        responses.close();
        commands.close();
      });
    });

    testUsingContext('printStatus should log to stdout when logToStdout is enabled', () async {
      final StringBuffer buffer = new StringBuffer();

      await runZoned(() async {
        return appContext.runInZone(() async {
          final StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
          final StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
          daemon = new Daemon(
            commands.stream,
            responses.add,
            notifyingLogger: notifyingLogger,
            logToStdout: true
          );
          printStatus('daemon.logMessage test');
          // Service the event loop.
          await new Future<Null>.value();
        });
      }, zoneSpecification: new ZoneSpecification(print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
        buffer.writeln(line);
      }));

      expect(buffer.toString().trim(), 'daemon.logMessage test');
    });

    testUsingContext('daemon.shutdown command should stop daemon', () async {
      final StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      final StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
        commands.stream,
        responses.add,
        notifyingLogger: notifyingLogger
      );
      commands.add(<String, dynamic>{'id': 0, 'method': 'daemon.shutdown'});
      return daemon.onExit.then<Null>((int code) {
        responses.close();
        commands.close();
        expect(code, 0);
      });
    });

    testUsingContext('app.start without a deviceId should report an error', () async {
      final DaemonCommand command = new DaemonCommand();
      applyMocksToCommand(command);

      final StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      final StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
        commands.stream,
        responses.add,
        daemonCommand: command,
        notifyingLogger: notifyingLogger
      );

      commands.add(<String, dynamic>{ 'id': 0, 'method': 'app.start' });
      final Map<String, dynamic> response = await responses.stream.firstWhere(_notEvent);
      expect(response['id'], 0);
      expect(response['error'], contains('deviceId is required'));
      responses.close();
      commands.close();
    });

    testUsingContext('app.restart without an appId should report an error', () async {
      final DaemonCommand command = new DaemonCommand();
      applyMocksToCommand(command);

      final StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      final StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
        commands.stream,
        responses.add,
        daemonCommand: command,
        notifyingLogger: notifyingLogger
      );

      commands.add(<String, dynamic>{ 'id': 0, 'method': 'app.restart' });
      final Map<String, dynamic> response = await responses.stream.firstWhere(_notEvent);
      expect(response['id'], 0);
      expect(response['error'], contains('appId is required'));
      responses.close();
      commands.close();
    });

    testUsingContext('ext.flutter.debugPaint via service extension without an appId should report an error', () async {
      final DaemonCommand command = new DaemonCommand();
      applyMocksToCommand(command);

      final StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      final StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
          commands.stream,
          responses.add,
          daemonCommand: command,
          notifyingLogger: notifyingLogger
      );

      commands.add(<String, dynamic>{
        'id': 0,
        'method': 'app.callServiceExtension',
        'params': <String, String> {
          'methodName': 'ext.flutter.debugPaint'
        }
      });
      final Map<String, dynamic> response = await responses.stream.firstWhere(_notEvent);
      expect(response['id'], 0);
      expect(response['error'], contains('appId is required'));
      responses.close();
      commands.close();
    });

    testUsingContext('app.stop without appId should report an error', () async {
      final DaemonCommand command = new DaemonCommand();
      applyMocksToCommand(command);

      final StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      final StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
        commands.stream,
        responses.add,
        daemonCommand: command,
        notifyingLogger: notifyingLogger
      );

      commands.add(<String, dynamic>{ 'id': 0, 'method': 'app.stop' });
      final Map<String, dynamic> response = await responses.stream.firstWhere(_notEvent);
      expect(response['id'], 0);
      expect(response['error'], contains('appId is required'));
      responses.close();
      commands.close();
    });

    testUsingContext('daemon should send showMessage on startup if no Android devices are available', () async {
      final StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      final StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
          commands.stream,
          responses.add,
          notifyingLogger: notifyingLogger,
      );

      final Map<String, dynamic> response = await responses.stream.first;
      expect(response['event'], 'daemon.showMessage');
      expect(response['params'], isMap);
      expect(response['params'], containsPair('level', 'warning'));
      expect(response['params'], containsPair('title', 'Unable to list devices'));
      expect(response['params'], containsPair('message', contains('Unable to discover Android devices')));
    }, overrides: <Type, Generator>{
      Doctor: () => new MockDoctor(androidCanListDevices: false),
    });

    testUsingContext('device.getDevices should respond with list', () async {
      final StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      final StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
        commands.stream,
        responses.add,
        notifyingLogger: notifyingLogger
      );
      commands.add(<String, dynamic>{'id': 0, 'method': 'device.getDevices'});
      final Map<String, dynamic> response = await responses.stream.firstWhere(_notEvent);
      expect(response['id'], 0);
      expect(response['result'], isList);
      responses.close();
      commands.close();
    });

    testUsingContext('should send device.added event when device is discovered', () {
      final StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      final StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
          commands.stream,
          responses.add,
          notifyingLogger: notifyingLogger
      );

      final MockPollingDeviceDiscovery discoverer = new MockPollingDeviceDiscovery();
      daemon.deviceDomain.addDeviceDiscoverer(discoverer);
      discoverer.addDevice(new MockAndroidDevice());

      return responses.stream.first.then((Map<String, dynamic> response) {
        expect(response['event'], 'device.added');
        expect(response['params'], isMap);

        final Map<String, dynamic> params = response['params'];
        expect(params['platform'], isNotEmpty); // the mock device has a platform of 'android-arm'

        responses.close();
        commands.close();
      });
    }, overrides: <Type, Generator>{
      Doctor: () => new MockDoctor(),
    });
  });
}

bool _notEvent(Map<String, dynamic> map) => map['event'] == null;

class MockDoctor extends Doctor {
  final bool androidCanListDevices;
  final bool iosCanListDevices;

  MockDoctor({this.androidCanListDevices: true, this.iosCanListDevices: true});

  @override
  AndroidWorkflow get androidWorkflow => new MockAndroidWorkflow(androidCanListDevices);

  @override
  IOSWorkflow get iosWorkflow => new MockIosWorkflow(iosCanListDevices);
}

class MockAndroidWorkflow extends AndroidWorkflow {
  @override
  final bool canListDevices;

  MockAndroidWorkflow(this.canListDevices);
}

class MockIosWorkflow extends IOSWorkflow {
  @override
  final bool canListDevices;

  MockIosWorkflow(this.canListDevices);
}
