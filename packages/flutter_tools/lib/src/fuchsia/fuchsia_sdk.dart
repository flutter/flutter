// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../cache.dart';
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
  Stream<String> syslogs(String id) {
    Process process;
    try {
      final StreamController<String> controller =
          StreamController<String>(onCancel: () {
        process.kill();
      });
      if (fuchsiaArtifacts.sshConfig == null) {
        return null;
      }
      const String remoteCommand = 'log_listener --clock Local';
      final List<String> cmd = <String>[
        'ssh',
        '-F',
        fuchsiaArtifacts.sshConfig.absolute.path,
        id,
        remoteCommand
      ];
      processManager.start(cmd).then((Process newProcess) {
        if (controller.isClosed) {
          return;
        }
        process = newProcess;
        process.exitCode.whenComplete(controller.close);
        controller.addStream(process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter()));
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

  /// Creates a new [FuchsiaArtifacts] using the cached Fuchsia SDK.
  ///
  /// Finds tools under bin/cache/artifacts/fuchsia/tools.
  /// Queries environment variables (first FUCHSIA_BUILD_DIR, then
  /// FUCHSIA_SSH_CONFIG) to find the ssh configuration needed to talk to
  /// a device.
  factory FuchsiaArtifacts.find() {
    final String fuchsia = Cache.instance.getArtifactDirectory('fuchsia').path;
    final String tools = fs.path.join(fuchsia, 'tools');

    // If FUCHSIA_BUILD_DIR is defined, then look for the ssh_config dir
    // relative to it. Next, if FUCHSIA_SSH_CONFIG is defined, then use it.
    // TODO(zra): Consider passing the ssh config path in with a flag.
    File sshConfig;
    if (platform.environment.containsKey(_kFuchsiaBuildDir)) {
      sshConfig = fs.file(fs.path.join(
          platform.environment[_kFuchsiaSshConfig], 'ssh-keys', 'ssh_config'));
    } else if (platform.environment.containsKey(_kFuchsiaSshConfig)) {
      sshConfig = fs.file(platform.environment[_kFuchsiaSshConfig]);
    }
    return FuchsiaArtifacts(
      sshConfig: sshConfig,
      devFinder: fs.file(fs.path.join(tools, 'dev_finder')),
    );
  }

  static const String _kFuchsiaSshConfig = 'FUCHSIA_SSH_CONFIG';
  static const String _kFuchsiaBuildDir = 'FUCHSIA_BUILD_DIR';

  /// The location of the SSH configuration file used to interact with a
  /// Fuchsia device.
  final File sshConfig;

  /// The location of the dev finder tool used to locate connected
  /// Fuchsia devices.
  final File devFinder;
}
