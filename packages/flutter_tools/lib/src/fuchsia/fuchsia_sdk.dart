// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/io.dart';
import '../base/platform.dart';
import '../convert.dart';
import '../features.dart' show featureFlags;
import '../globals.dart' as globals;

import 'fuchsia_ffx.dart';
import 'fuchsia_kernel_compiler.dart';
import 'fuchsia_pm.dart';

/// Returns [true] if the current platform supports Fuchsia targets.
bool isFuchsiaSupportedPlatform(Platform platform) {
  return featureFlags.isFuchsiaEnabled && (platform.isLinux || platform.isMacOS);
}

/// The Fuchsia SDK shell commands.
///
/// This workflow assumes development within the fuchsia source tree,
/// including a working fx command-line tool in the user's PATH.
class FuchsiaSdk {
  /// Interface to the 'pm' tool.
  late final FuchsiaPM fuchsiaPM = FuchsiaPM();

  /// Interface to the 'kernel_compiler' tool.
  late final FuchsiaKernelCompiler fuchsiaKernelCompiler = FuchsiaKernelCompiler();

  /// Interface to the 'ffx' tool.
  late final FuchsiaFfx fuchsiaFfx = FuchsiaFfx();

  /// Returns any attached devices is a newline-denominated String.
  ///
  /// Example output: abcd::abcd:abc:abcd:abcd%qemu scare-cable-skip-joy
  Future<String?> listDevices({Duration? timeout}) async {
    final File? ffx = globals.fuchsiaArtifacts?.ffx;
    if (ffx == null || !ffx.existsSync()) {
      return null;
    }
    final List<String>? devices = await fuchsiaFfx.list(timeout: timeout);
    if (devices == null) {
      return null;
    }
    return devices.isNotEmpty ? devices.join('\n') : null;
  }

  /// Returns the fuchsia system logs for an attached device where
  /// [id] is the IP address of the device.
  Stream<String>? syslogs(String id) {
    Process? process;
    try {
      final StreamController<String> controller = StreamController<String>(onCancel: () {
        process?.kill();
      });
      final File? sshConfig = globals.fuchsiaArtifacts?.sshConfig;
      if (sshConfig == null || !sshConfig.existsSync()) {
        globals.printError('Cannot read device logs: No ssh config.');
        globals.printError('Have you set FUCHSIA_SSH_CONFIG or FUCHSIA_BUILD_DIR?');
        return null;
      }
      const String remoteCommand = 'log_listener --clock Local';
      final List<String> cmd = <String>[
        'ssh',
        '-F',
        sshConfig.absolute.path,
        id, // The device's IP.
        remoteCommand,
      ];
      globals.processManager.start(cmd).then((Process newProcess) {
        if (controller.isClosed) {
          return;
        }
        process = newProcess;
        process?.exitCode.whenComplete(controller.close);
        controller.addStream(process!.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter()));
      });
      return controller.stream;
    } on Exception catch (exception) {
      globals.printTrace('$exception');
    }
    return const Stream<String>.empty();
  }
}

/// Fuchsia-specific artifacts used to interact with a device.
class FuchsiaArtifacts {
  /// Creates a new [FuchsiaArtifacts].
  FuchsiaArtifacts({
    this.sshConfig,
    this.ffx,
    this.pm,
  });

  /// Creates a new [FuchsiaArtifacts] using the cached Fuchsia SDK.
  ///
  /// Finds tools under bin/cache/artifacts/fuchsia/tools.
  /// Queries environment variables (first FUCHSIA_BUILD_DIR, then
  /// FUCHSIA_SSH_CONFIG) to find the ssh configuration needed to talk to
  /// a device.
  factory FuchsiaArtifacts.find() {
    if (!isFuchsiaSupportedPlatform(globals.platform)) {
      // Don't try to find the artifacts on platforms that are not supported.
      return FuchsiaArtifacts();
    }
    // If FUCHSIA_BUILD_DIR is defined, then look for the ssh_config dir
    // relative to it. Next, if FUCHSIA_SSH_CONFIG is defined, then use it.
    // TODO(zanderso): Consider passing the ssh config path in with a flag.
    File? sshConfig;
    if (globals.platform.environment.containsKey(_kFuchsiaBuildDir)) {
      sshConfig = globals.fs.file(globals.fs.path.join(
          globals.platform.environment[_kFuchsiaBuildDir]!, 'ssh-keys', 'ssh_config'));
    } else if (globals.platform.environment.containsKey(_kFuchsiaSshConfig)) {
      sshConfig = globals.fs.file(globals.platform.environment[_kFuchsiaSshConfig]);
    }

    final String fuchsia = globals.cache.getArtifactDirectory('fuchsia').path;
    final String tools = globals.fs.path.join(fuchsia, 'tools');
    final File ffx = globals.fs.file(globals.fs.path.join(tools, 'x64/ffx'));
    final File pm = globals.fs.file(globals.fs.path.join(tools, 'pm'));

    return FuchsiaArtifacts(
      sshConfig: sshConfig,
      ffx: ffx.existsSync() ? ffx : null,
      pm: pm.existsSync() ? pm : null,
    );
  }

  static const String _kFuchsiaSshConfig = 'FUCHSIA_SSH_CONFIG';
  static const String _kFuchsiaBuildDir = 'FUCHSIA_BUILD_DIR';

  /// The location of the SSH configuration file used to interact with a
  /// Fuchsia device.
  final File? sshConfig;

  /// The location of the ffx tool used to locate connected
  /// Fuchsia devices.
  final File? ffx;

  /// The pm tool.
  final File? pm;

  /// Returns true if the [sshConfig] file is not null and exists.
  bool get hasSshConfig => sshConfig != null && sshConfig!.existsSync();
}
