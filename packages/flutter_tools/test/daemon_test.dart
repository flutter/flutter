// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
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
      appContext.setVariable(Platform, const LocalPlatform());
      appContext.setVariable(Logger, notifyingLogger);
      appContext.setVariable(Doctor, new Doctor());
      if (platform.isMacOS)
        appContext.setVariable(Xcode, new Xcode());
      appContext.setVariable(DeviceManager, new MockDeviceManager());
    });

    tearDown(() {
      if (daemon != null)
        return daemon.shutdown();
      notifyingLogger.dispose();
    });

    _testUsingContext('daemon.version', () async {
      final StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      final StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
        commands.stream,
        responses.add,
        notifyingLogger: notifyingLogger
      );
      commands.add(<String, dynamic>{'id': 0, 'method': 'daemon.version'});
      final Map<String, dynamic> response = await responses.stream.where(_notEvent).first;
      expect(response['id'], 0);
      expect(response['result'], isNotEmpty);
      expect(response['result'] is String, true);
      responses.close();
      commands.close();
    });

    _testUsingContext('daemon.logMessage', () {
      return appContext.runInZone(() async {
        final StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
        final StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
        daemon = new Daemon(
          commands.stream,
          responses.add,
          notifyingLogger: notifyingLogger
        );
        printError('daemon.logMessage test');
        final Map<String, dynamic> response = await responses.stream.where((Map<String, dynamic> map) {
          return map['event'] == 'daemon.logMessage' && map['params']['level'] == 'error';
        }).first;
        expect(response['id'], isNull);
        expect(response['event'], 'daemon.logMessage');
        final Map<String, String> logMessage = response['params'];
        expect(logMessage['level'], 'error');
        expect(logMessage['message'], 'daemon.logMessage test');
        responses.close();
        commands.close();
      });
    });

    _testUsingContext('daemon.logMessage logToStdout', () async {
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

    _testUsingContext('daemon.shutdown', () async {
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

    _testUsingContext('daemon.start', () async {
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
      final Map<String, dynamic> response = await responses.stream.where(_notEvent).first;
      expect(response['id'], 0);
      expect(response['error'], contains('deviceId is required'));
      responses.close();
      commands.close();
    });

    _testUsingContext('daemon.restart', () async {
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
      final Map<String, dynamic> response = await responses.stream.where(_notEvent).first;
      expect(response['id'], 0);
      expect(response['error'], contains('appId is required'));
      responses.close();
      commands.close();
    });

    _testUsingContext('daemon.callServiceExtension', () async {
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
      final Map<String, dynamic> response = await responses.stream.where(_notEvent).first;
      expect(response['id'], 0);
      expect(response['error'], contains('appId is required'));
      responses.close();
      commands.close();
    });

    _testUsingContext('daemon.stop', () async {
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
      final Map<String, dynamic> response = await responses.stream.where(_notEvent).first;
      expect(response['id'], 0);
      expect(response['error'], contains('appId is required'));
      responses.close();
      commands.close();
    });

    _testUsingContext('device.getDevices', () async {
      final StreamController<Map<String, dynamic>> commands = new StreamController<Map<String, dynamic>>();
      final StreamController<Map<String, dynamic>> responses = new StreamController<Map<String, dynamic>>();
      daemon = new Daemon(
        commands.stream,
        responses.add,
        notifyingLogger: notifyingLogger
      );
      commands.add(<String, dynamic>{'id': 0, 'method': 'device.getDevices'});
      final Map<String, dynamic> response = await responses.stream.where(_notEvent).first;
      expect(response['id'], 0);
      expect(response['result'], isList);
      responses.close();
      commands.close();
    });

    _testUsingContext('device.notify', () {
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
    });
  });
}

bool _notEvent(Map<String, dynamic> map) => map['event'] == null;
