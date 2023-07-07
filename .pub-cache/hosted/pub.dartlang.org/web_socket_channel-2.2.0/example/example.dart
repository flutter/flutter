// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

void main() {
  final channel = IOWebSocketChannel.connect('ws://localhost:1234');

  channel.stream.listen((message) {
    channel.sink.add('received!');
    channel.sink.close(status.goingAway);
  });
}
