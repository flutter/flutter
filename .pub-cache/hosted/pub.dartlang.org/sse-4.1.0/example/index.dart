// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:sse/client/sse_client.dart';

/// A basic example which should be used in a browser that supports SSE.
void main() {
  var channel = SseClient('/sseHandler');

  channel.stream.listen((s) {
    // Listen for messages and send them back.
    channel.sink.add(s);
  });
}
