// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate.example.http_server;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:isolate/isolate_runner.dart';
import 'package:isolate/ports.dart';
import 'package:isolate/runner.dart';

Future<Future<Object?> Function()> runHttpServer(
    Runner runner, int port, HttpListener listener) async {
  var stopPort = await runner.run(_startHttpServer, [port, listener]);

  return () => _sendStop(stopPort);
}

Future<Object?> _sendStop(SendPort stopPort) =>
    singleResponseFuture(stopPort.send);

Future<SendPort> _startHttpServer(List<Object?> args) async {
  var port = args[0] as int;
  var listener = args[1] as HttpListener;

  var server =
      await HttpServer.bind(InternetAddress.anyIPv6, port, shared: true);
  await listener.start(server);

  return singleCallbackPort((SendPort resultPort) {
    sendFutureResult(Future.sync(listener.stop), resultPort);
  });
}

/// An [HttpRequest] handler setup. Gets called when with the server, and
/// is told when to stop listening.
///
/// These callbacks allow the listener to set up handlers for HTTP requests.
/// The object should be sendable to an equivalent isolate.
abstract class HttpListener {
  Future start(HttpServer server);

  Future stop();
}

/// An [HttpListener] that sets itself up as an echo server.
///
/// Returns the message content plus an ID describing the isolate that
/// handled the request.
class EchoHttpListener implements HttpListener {
  static const _delay = Duration(seconds: 2);
  static final _id = Isolate.current.hashCode;
  final SendPort _counter;

  StreamSubscription? _subscription;

  EchoHttpListener(this._counter);

  @override
  Future start(HttpServer server) async {
    print('Starting isolate $_id');
    _subscription = server.listen((HttpRequest request) async {
      await request.response.addStream(request);
      print('Request to $hashCode');
      request.response.write('#$_id\n');
      var watch = Stopwatch()..start();
      while (watch.elapsed < _delay) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      print('Response from $_id');
      await request.response.close();
      _counter.send(null);
    });
  }

  @override
  Future stop() async {
    print('Stopping isolate $_id');
    await _subscription?.cancel();
  }
}

void main(List<String> args) async {
  var port = 0;
  if (args.isNotEmpty) {
    port = int.parse(args[0]);
  }

  var counter = ReceivePort();
  HttpListener listener = EchoHttpListener(counter.sendPort);

  // Used to ensure the requested port is available or to find an available
  // port if `0` is provided.
  var socket =
      await ServerSocket.bind(InternetAddress.anyIPv6, port, shared: true);

  port = socket.port;
  var isolates = await Future.wait<IsolateRunner>(
      Iterable.generate(5, (_) => IsolateRunner.spawn()), cleanUp: (isolate) {
    isolate.close();
  });

  var stoppers =
      await Future.wait<Function>(isolates.map((IsolateRunner isolate) {
    return runHttpServer(isolate, socket.port, listener);
  }), cleanUp: (shutdownServer) {
    shutdownServer();
  });

  await socket.close();
  var count = 25;

  print('Server listening on port $port for $count requests');
  print('Test with:');
  print('  ab -l -c10 -n $count http://localhost:$port/');
  print("where 'ab' is ApacheBench from, e.g., apache2_tools.");

  await for (var _ in counter) {
    count--;
    if (count == 0) {
      print('Shutting down');
      for (var stopper in stoppers) {
        await stopper();
      }
      counter.close();
    }
  }
  print('Finished');
}
