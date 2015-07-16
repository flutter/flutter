// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library observatory_tester;

// Minimal dependency Observatory heartbeat test.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class Expect {
  static equals(a, b) {
    if (a != b) {
      throw 'Expected $a == $b';
    }
  }

  static isMap(a) {
    if (a is! Map) {
      throw 'Expected $a to be a Map';
    }
  }

  static notExecuted() {
    throw 'Should not have hit';
  }

  static isNotNull(a) {
    if (a == null) {
      throw 'Expected $a to not be null.';
    }
  }
}

class Launch {
  Launch(this.executable, this.arguments, this.process, this.port) {
    _killRequested = false;
    this.process.exitCode.then(_checkKill);
  }

  void kill() {
    _killRequested = true;
    process.kill();
  }

  void _checkKill(int exitCode) {
    if (!_killRequested) {
      throw 'Unexpected exit of testee. (exitCode = $exitCode)';
    }
  }

  final String executable;
  final String arguments;
  final Process process;
  final int port;
  bool _killRequested;
}

class Launcher {
  /// Launch [executable] with [arguments]. Returns a future to a [Launch]
  /// which includes the process and port where Observatory is running.
  static Future<Launch> launch(String executable,
                               List<String> arguments) async {
    var process = await Process.start(executable, arguments);

    // Completer completes once 'Observatory listening on' message has been
    // scraped and we know the port number.
    var completer = new Completer();

    process.stdout.transform(UTF8.decoder)
                  .transform(new LineSplitter()).listen((line) {
      if (line.startsWith('Observatory listening on http://')) {
        RegExp portExp = new RegExp(r"\d+.\d+.\d+.\d+:(\d+)");
        var port = portExp.firstMatch(line).group(1);
        var portNumber = int.parse(port);
        completer.complete(portNumber);
      } else {
        print(line);
      }
    });

    process.stderr.transform(UTF8.decoder)
                  .transform(new LineSplitter()).listen((line) {
      print(line);
    });

    var port = await completer.future;
    return new Launch(executable, arguments, process, port);
  }
}

class ServiceHelper {
  ServiceHelper(this.client) {
    client.listen(_onData,
                  onError: _onError,
                  cancelOnError: true);
  }

  Future<Map> invokeRPC(String method, [Map params]) async {
    var key = _createKey();
    var request = JSON.encode({
      'jsonrpc': '2.0',
      'method': method,
      'params': params == null ? {} : params,
      'id': key,
    });
    client.add(request);
    var completer = new Completer();
    _outstanding_requests[key] = completer;
    print('-> $key ($method)');
    return completer.future;
  }

  String _createKey() {
    var key = '$_id';
    _id++;
    return key;
  }

  void _onData(String message) {
    var response = JSON.decode(message);
    var key = response['id'];
    print('<- $key');
    var completer = _outstanding_requests.remove(key);
    assert(completer != null);
    var result = response['result'];
    var error = response['error'];
    if (error != null) {
      assert(result == null);
      completer.completeError(error);
    } else {
      assert(result != null);
      completer.complete(result);
    }
  }

  void _onError(error) {
    print('WebSocket error: $error');
  }

  final WebSocket client;
  final Map<String, Completer> _outstanding_requests = <String, Completer>{};
  var _id = 1;
}

main(List<String> args) async {
  var executable = args[0];
  var arguments = args.sublist(1);

  print('Launching $executable with $arguments');

  var launch = await Launcher.launch(executable, arguments);

  print('Observatory is on port ${launch.port}');
  var serviceUrl = 'ws://127.0.0.1:${launch.port}/ws';

  var client = await WebSocket.connect(serviceUrl);
  print('Connected to $serviceUrl');

  var helper = new ServiceHelper(client);

  // Invoke getVM RPC. Verify a valid repsonse.
  var vm = await helper.invokeRPC('getVM');
  Expect.equals(vm['type'], 'VM');

  // Invoke a bogus RPC. Expect an error.
  bool errorCaught = false;
  try {
    var bad = await helper.invokeRPC('BARTSIMPSON');
    Expect.notExecuted();
  } catch (e) {
    errorCaught = true;
    // Map.
    Expect.isMap(e);
    // Has an error code.
    Expect.isNotNull(e['code']);
  }
  Expect.equals(errorCaught, true);

  await client.close();
  print('Closed connection');

  print('Finished.');
  launch.kill();
}
