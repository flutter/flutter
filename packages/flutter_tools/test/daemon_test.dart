// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:flutter_tools/src/commands/daemon.dart';
import 'package:test/test.dart';

import 'src/mocks.dart';

main() => defineTests();

defineTests() {
  group('daemon', () {
    Daemon daemon;

    tearDown(() {
      if (daemon != null)
        return daemon.shutdown();
    });

    test('daemon.version', () async {
      StreamController<Map> commands = new StreamController();
      StreamController<Map> responses = new StreamController();
      daemon = new Daemon(
        commands.stream,
        (Map result) => responses.add(result)
      );
      commands.add({'id': 0, 'event': 'daemon.version'});
      Map response = await responses.stream.first;
      expect(response['id'], 0);
      expect(response['result'], isNotEmpty);
      expect(response['result'] is String, true);
    });

    test('daemon.shutdown', () async {
      StreamController<Map> commands = new StreamController();
      StreamController<Map> responses = new StreamController();
      daemon = new Daemon(
        commands.stream,
        (Map result) => responses.add(result)
      );
      commands.add({'id': 0, 'event': 'daemon.shutdown'});
      return daemon.onExit.then((int code) {
        expect(code, 0);
      });
    });

    test('daemon.stopAll', () async {
      DaemonCommand command = new DaemonCommand();
      applyMocksToCommand(command);

      StreamController<Map> commands = new StreamController();
      StreamController<Map> responses = new StreamController();
      daemon = new Daemon(
        commands.stream,
        (Map result) => responses.add(result),
        daemonCommand: command
      );

      MockDeviceStore mockDevices = command.devices;

      when(mockDevices.android.isConnected()).thenReturn(true);
      when(mockDevices.android.stopApp(any)).thenReturn(true);

      when(mockDevices.iOS.isConnected()).thenReturn(false);
      when(mockDevices.iOS.stopApp(any)).thenReturn(false);

      when(mockDevices.iOSSimulator.isConnected()).thenReturn(false);
      when(mockDevices.iOSSimulator.stopApp(any)).thenReturn(false);

      commands.add({'id': 0, 'event': 'app.stopAll'});
      Map response = await responses.stream.first;
      expect(response['id'], 0);
      expect(response['result'], true);
    });
  });
}
