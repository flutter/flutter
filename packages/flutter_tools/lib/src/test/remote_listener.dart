// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:stack_trace/stack_trace.dart';
import 'package:test/src/backend/declarer.dart';
import 'package:test/src/backend/live_test.dart';
import 'package:test/src/backend/metadata.dart';
import 'package:test/src/backend/operating_system.dart';
import 'package:test/src/backend/suite.dart';
import 'package:test/src/backend/test_platform.dart';
import 'package:test/src/backend/test.dart';
import 'package:test/src/util/remote_exception.dart';

final OperatingSystem currentOS = (() {
  var name = Platform.operatingSystem;
  var os = OperatingSystem.findByIoName(name);
  if (os != null) return os;

  throw new UnsupportedError('Unsupported operating system "$name".');
})();

typedef AsyncFunction();

class RemoteListener {
  RemoteListener._(this._suite, this._socket);

  final Suite _suite;
  final WebSocket _socket;
  final Set<LiveTest> _liveTests = new Set<LiveTest>();

  static Future start(String server, Metadata metadata, Function getMain()) async {
    WebSocket socket = await WebSocket.connect(server);
    // Capture any top-level errors (mostly lazy syntax errors, since other are
    // caught below) and report them to the parent isolate. We set errors
    // non-fatal because otherwise they'll be double-printed.
    var errorPort = new ReceivePort();
    Isolate.current.setErrorsFatal(false);
    Isolate.current.addErrorListener(errorPort.sendPort);
    errorPort.listen((message) {
      // Masquerade as an IsolateSpawnException because that's what this would
      // be if the error had been detected statically.
      var error = new IsolateSpawnException(message[0]);
      var stackTrace =
          message[1] == null ? new Trace([]) : new Trace.parse(message[1]);
      socket.add(JSON.encode({
        "type": "error",
        "error": RemoteException.serialize(error, stackTrace)
      }));
    });

    var main;
    try {
      main = getMain();
    } on NoSuchMethodError catch (_) {
      _sendLoadException(socket, "No top-level main() function defined.");
      return;
    }

    if (main is! Function) {
      _sendLoadException(socket, "Top-level main getter is not a function.");
      return;
    } else if (main is! AsyncFunction) {
      _sendLoadException(
          socket, "Top-level main() function takes arguments.");
      return;
    }

    Declarer declarer = new Declarer(metadata);
    try {
      await runZoned(() => new Future.sync(main), zoneValues: {
        #test.declarer: declarer
      }, zoneSpecification: new ZoneSpecification(print: (_, __, ___, line) {
        socket.add(JSON.encode({"type": "print", "line": line}));
      }));
    } catch (error, stackTrace) {
      socket.add(JSON.encode({
        "type": "error",
        "error": RemoteException.serialize(error, stackTrace)
      }));
      return;
    }

    Suite suite = new Suite(declarer.build(),
        platform: TestPlatform.vm, os: currentOS);
    new RemoteListener._(suite, socket)._listen();
  }

  static void _sendLoadException(WebSocket socket, String message) {
    socket.add(JSON.encode({"type": "loadException", "message": message}));
  }

  void _send(data) {
    _socket.add(JSON.encode(data));
  }

  void _listen() {
    List tests = [];
    for (var i = 0; i < _suite.group.entries.length; i++) {
      // TODO(ianh): entries[] might return a Group instead of a Test. We don't
      // currently support nested groups.
      Test test = _suite.group.entries[i];
      tests.add({
        "name": test.name,
        "metadata": test.metadata.serialize(),
        "index": i,
      });
    }

    _send({"type": "success", "tests": tests});
    _socket.listen(_handleCommand);
  }

  void _handleCommand(String data) {
    var message = JSON.decode(data);
    if (message['command'] == 'run') {
      // TODO(ianh): entries[] might return a Group instead of a Test. We don't
      // currently support nested groups.
      Test test = _suite.group.entries[message['index']];
      LiveTest liveTest = test.load(_suite);
      _liveTests.add(liveTest);

      liveTest.onStateChange.listen((state) {
        _send({
          "type": "state-change",
          "status": state.status.name,
          "result": state.result.name
        });
      });

      liveTest.onError.listen((asyncError) {
        _send({
          "type": "error",
          "error": RemoteException.serialize(
            asyncError.error,
            asyncError.stackTrace
          )
        });
      });

      liveTest.onPrint.listen((line) {
        _send({"type": "print", "line": line});
      });

      liveTest.run().then((_) {
        _send({"type": "complete"});
        _liveTests.remove(liveTest);
      });
    } else if (message['command'] == 'close') {
      if (_liveTests.isNotEmpty)
        print('closing with ${_liveTests.length} live tests');
      for (LiveTest liveTest in _liveTests)
        liveTest.close();
      _liveTests.clear();
    } else {
      print('remote_listener.dart: ignoring command "${message["command"]}" from test harness');
    }
  }
}
