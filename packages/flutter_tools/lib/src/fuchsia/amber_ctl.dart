// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import '../base/process.dart';

import 'fuchsia_device.dart';
import 'fuchsia_pm.dart';

// usage: amber_ctl <command> [opts]
// Commands
//     get_up        - get an update for a package
//       Options
//         -n:      name of the package
//         -v:      version of the package to retrieve, if none is supplied any
//                  package instance could match
//         -m:      merkle root of the package to retrieve, if none is supplied
//                  any package instance could match
//
//     get_blob      - get the specified content blob
//         -i: content ID of the blob
//
//     add_src       - add a source to the list we can use
//         -n: name of the update source (optional, with URL)
//         -f: file path or url to a source config file
//         -h: SHA256 hash of source config file (optional, with URL)
//         -x: do not disable other active sources (if the provided source is
//             enabled)
//
//     add_repo_cfg  - add a repository config to the set of known repositories,
//                     using a source config
//         -n: name of the update source (optional, with URL)
//         -f: file path or url to a source config file
//         -h: SHA256 hash of source config file (optional, with URL)
//
//     rm_src        - remove a source, if it exists
//         -n: name of the update source
//
//     list_srcs     - list the set of sources we can use
//
//     enable_src
//         -n: name of the update source
//         -x: do not disable other active sources
//
//     disable_src
//         -n: name of the update source
//
//     system_update - check for, download, and apply any available system
//                     update
//
//     gc - trigger a garbage collection
//
//     print_state - print go routine state of amber process

/// Simple wrapper for interacting with the 'amber_ctl' tool running on the
/// Fuchsia device.
class FuchsiaAmberCtl {
  /// Teaches the amber instance running on [device] about the Fuchsia package
  /// server accessible via [configUrl].
  Future<bool> addSrc(FuchsiaDevice device, FuchsiaPackageServer server) async {
    final String localIp = await device.hostAddress;
    final String configUrl = 'http://[$localIp]:${server.port}/config.json';
    final RunResult result = await device.shell(
      'amber_ctl add_src -x -f $configUrl',
    );
    return result.exitCode == 0;
  }

  /// Instructs the amber instance running on [device] to forget about the
  /// Fuchsia package server that it was accessing via [serverUrl].
  Future<bool> rmSrc(FuchsiaDevice device, FuchsiaPackageServer server) async {
    final String localIp = await device.hostAddress;
    final RunResult result = await device.shell(
      'amber_ctl rm_src -n http://[$localIp]:${server.port}/',
    );
    return result.exitCode == 0;
  }

  /// Instructs the amber instance running on [device] to prefetch the package
  /// [packageName].
  Future<bool> getUp(FuchsiaDevice device, String packageName) async {
    final RunResult result = await device.shell(
      'amber_ctl get_up -n $packageName',
    );
    return result.exitCode == 0;
  }

  /// Converts the amber source config created when [server] was set up to a
  /// pkg_resolver repo config, and teaches the pkg_resolver instance running
  /// on [device] about the [FuchsiaPackageServer].
  Future<bool> addRepoCfg(FuchsiaDevice device, FuchsiaPackageServer server) async {
    final String localIp = await device.hostAddress;
    final String configUrl = 'http://[$localIp]:${server.port}/config.json';
    final RunResult result = await device.shell(
      'amber_ctl add_repo_cfg -n ${server.name} -f $configUrl',
    );
    return result.exitCode == 0;
  }

  /// Instructs the pkg_resolver instance running on [device] to prefetch the
  /// package [packageName].
  Future<bool> pkgCtlResolve(
    FuchsiaDevice device,
    FuchsiaPackageServer server,
    String packageName,
  ) async {
    final String packageUrl = 'fuchsia-pkg://${server.name}/$packageName';
    final RunResult result = await device.shell('pkgctl resolve $packageUrl');
    return result.exitCode == 0;
  }

  /// Instructs the pkg_resolver instance running on [device] to forget about
  /// the Fuchsia package server that it was accessing via [serverUrl].
  Future<bool> pkgCtlRepoRemove(
    FuchsiaDevice device,
    FuchsiaPackageServer server,
  ) async {
    final String repoUrl = 'fuchsia-pkg://${server.name}';
    final RunResult result = await device.shell('pkgctl repo rm $repoUrl');
    return result.exitCode == 0;
  }
}
