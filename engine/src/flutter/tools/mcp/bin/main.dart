// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show LineSplitter, utf8;
import 'dart:io' as io show stdin, stdout;

import 'package:async/async.dart' show StreamSinkTransformer;
import 'package:engine_mcp/server.dart';
import 'package:stream_channel/stream_channel.dart';

void main() async {
  EngineServer.fromStreamChannel(
    StreamChannel.withCloseGuarantee(io.stdin, io.stdout)
        .transform(StreamChannelTransformer.fromCodec(utf8))
        .transformStream(const LineSplitter())
        .transformSink(
          StreamSinkTransformer.fromHandlers(
            handleData: (data, sink) {
              sink.add('$data\n');
            },
          ),
        ),
  );
}
