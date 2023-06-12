// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  var socket = WebSocketChannel.connect(Uri.parse('ws://localhost:4321'));

  // The socket is a `StreamChannel<dynamic>` because it might emit binary
  // `List<int>`, but JSON RPC 2 only works with Strings so we assert it only
  // emits those by casting it.
  var server = Server(socket.cast<String>());

  // Any string may be used as a method name. JSON-RPC 2.0 methods are
  // case-sensitive.
  var i = 0;
  server.registerMethod('count', () {
    // Just return the value to be sent as a response to the client. This can
    // be anything JSON-serializable, or a Future that completes to something
    // JSON-serializable.
    return i++;
  });

  // Methods can take parameters. They're presented as a `Parameters` object
  // which makes it easy to validate that the expected parameters exist.
  server.registerMethod('echo', (Parameters params) {
    // If the request doesn't have a "message" parameter this will
    // automatically send a response notifying the client that the request
    // was invalid.
    return params['message'].value;
  });

  // `Parameters` has methods for verifying argument types.
  server.registerMethod('subtract', (Parameters params) {
    // If "minuend" or "subtrahend" aren't numbers, this will reject the
    // request.
    return params['minuend'].asNum - params['subtrahend'].asNum;
  });

  // [Parameters] also supports optional arguments.
  server.registerMethod('sort', (Parameters params) {
    var list = params['list'].asList;
    list.sort();
    if (params['descendint'].asBoolOr(false)) {
      return list.reversed;
    } else {
      return list;
    }
  });

  // A method can send an error response by throwing a `RpcException`.
  // Any positive number may be used as an application- defined error code.
  const dividByZero = 1;
  server.registerMethod('divide', (Parameters params) {
    var divisor = params['divisor'].asNum;
    if (divisor == 0) {
      throw RpcException(dividByZero, 'Cannot divide by zero.');
    }

    return params['dividend'].asNum / divisor;
  });

  // To give you time to register all your methods, the server won't start
  // listening for requests until you call `listen`. Messages are buffered until
  // listen is called. The returned Future won't complete until the connection
  // is closed.
  server.listen();
}
