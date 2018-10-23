// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../fuchsia/fuchsia_device.dart';
import '../vmservice.dart';

/// The [FuchsiaSdk] instance.
FuchsiaSdk get fuchsiaSdk => context[FuchsiaSdk];

/// The Fuchsia SDK shell commands.
///
/// This workflow assumes development within the fuchsia source tree,
/// including a working fx command-line tool in the user's PATH.
class FuchsiaSdk {
  /// The location of the SSH configuration file used to interact with a
  /// fuchsia device.
  ///
  /// Requires the env variable `build-dir` to be set.
  File get sshConfig {
    if (_sshConfig == null) {
      final String buildDirectory = platform.environment['build-dir'];
      _sshConfig = fs.file('$buildDirectory/ssh-keys/ssh_config');
    }
    return _sshConfig;
  }
  File _sshConfig;

  /// Invokes the `netaddr` command.
  ///
  /// This returns the network address of an attached fuchsia device. Does
  /// not currently support multiple attached devices.
  ///
  /// Example output:
  ///     $ fx netaddr --fuchsia -d liliac-shore-only-last
  ///     > fe80::9aaa:fcff:fe60:d3af%eth1
  Future<String> netaddr(String name) async {
    try {
      final RunResult process = await runAsync(<String>['fx', 'netaddr', '--fuchsia', '-d', name]);
      return process.stdout;
    } on ArgumentError catch (exception) {
      throwToolExit('$exception');
    }
    return null;
  }

  /// Invokes the `netls` command.
  ///
  /// This lists attached fuchsia devices with their name and address. Does
  /// not currently support multiple attached devices.
  ///
  /// Example output:
  ///     $ fx netls --nowait
  ///     > device liliac-shore-only-last (fe80::82e4:da4d:fe81:227d/3)
  Future<String> netls() async {
    try {
      final RunResult process = await runAsync(
        <String>['fx', 'netls', '--nowait']);
      return process.stdout;
    } on ArgumentError catch (exception) {
      throwToolExit('$exception');
    }
    return null;
  }

  /// Run `command` on the Fuchsia `device`.
  Future<String> run(FuchsiaDevice device, String command) async {
    final RunResult result = await runAsync(<String>[
      'ssh', '-F', fuchsiaSdk.sshConfig.absolute.path, device.id, command]);
    if (result.exitCode != 0) {
      throwToolExit('Command failed: $command\nstdout: ${result.stdout}\nstderr: ${result.stderr}');
      return null;
    }
    return result.stdout;
  }

  /// Finds the first port running a VM matching `isolateName` on `device`.
  ///
  /// TODO(jonahwilliams): replacing this with the hub will require an update
  /// to the flutter_runner.
  Future<int> servicePort(FuchsiaDevice device, String isolateName) async {
    final String lsOutput = await run(device, 'ls /tmp/dart.services');
    final List<int> ports =  parseFuchsiaDartPortOutput(lsOutput);

    for (int port in ports) {
      final String addr = 'http://${InternetAddress.loopbackIPv4.address}:$port';
      final Uri uri = Uri.parse(addr);
      final VMService vmService = await VMService.connect(uri);
      await vmService.getVM();
      await vmService.refreshViews();
      for (FlutterView flutterView in vmService.vm.views) {
        if (flutterView.uiIsolate == null) {
          continue;
        }
        final Uri address = flutterView.owner.vmService.httpAddress;
        if (flutterView.uiIsolate.name.contains(isolateName)) {
          return address.port;
        }
      }
    }
    throwToolExit('No ports found running $isolateName');
    return null;
  }
}

/// Parses output from `dart.services` output on a fuchsia device.
///
/// Example output:
///     $ ls dart.services
///     > ...
@visibleForTesting
List<int> parseFuchsiaDartPortOutput(String text) {
  final List<int> ports = <int>[];
  if (text == null)
    return ports;
  for (String line in text.split('\n')) {
    final String trimmed = line.trim();
    final int lastSpace = trimmed.lastIndexOf(' ');
    final String lastWord = trimmed.substring(lastSpace + 1);
    if ((lastWord != '.') && (lastWord != '..')) {
      final int value = int.tryParse(lastWord);
      if (value != null) {
        ports.add(value);
      }
    }
  }
  return ports;
}
