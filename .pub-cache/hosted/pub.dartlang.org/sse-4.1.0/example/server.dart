// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:shelf/shelf_io.dart' as io;
import 'package:sse/server/sse_handler.dart';

/// A basic server which sets up an SSE handler.
///
/// When a client connnects it will send a simple message and print the
/// response.
void main() async {
  var handler = SseHandler(Uri.parse('/sseHandler'));
  await io.serve(handler.handler, 'localhost', 0);
  var connections = handler.connections;
  while (await connections.hasNext) {
    var connection = await connections.next;
    connection.sink.add('foo');
    connection.stream.listen(print);
  }
}
