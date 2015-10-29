// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/src/backend/live_test.dart';
import 'package:test/src/backend/live_test_controller.dart';
import 'package:test/src/backend/metadata.dart';
import 'package:test/src/backend/operating_system.dart';
import 'package:test/src/backend/state.dart';
import 'package:test/src/backend/suite.dart';
import 'package:test/src/backend/test.dart';
import 'package:test/src/backend/test_platform.dart';
import 'package:test/src/util/remote_exception.dart';

import 'package:sky_tools/src/test/json_socket.dart';

class RemoteTest extends Test {
  final String name;
  final Metadata metadata;

  final JSONSocket _socket;
  final int _index;

  RemoteTest(this.name, this.metadata, this._socket, this._index);

  LiveTest load(Suite suite) {
    LiveTestController controller;
    StreamSubscription subscription;

    controller = new LiveTestController(suite, this, () async {
      controller.setState(const State(Status.running, Result.success));

      _socket.send({'command': 'run', 'index': _index});

      subscription = _socket.stream.listen((message) {
        if (message['type'] == 'error') {
          AsyncError asyncError = RemoteException.deserialize(message['error']);
          controller.addError(asyncError.error, asyncError.stackTrace);
        } else if (message['type'] == 'state-change') {
          controller.setState(
              new State(
                  new Status.parse(message['status']),
                  new Result.parse(message['result'])));
        } else if (message['type'] == 'print') {
          controller.print(message['line']);
        } else {
          assert(message['type'] == 'complete');
          subscription.cancel();
          subscription = null;
          controller.completer.complete();
        }
      });
    }, () async {
      _socket.send({'command': 'close'});
      if (subscription != null) {
        subscription.cancel();
        subscription = null;
      }
    });
    return controller.liveTest;
  }

  Test change({String name, Metadata metadata}) {
    if (name == name && metadata == this.metadata) return this;
    if (name == null) name = this.name;
    if (metadata == null) metadata = this.metadata;
    return new RemoteTest(name, metadata, _socket, _index);
  }

  // TODO(ianh): Implement this if we need it.
  Test forPlatform(TestPlatform platform, {OperatingSystem os}) {
    assert(false);
    return this;
  }  
}
