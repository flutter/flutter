// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:test/test.dart';

const kPortName = 'foobar';
const kErrorCode = -1;
const kStartCode = 0;
const kCloseCode = 1;
const kDeletedCode = 2;

void isolateSpawnEntrypoint(SendPort port) {
  sendHelper(int code, [String message = '']) {
    port.send(<dynamic>[code, message]);
  }

  SendPort shared = IsolateNameServer.lookupPortByName(kPortName);
  if (shared == null) {
    sendHelper(kErrorCode, 'Could not find port: $kPortName');
    return;
  }

  // ack that the SendPort lookup was successful.
  sendHelper(kStartCode);

  shared.send(kPortName);
  sendHelper(kCloseCode);

  // We'll fail if the ReceivePort's callback is called more than once. Try to
  // send another message to ensure we don't crash.
  shared.send('garbage');

  bool result = IsolateNameServer.removePortNameMapping(kPortName);
  if (result) {
    sendHelper(kDeletedCode);
  } else {
    sendHelper(kErrorCode, 'Was unable to remove mapping for $kPortName');
  }
}

void main() {
  tearDown(() {
    IsolateNameServer.removePortNameMapping(kPortName);
  });

  test('simple isolate name server', () {
    // Mapping for 'foobar' isn't set. Check these cases to ensure correct
    // negative response.
    expect(IsolateNameServer.lookupPortByName(kPortName), isNull);
    expect(IsolateNameServer.removePortNameMapping(kPortName), isFalse);

    // Register a SendPort.
    final receivePort = new ReceivePort();
    final sendPort = receivePort.sendPort;
    expect(IsolateNameServer.registerPortWithName(sendPort, kPortName), isTrue);
    expect(IsolateNameServer.lookupPortByName(kPortName), sendPort);

    // Check we can't register the same name twice.
    final receivePort2 = new ReceivePort();
    final sendPort2 = receivePort2.sendPort;
    expect(
        IsolateNameServer.registerPortWithName(sendPort2, kPortName), isFalse);
    expect(IsolateNameServer.lookupPortByName(kPortName), sendPort);

    // Remove the mapping.
    expect(IsolateNameServer.removePortNameMapping(kPortName), isTrue);
    expect(IsolateNameServer.lookupPortByName(kPortName), isNull);

    // Ensure registering a new port with the old name returns the new port.
    expect(
        IsolateNameServer.registerPortWithName(sendPort2, kPortName), isTrue);
    expect(IsolateNameServer.lookupPortByName(kPortName), sendPort2);

    // Close so the test runner doesn't hang.
    receivePort.close();
    receivePort2.close();
  });

  test('isolate name server multi-isolate', () async {
    // Register our send port with the name server.
    final receivePort = new ReceivePort();
    final sendPort = receivePort.sendPort;
    expect(IsolateNameServer.registerPortWithName(sendPort, kPortName), isTrue);

    // Test driver.
    final testReceivePort = new ReceivePort();
    testReceivePort.listen(expectAsync1((response) {
      final int code = response[0];
      final String message = response[1];
      switch (code) {
        case kStartCode:
          break;
        case kCloseCode:
          receivePort.close();
          break;
        case kDeletedCode:
          expect(IsolateNameServer.lookupPortByName(kPortName), isNull);
          // Test is done, close the last ReceivePort.
          testReceivePort.close();
          break;
        case kErrorCode:
          throw message;
        default:
          throw 'UNREACHABLE';
      }
    }, count: 3));

    receivePort.listen(expectAsync1((message) {
      // If we don't get this message, we timeout and fail.
      expect(message, kPortName);
    }));

    // Run the test.
    await Isolate.spawn(isolateSpawnEntrypoint, testReceivePort.sendPort);
  });
}
