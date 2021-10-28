// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/src/dap/logging.dart';
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_server.dart';

/// Whether to run the DAP server in-process with the tests, or externally in
/// another process.
///
/// By default tests will run the DAP server out-of-process to match the real
/// use from editors, but this complicates debugging the adapter. Set this env
/// variables to run the server in-process for easier debugging (this can be
/// simplified in VS Code by using a launch config with custom CodeLens links).
final bool useInProcessDap = Platform.environment['DAP_TEST_INTERNAL'] == 'true';

/// Whether to print all protocol traffic to stdout while running tests.
///
/// This is useful for debugging locally or on the bots and will include both
/// DAP traffic (between the test DAP client and the DAP server) and the VM
/// Service traffic (wrapped in a custom 'dart.log' event).
final bool verboseLogging = Platform.environment['DAP_TEST_VERBOSE'] == 'true';

/// Expects the lines in [actual] to match the relevant matcher in [expected],
/// ignoring differences in line endings and trailing whitespace.
void expectLines(
  String actual,
  List<Object> expected, {
  bool allowExtras = false,
}) {
  if (allowExtras) {
    expect(
      actual.replaceAll('\r\n', '\n').trim().split('\n'),
      containsAllInOrder(expected),
    );
  } else {
    expect(
      actual.replaceAll('\r\n', '\n').trim().split('\n'),
      equals(expected),
    );
  }
}

/// A helper class containing the DAP server/client for DAP integration tests.
class DapTestSession {
  DapTestSession._(this.server, this.client);

  DapTestServer server;
  DapTestClient client;

  Future<void> tearDown() async {
    await client.stop();
    await server.stop();
  }

  static Future<DapTestSession> setUp({List<String>? additionalArgs}) async {
    final DapTestServer server = await _startServer(additionalArgs: additionalArgs);
    final DapTestClient client = await DapTestClient.connect(
      server,
      captureVmServiceTraffic: verboseLogging,
      logger: verboseLogging ? print : null,
    );
    return DapTestSession._(server, client);
  }

  /// Starts a DAP server that can be shared across tests.
  static Future<DapTestServer> _startServer({
    Logger? logger,
    List<String>? additionalArgs,
  }) async {
    return useInProcessDap
        ? await InProcessDapTestServer.create(
            logger: logger,
            additionalArgs: additionalArgs,
          )
        : await OutOfProcessDapTestServer.create(
            logger: logger,
            additionalArgs: additionalArgs,
          );
  }
}
