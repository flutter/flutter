// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../convert.dart';
import '../globals.dart';

/// The [FuchsiaSdk] instance.
FuchsiaSdk get fuchsiaSdk => context.get<FuchsiaSdk>();

/// The [FuchsiaArtifacts] instance.
FuchsiaArtifacts get fuchsiaArtifacts => context.get<FuchsiaArtifacts>();

/// The Fuchsia SDK shell commands.
///
/// This workflow assumes development within the fuchsia source tree,
/// including a working fx command-line tool in the user's PATH.
class FuchsiaSdk {
  static const List<String> _syslogCommand = <String>['fx', 'syslog', '--clock', 'Local'];

  /// Example output:
  ///    $ dev_finder list -full
  ///    > 192.168.42.56 paper-pulp-bush-angel
  Future<String> listDevices() async {
    try {
      final String path = fuchsiaArtifacts.devFinder.absolute.path;
      final RunResult process = await runAsync(<String>[path, 'list', '-full']);
      return process.stdout.trim();
    } catch (exception) {
      printTrace('$exception');
    }
    return null;
  }

  /// Returns the fuchsia system logs for an attached device.
  ///
  /// Does not currently support multiple attached devices.
  Stream<String> syslogs() {
    Process process;
    try {
      final StreamController<String> controller = StreamController<String>(onCancel: () {
        process.kill();
      });
      processManager.start(_syslogCommand).then((Process newProcess) {
        if (controller.isClosed) {
          return;
        }
        process = newProcess;
        process.exitCode.whenComplete(controller.close);
        controller.addStream(process.stdout.transform(utf8.decoder).transform(const LineSplitter()));
      });
      return controller.stream;
    } catch (exception) {
      printTrace('$exception');
    }
    return null;
  }
}

/// Fuchsia-specific artifacts used to interact with a device.
class FuchsiaArtifacts {
  /// Creates a new [FuchsiaArtifacts].
  FuchsiaArtifacts({this.sshConfig, this.devFinder});

  /// The location of the SSH configuration file used to interact with a
  /// Fuchsia device.
  final File sshConfig;

  /// The location of the dev finder tool used to locate connected
  /// Fuchsia devices.
  final File devFinder;
}
