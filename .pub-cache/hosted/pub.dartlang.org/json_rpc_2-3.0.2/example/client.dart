// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  var socket = WebSocketChannel.connect(Uri.parse('ws://localhost:4321'));
  var client = Client(socket.cast<String>());

  // The client won't subscribe to the input stream until you call `listen`.
  // The returned Future won't complete until the connection is closed.
  unawaited(client.listen());

  // This calls the "count" method on the server. A Future is returned that
  // will complete to the value contained in the server's response.
  var count = await client.sendRequest('count');
  print('Count is $count');

  // Parameters are passed as a simple Map or, for positional parameters, an
  // Iterable. Make sure they're JSON-serializable!
  var echo = await client.sendRequest('echo', {'message': 'hello'});
  print('Echo says "$echo"!');

  // A notification is a way to call a method that tells the server that no
  // result is expected. Its return type is `void`; even if it causes an
  // error, you won't hear back.
  client.sendNotification('count');

  // If the server sends an error response, the returned Future will complete
  // with an RpcException. You can catch this error and inspect its error
  // code, message, and any data that the server sent along with it.
  try {
    await client.sendRequest('divide', {'dividend': 2, 'divisor': 0});
  } on RpcException catch (error) {
    print('RPC error ${error.code}: ${error.message}');
  }
}
