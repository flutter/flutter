// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart';

import 'fuchsia_dev_finder.dart';
import 'fuchsia_kernel_compiler.dart';
import 'fuchsia_pm.dart';

/// The [FuchsiaSdk] instance.
FuchsiaSdk get fuchsiaSdk => context.get<FuchsiaSdk>();

/// The [FuchsiaArtifacts] instance.
FuchsiaArtifacts get fuchsiaArtifacts => context.get<FuchsiaArtifacts>();

/// The Fuchsia SDK shell commands.
///
/// This workflow assumes development within the fuchsia source tree,
/// including a working fx command-line tool in the user's PATH.
class FuchsiaSdk {
  /// Interface to the 'pm' tool.
  FuchsiaPM get fuchsiaPM => _fuchsiaPM ??= FuchsiaPM();
  FuchsiaPM _fuchsiaPM;

  /// Interface to the 'dev_finder' tool.
  FuchsiaDevFinder _fuchsiaDevFinder;
  FuchsiaDevFinder get fuchsiaDevFinder =>
      _fuchsiaDevFinder ??= FuchsiaDevFinder();

  /// Interface to the 'kernel_compiler' tool.
  FuchsiaKernelCompiler _fuchsiaKernelCompiler;
  FuchsiaKernelCompiler get fuchsiaKernelCompiler =>
      _fuchsiaKernelCompiler ??= FuchsiaKernelCompiler();

  /// Example output:
  ///    $ dev_finder list -full
  ///    > 192.168.42.56 paper-pulp-bush-angel
  Future<String> listDevices() async {
    if (fuchsiaArtifacts.devFinder == null ||
        !fuchsiaArtifacts.devFinder.existsSync()) {
      return null;
    }
    final List<String> devices = await fuchsiaDevFinder.list();
    if (devices == null) {
      return null;
    }
    return devices.isNotEmpty ? devices[0] : null;
  }

  /// Returns the fuchsia system logs for an attached device.
  Stream<String> syslogs(String id) {
    Process process;
    try {
      final StreamController<String> controller =
          StreamController<String>(onCancel: () {
        process.kill();
      });
      if (fuchsiaArtifacts.sshConfig == null ||
          !fuchsiaArtifacts.sshConfig.existsSync()) {
        printError('Cannot read device logs: No ssh config.');
        printError('Have you set FUCHSIA_SSH_CONFIG or FUCHSIA_BUILD_DIR?');
        return null;
      }
      const String remoteCommand = 'log_listener --clock Local';
      final List<String> cmd = <String>[
        'ssh',
        '-F',
        fuchsiaArtifacts.sshConfig.absolute.path,
        id,
        remoteCommand,
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
    return const Stream<String>.empty();
  }
}

/// Fuchsia-specific artifacts used to interact with a device.
class FuchsiaArtifacts {
  /// Creates a new [FuchsiaArtifacts].
  FuchsiaArtifacts({
    this.sshConfig,
    this.devFinder,
    this.platformKernelDill,
    this.flutterPatchedSdk,
    this.kernelCompiler,
    this.pm,
  });

  /// Creates a new [FuchsiaArtifacts] using the cached Fuchsia SDK.
  ///
  /// Finds tools under bin/cache/artifacts/fuchsia/tools.
  /// Queries environment variables (first FUCHSIA_BUILD_DIR, then
  /// FUCHSIA_SSH_CONFIG) to find the ssh configuration needed to talk to
  /// a device.
  factory FuchsiaArtifacts.find() {
    if (!platform.isLinux && !platform.isMacOS) {
      // Don't try to find the artifacts on platforms that are not supported.
      return FuchsiaArtifacts();
    }
    final String fuchsia = Cache.instance.getArtifactDirectory('fuchsia').path;
    final String tools = fs.path.join(fuchsia, 'tools');
    final String dartPrebuilts = fs.path.join(tools, 'dart_prebuilts');

    final File devFinder = fs.file(fs.path.join(tools, 'dev_finder'));
    final File platformDill = fs.file(fs.path.join(
          dartPrebuilts, 'flutter_runner', 'platform_strong.dill'));
    final File patchedSdk = fs.file(fs.path.join(
          dartPrebuilts, 'flutter_runner'));
    final File kernelCompiler = fs.file(fs.path.join(
          dartPrebuilts, 'kernel_compiler.snapshot'));
    final File pm = fs.file(fs.path.join(tools, 'pm'));

    // If FUCHSIA_BUILD_DIR is defined, then look for the ssh_config dir
    // relative to it. Next, if FUCHSIA_SSH_CONFIG is defined, then use it.
    // TODO(zra): Consider passing the ssh config path in with a flag.
    File sshConfig;
    if (platform.environment.containsKey(_kFuchsiaBuildDir)) {
      sshConfig = fs.file(fs.path.join(
          platform.environment[_kFuchsiaBuildDir], 'ssh-keys', 'ssh_config'));
    } else if (platform.environment.containsKey(_kFuchsiaSshConfig)) {
      sshConfig = fs.file(platform.environment[_kFuchsiaSshConfig]);
    }
    return FuchsiaArtifacts(
      sshConfig: sshConfig,
      devFinder: devFinder.existsSync() ? devFinder : null,
      platformKernelDill: platformDill.existsSync() ? platformDill : null,
      flutterPatchedSdk: patchedSdk.existsSync() ? patchedSdk : null,
      kernelCompiler: kernelCompiler.existsSync() ? kernelCompiler : null,
      pm: pm.existsSync() ? pm : null,
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

  /// The location of the Fuchsia-specific platform dill.
  final File platformKernelDill;

  /// The directory containing [platformKernelDill].
  final File flutterPatchedSdk;

  /// The snapshot of the Fuchsia kernel compiler.
  final File kernelCompiler;

  /// The pm tool.
  final File pm;
}
