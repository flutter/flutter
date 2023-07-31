// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:sse/client/sse_client.dart';

void main() {
  var channel = SseClient('/test');

  document.querySelector('button')!.onClick.listen((_) {
    channel.sink.close();
  });

  channel.stream.listen((s) {
    if (s.startsWith('send ')) {
      var count = int.parse(s.split(' ').last);
      for (var i = 0; i < count; i++) {
        channel.sink.add('$i');
      }
    } else {
      channel.sink.add(s);
    }
  });
}
