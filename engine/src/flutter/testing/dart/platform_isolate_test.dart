// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:litetest/litetest.dart';

int counter = 0;

void main() {
  test('PlatformIsolate isRunningOnPlatformThread, false cases', () async {
    final bool isPlatThread =
        await Isolate.run(() => isRunningOnPlatformThread);
    expect(isPlatThread, isFalse);
  });

  test('PlatformIsolate runOnPlatformThread', () async {
    final bool isPlatThread =
        await runOnPlatformThread(() => isRunningOnPlatformThread);
    expect(isPlatThread, isTrue);
  });

  test('PlatformIsolate runOnPlatformThread, async operations', () async {
    final bool isPlatThread = await runOnPlatformThread(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return isRunningOnPlatformThread;
    });
    expect(isPlatThread, isTrue);
  });

  test('PlatformIsolate runOnPlatformThread, retains state', () async {
    await runOnPlatformThread(() => ++counter);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await runOnPlatformThread(() => ++counter);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await runOnPlatformThread(() => ++counter);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final int counterValue = await runOnPlatformThread(() => counter);
    expect(counterValue, 3);
  });

  test('PlatformIsolate runOnPlatformThread, concurrent jobs', () async {
    final Future<int> future1 = runOnPlatformThread(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return 1;
    });
    final Future<int> future2 = runOnPlatformThread(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return 2;
    });
    final Future<int> future3 = runOnPlatformThread(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return 3;
    });
    expect(await future1, 1);
    expect(await future2, 2);
    expect(await future3, 3);
  });

  test('PlatformIsolate runOnPlatformThread, send and receive messages',
      () async {
    // Send numbers 1 to 10 to the platform isolate. The platform isolate
    // multiplies them by 100 and sends them back.
    int sum = 0;
    final RawReceivePort recvPort = RawReceivePort((Object message) {
      if (message is SendPort) {
        for (int i = 1; i <= 10; ++i) {
          message.send(i);
        }
      } else {
        sum += message as int;
      }
    });
    final SendPort sendPort = recvPort.sendPort;
    await runOnPlatformThread(() async {
      final Completer<void> completer = Completer<void>();
      final RawReceivePort recvPort = RawReceivePort((Object message) {
        sendPort.send((message as int) * 100);
        if (message == 10) {
          completer.complete();
        }
      });
      sendPort.send(recvPort.sendPort);
      await completer.future;
      recvPort.close();
    });
    expect(sum, 5500); // sum(1 to 10) * 100
    recvPort.close();
  });

  test('PlatformIsolate runOnPlatformThread, throws', () async {
    bool throws = false;
    try {
      await runOnPlatformThread(() => throw 'Oh no!');
    } catch (error) {
      expect(error, 'Oh no!');
      throws = true;
    }
    expect(throws, true);
  });

  test('PlatformIsolate runOnPlatformThread, async throws', () async {
    bool throws = false;
    try {
      await runOnPlatformThread(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        throw 'Oh no!';
      });
    } catch (error) {
      expect(error, 'Oh no!');
      throws = true;
    }
    expect(throws, true);
  });

  test('PlatformIsolate runOnPlatformThread, disabled on helper isolates',
      () async {
    await Isolate.run(() {
      expect(() => runOnPlatformThread(() => print('Unreachable')), throws);
    });
  });

  test('PlatformIsolate runOnPlatformThread, on platform isolate', () async {
    final int result = await runOnPlatformThread(() => runOnPlatformThread(
        () => runOnPlatformThread(() => runOnPlatformThread(() => 123))));
    expect(result, 123);
  });

  test('PlatformIsolate runOnPlatformThread, exit disabled', () async {
    await runOnPlatformThread(() => expect(() => Isolate.exit(), throws));
  });

  test('PlatformIsolate runOnPlatformThread, unsendable object', () async {
    bool throws = false;
    try {
      await runOnPlatformThread(() => ReceivePort());
    } catch (error) {
      throws = true;
    }
    expect(throws, true);
  });

  test('PlatformIsolate runOnPlatformThread, unsendable object async',
      () async {
    bool throws = false;
    try {
      await runOnPlatformThread(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return ReceivePort();
      });
    } catch (error) {
      throws = true;
    }
    expect(throws, true);
  });

  test('PlatformIsolate runOnPlatformThread, throws unsendable', () async {
    bool throws = false;
    try {
      await runOnPlatformThread(() => throw ReceivePort());
    } catch (error) {
      throws = true;
    }
    expect(throws, true);
  });

  test('PlatformIsolate runOnPlatformThread, throws unsendable async',
      () async {
    bool throws = false;
    try {
      await runOnPlatformThread(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        throw ReceivePort();
      });
    } catch (error) {
      throws = true;
    }
    expect(throws, true);
  });
}
