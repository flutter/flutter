// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:io';

import '../debug_adapters/server.dart';
import '../runner/flutter_command.dart';

/// This command will start up a Debug Adapter that communicates using the Debug
/// Adapter Protocol (DAP).
///
/// This is for use by editors and IDEs that have DAP clients to launch and
/// debug Flutter apps/tests. It extends the standard Dart DAP implementation
/// from DDS with Flutter-specific functionality (such as Hot Restart).
///
/// The server is intended to be single-use. It should live only for the
/// duration of a single debug session in the editor, and terminate when the
/// user stops debugging. If a user starts multiple debug sessions
/// simultaneously it is expected that the editor will start multiple debug
/// adapters.
///
/// The DAP specification can be found at
/// https://microsoft.github.io/debug-adapter-protocol/.
class DebugAdapterCommand extends FlutterCommand {
  DebugAdapterCommand({ bool verboseHelp = false}):hidden = !verboseHelp {
    usesIpv6Flag(verboseHelp: verboseHelp);
    addDdsOptions(verboseHelp: verboseHelp);
  }

  @override
  final String name = 'debug_adapter';

  @override
  final String description = 'Run a Debug Adapter Protocol (DAP) server to communicate with devices.';

  @override
  final bool hidden;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final DapServer server = DapServer(
      stdin,
      stdout.nonBlocking,
      ipv6: ipv6,
      enableDds: enableDds,
    );

    await server.channel.closed;

    return FlutterCommandResult.success();
  }
}
