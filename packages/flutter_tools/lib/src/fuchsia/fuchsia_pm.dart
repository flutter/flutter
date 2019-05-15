// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/io.dart';
import '../base/process_manager.dart';
import '../globals.dart';

import 'fuchsia_sdk.dart';

/// The [FuchsiaPM] instance.
FuchsiaPM get fuchsiaPM => context.get<FuchsiaPM>();

/// This is a basic wrapper class for the Fuchsia SDK's `pm` tool.
class FuchsiaPM {
  /// Initializes the staging area at [buildPath] for creating the Fuchsia
  /// package for the app named [appName].
  ///
  /// When successful, this creates a file under [buildPath] at `meta/package`.
  ///
  /// NB: The [buildPath] should probably be e.g. `build/fuchsia/pkg`, and the
  /// [appName] should probably be the name of the app from the pubspec file.
  Future<bool> init(String buildPath, String appName) async {
    final List<String> command = <String>[
      fuchsiaArtifacts.pm.path,
      '-o',
      buildPath,
      '-n',
      appName,
      'init',
    ];
    printTrace("Running: '${command.join(' ')}'");
    final ProcessResult result = await processManager.run(command);
    if (result.exitCode != 0) {
      printError('Error initializing Fuchsia package for $appName: ');
      printError(result.stdout);
      printError(result.stderr);
      return false;
    }
    return true;
  }

  /// Generates a new private key to be used to sign a Fuchsia package.
  ///
  /// [buildPath] should be the same [buildPath] passed to [init].
  Future<bool> genkey(String buildPath, String outKeyPath) async {
    final List<String> command = <String>[
      fuchsiaArtifacts.pm.path,
      '-o',
      buildPath,
      '-k',
      outKeyPath,
      'genkey',
    ];
    printTrace("Running: '${command.join(' ')}'");
    final ProcessResult result = await processManager.run(command);
    if (result.exitCode != 0) {
      printError('Error generating key for Fuchsia package: ');
      printError(result.stdout);
      printError(result.stderr);
      return false;
    }
    return true;
  }

  /// Updates, signs, and seals a Fuchsia package.
  ///
  /// [buildPath] should be the same [buildPath] passed to [init].
  /// [manifestPath] must be a file containing lines formatted as follows:
  ///
  ///     data/path/to/file/in/the/package=/path/to/file/on/the/host
  ///
  /// which describe the contents of the Fuchsia package. It must also contain
  /// two other entries:
  ///
  ///     meta/$APPNAME.cmx=/path/to/cmx/on/the/host/$APPNAME.cmx
  ///     meta/package=/path/to/package/file/from/init/package
  ///
  /// where $APPNAME is the same [appName] passed to [init], and meta/package
  /// is set up to be the file `meta/package` created by [init].
  Future<bool> build(
      String buildPath, String keyPath, String manifestPath) async {
    final List<String> command = <String>[
      fuchsiaArtifacts.pm.path,
      '-o',
      buildPath,
      '-k',
      keyPath,
      '-m',
      manifestPath,
      'build',
    ];
    printTrace("Running: '${command.join(' ')}'");
    final ProcessResult result = await processManager.run(command);
    if (result.exitCode != 0) {
      printError('Error building Fuchsia package: ');
      printError(result.stdout);
      printError(result.stderr);
      return false;
    }
    return true;
  }

  /// Constructs a .far representation of the Fuchsia package.
  ///
  /// When successful, creates a file `app_name-0.far` under [buildPath], which
  /// is the Fuchsia package.
  ///
  /// [buildPath] should be the same path passed to [init], and [manfiestPath]
  /// should be the same manifest passed to [build].
  Future<bool> archive(
      String buildPath, String keyPath, String manifestPath) async {
    final List<String> command = <String>[
      fuchsiaArtifacts.pm.path,
      '-o',
      buildPath,
      '-k',
      keyPath,
      '-m',
      manifestPath,
      'archive',
    ];
    printTrace("Running: '${command.join(' ')}'");
    final ProcessResult result = await processManager.run(command);
    if (result.exitCode != 0) {
      printError('Error archiving Fuchsia package: ');
      printError(result.stdout);
      printError(result.stderr);
      return false;
    }
    return true;
  }
}
