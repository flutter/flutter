// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:isolate';

import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/stream_channel.dart';

import 'package:test_core/src/runner/plugin/remote_platform_helpers.dart';

/// Bootstraps a vm test to communicate with the test runner.
void internalBootstrapVmTest(Function Function() getMain, SendPort sendPort) {
  var platformChannel =
      MultiChannel(IsolateChannel<Object?>.connectSend(sendPort));
  var testControlChannel = platformChannel.virtualChannel()
    ..pipe(serializeSuite(getMain));
  platformChannel.sink.add(testControlChannel.id);

  platformChannel.stream.forEach((message) {
    assert(message == 'debug');
    debugger(message: 'Paused by test runner');
    platformChannel.sink.add('done');
  });
}
