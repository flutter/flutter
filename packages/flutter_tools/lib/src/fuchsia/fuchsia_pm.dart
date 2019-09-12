// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process.dart';
import '../convert.dart';
import '../globals.dart';

import 'fuchsia_sdk.dart';

/// This is a basic wrapper class for the Fuchsia SDK's `pm` tool.
class FuchsiaPM {
  /// Initializes the staging area at [buildPath] for creating the Fuchsia
  /// package for the app named [appName].
  ///
  /// When successful, this creates a file under [buildPath] at `meta/package`.
  ///
  /// NB: The [buildPath] should probably be e.g. `build/fuchsia/pkg`, and the
  /// [appName] should probably be the name of the app from the pubspec file.
  Future<bool> init(String buildPath, String appName) {
    return _runPMCommand(<String>[
      '-o',
      buildPath,
      '-n',
      appName,
      'init',
    ]);
  }

  /// Generates a new private key to be used to sign a Fuchsia package.
  ///
  /// [buildPath] should be the same [buildPath] passed to [init].
  Future<bool> genkey(String buildPath, String outKeyPath) {
    return _runPMCommand(<String>[
      '-o',
      buildPath,
      '-k',
      outKeyPath,
      'genkey',
    ]);
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
      String buildPath, String keyPath, String manifestPath) {
    return _runPMCommand(<String>[
      '-o',
      buildPath,
      '-k',
      keyPath,
      '-m',
      manifestPath,
      'build',
    ]);
  }

  /// Constructs a .far representation of the Fuchsia package.
  ///
  /// When successful, creates a file `app_name-0.far` under [buildPath], which
  /// is the Fuchsia package.
  ///
  /// [buildPath] should be the same path passed to [init], and [manfiestPath]
  /// should be the same manifest passed to [build].
  Future<bool> archive(String buildPath, String keyPath, String manifestPath) {
    return _runPMCommand(<String>[
      '-o',
      buildPath,
      '-k',
      keyPath,
      '-m',
      manifestPath,
      'archive',
    ]);
  }

  /// Initializes a new package repository at [repoPath] to be later served by
  /// the 'serve' command.
  Future<bool> newrepo(String repoPath) {
    return _runPMCommand(<String>[
      'newrepo',
      '-repo',
      repoPath,
    ]);
  }

  /// Spawns an http server in a new process for serving Fuchisa packages.
  ///
  /// The arguemnt [repoPath] should have previously been an arguemnt to
  /// [newrepo]. The [host] should be the host reported by
  /// [FuchsiaDevFinder.resolve], and [port] should be an unused port for the
  /// http server to bind.
  Future<Process> serve(String repoPath, String host, int port) async {
    if (fuchsiaArtifacts.pm == null) {
      throwToolExit('Fuchsia pm tool not found');
    }
    final List<String> command = <String>[
      fuchsiaArtifacts.pm.path,
      'serve',
      '-repo',
      repoPath,
      '-l',
      '$host:$port',
    ];
    final Process process = await processUtils.start(command);
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(printTrace);
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(printError);
    return process;
  }

  /// Publishes a Fuchsia package to a served package repository.
  ///
  /// For a package repo initialized with [newrepo] at [repoPath] and served
  /// by [serve], this call publishes the `far` package at [packagePath] to
  /// the repo such that it will be visible to devices connecting to the
  /// package server.
  Future<bool> publish(String repoPath, String packagePath) {
    return _runPMCommand(<String>[
      'publish',
      '-a',
      '-r',
      repoPath,
      '-f',
      packagePath,
    ]);
  }

  Future<bool> _runPMCommand(List<String> args) async {
    if (fuchsiaArtifacts.pm == null) {
      throwToolExit('Fuchsia pm tool not found');
    }
    final List<String> command = <String>[fuchsiaArtifacts.pm.path] + args;
    final RunResult result = await processUtils.run(command);
    return result.exitCode == 0;
  }
}

/// A class for running and retaining state for a Fuchsia package server.
///
/// [FuchsiaPackageServer] takes care of initializing the package repository,
/// spinning up the package server, publishing packages, and shutting down the
/// the server.
///
/// Example usage:
/// var server = FuchsiaPackageServer(
///     '/path/to/repo',
///     'server_name',
///     await FuchsiaDevFinder.resolve(deviceName),
///     await freshPort());
/// try {
///   await server.start();
///   await server.addPackage(farArchivePath);
///   ...
/// } finally {
///   server.stop();
/// }
class FuchsiaPackageServer {
  FuchsiaPackageServer(this._repo, this.name, this._host, this._port);

  final String _repo;
  final String _host;
  final int _port;

  Process _process;

  /// The url that can be used by the device to access this package server.
  String get url => 'http://$_host:$_port';

  // The name used to reference the server by fuchsia-pkg:// urls.
  final String name;

  /// Usees [FuchiaPM.newrepo] and [FuchsiaPM.serve] to spin up a new Fuchsia
  /// package server.
  ///
  /// Returns false if the repo could not be created or the server could not
  /// be spawned, and true otherwise.
  Future<bool> start() async {
    if (_process != null) {
      printError('$this already started!');
      return false;
    }
    // initialize a new repo.
    if (!await fuchsiaSdk.fuchsiaPM.newrepo(_repo)) {
      printError('Failed to create a new package server repo');
      return false;
    }
    _process = await fuchsiaSdk.fuchsiaPM.serve(_repo, _host, _port);
    // Put a completer on _process.exitCode to watch for error.
    unawaited(_process.exitCode.whenComplete(() {
      // If _process is null, then the server was stopped deliberately.
      if (_process != null) {
        printError('Error running Fuchsia pm tool "serve" command');
      }
    }));
    return true;
  }

  /// Forcefully stops the package server process by sending it SIGTERM.
  void stop() {
    if (_process != null) {
      _process.kill();
      _process = null;
    }
  }

  /// Uses [FuchsiaPM.publish] to add the Fuchsia 'far' package at
  /// [packagePath] to the package server.
  ///
  /// Returns true on success and false if the server wasn't started or the
  /// publish command failed.
  Future<bool> addPackage(File package) async {
    if (_process == null) {
      return false;
    }
    return await fuchsiaSdk.fuchsiaPM.publish(_repo, package.path);
  }

  @override
  String toString() {
    final String p = (_process == null) ? 'stopped' : 'running ${_process.pid}';
    return 'FuchsiaPackageServer at $_host:$_port ($p)';
  }
}
