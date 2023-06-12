// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'adapters/dart.dart';
import 'adapters/dart_cli_adapter.dart';
import 'adapters/dart_test_adapter.dart';
import 'logging.dart';
import 'protocol_stream.dart';

/// A DAP server that communicates over a [ByteStreamServerChannel], usually
/// constructed from the processes stdin/stdout streams.
///
/// The server runs in single-user mode and services only a single client. For
/// multiple debug sessions, there would be multiple servers (and the editor
/// would have a client for each of them).
class DapServer {
  final ByteStreamServerChannel channel;
  late final DartDebugAdapter adapter;
  final bool ipv6;
  final bool enableDds;
  final bool enableAuthCodes;
  final bool test;
  final Logger? logger;

  DapServer(
    Stream<List<int>> _input,
    StreamSink<List<int>> _output, {
    this.ipv6 = false,
    this.enableDds = true,
    this.enableAuthCodes = true,
    this.test = false,
    this.logger,
    Function? onError,
  }) : channel = ByteStreamServerChannel(_input, _output, logger) {
    adapter = test
        ? DartTestDebugAdapter(
            channel,
            ipv6: ipv6,
            enableDds: enableDds,
            enableAuthCodes: enableAuthCodes,
            logger: logger,
            onError: onError,
          )
        : DartCliDebugAdapter(
            channel,
            ipv6: ipv6,
            enableDds: enableDds,
            enableAuthCodes: enableAuthCodes,
            logger: logger,
            onError: onError,
          );
  }

  void stop() {
    channel.close();
  }
}
