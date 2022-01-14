// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/process.dart';

import 'fuchsia_device.dart';
import 'fuchsia_pm.dart';

/// Simple wrapper for interacting with the 'pkgctl' tool running on the
/// Fuchsia device.
class FuchsiaPkgctl {
  /// Teaches pkgctl on [device] about the Fuchsia package server
  Future<bool> addRepo(
      FuchsiaDevice device, FuchsiaPackageServer server) async {
    final String localIp = await device.hostAddress;
    final String configUrl = 'http://[$localIp]:${server.port}/config.json';
    final RunResult result =
        await device.shell('pkgctl repo add url -n ${server.name} $configUrl');
    return result.exitCode == 0;
  }

  /// Instructs pkgctl instance running on [device] to forget about the
  /// Fuchsia package server with the given name
  /// pkgctl repo rm fuchsia-pkg://mycorp.com
  Future<bool> rmRepo(FuchsiaDevice device, FuchsiaPackageServer server) async {
    final RunResult result = await device.shell(
      'pkgctl repo rm fuchsia-pkg://${server.name}',
    );
    return result.exitCode == 0;
  }

  /// Instructs the pkgctl instance running on [device] to prefetch the package
  /// with the given [packageUrl] hosted in the given [serverName].
  Future<bool> resolve(
    FuchsiaDevice device,
    String serverName,
    String packageName,
  ) async {
    final String packageUrl = 'fuchsia-pkg://$serverName/$packageName';
    final RunResult result = await device.shell('pkgctl resolve $packageUrl');
    return result.exitCode == 0;
  }
}
