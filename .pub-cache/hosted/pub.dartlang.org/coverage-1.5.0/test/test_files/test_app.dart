// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// coverage:ignore-file

import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:coverage/src/util.dart';

import 'test_app_isolate.dart';

Future<void> main() async {
  for (var i = 0; i < 10; i++) {
    for (var j = 0; j < 10; j++) {
      final sum = usedMethod(i, j);
      if (sum != (i + j)) {
        throw 'bad method!';
      }
    }
  }

  final port = ReceivePort();

  final isolate =
      await Isolate.spawn(isolateTask, [port.sendPort, 1, 2], paused: true);
  await Service.controlWebServer(enable: true);
  final isolateID = Service.getIsolateID(isolate);
  print('isolateId = $isolateID');

  isolate.addOnExitListener(port.sendPort);
  isolate.resume(isolate.pauseCapability!);

  final value = await port.first as int;
  if (value != 3) {
    throw 'expected 3!';
  }

  final result = await retry(() async => 42, const Duration(seconds: 1)) as int;
  print(result);
}

int usedMethod(int a, int b) {
  return a + b;
}

int unusedMethod(int a, int b) {
  return a - b;
}
