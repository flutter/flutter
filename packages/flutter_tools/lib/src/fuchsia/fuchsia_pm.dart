// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/net.dart';
import '../base/process.dart';
import '../convert.dart';
import '../globals.dart' as globals;

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
  Future<bool> build(String buildPath, String manifestPath) {
    return _runPMCommand(<String>[
      '-o',
      buildPath,
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
  /// [buildPath] should be the same path passed to [init], and [manifestPath]
  /// should be the same manifest passed to [build].
  Future<bool> archive(String buildPath, String manifestPath) {
    return _runPMCommand(<String>[
      '-o',
      buildPath,
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

  /// Spawns an http server in a new process for serving Fuchsia packages.
  ///
  /// The argument [repoPath] should have previously been an argument to
  /// [newrepo]. The [host] should be the host reported by
  /// [FuchsiaFfx.resolve], and [port] should be an unused port for the
  /// http server to bind.
  Future<Process> serve(String repoPath, String host, int port) async {
    final File? pm = globals.fuchsiaArtifacts?.pm;
    if (pm == null) {
      throwToolExit('Fuchsia pm tool not found');
    }
    if (isIPv6Address(host.split('%').first)) {
      host = '[$host]';
    }
    final List<String> command = <String>[
      pm.path,
      'serve',
      '-repo',
      repoPath,
      '-l',
      '$host:$port',
      '-c',
      '2',
    ];
    final Process process = await globals.processUtils.start(command);
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(globals.printTrace);
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(globals.printError);
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
    final File? pm = globals.fuchsiaArtifacts?.pm;
    if (pm == null) {
      throwToolExit('Fuchsia pm tool not found');
    }
    final List<String> command = <String>[pm.path, ...args];
    final RunResult result = await globals.processUtils.run(command);
    return result.exitCode == 0;
  }
}

/// A class for running and retaining state for a Fuchsia package server.
///
/// [FuchsiaPackageServer] takes care of initializing the package repository,
/// spinning up the package server, publishing packages, and shutting down the
/// server.
///
/// Example usage:
/// var server = FuchsiaPackageServer(
///     '/path/to/repo',
///     'server_name',
///     await FuchsiaFfx.resolve(deviceName),
///     await freshPort());
/// try {
///   await server.start();
///   await server.addPackage(farArchivePath);
///   ...
/// } finally {
///   server.stop();
/// }
class FuchsiaPackageServer {
  factory FuchsiaPackageServer(
      String repo, String name, String host, int port) {
    return FuchsiaPackageServer._(repo, name, host, port);
  }

  FuchsiaPackageServer._(this._repo, this.name, this._host, this._port);

  static const String deviceHost = 'fuchsia.com';
  static const String toolHost = 'flutter-tool';

  final String _repo;
  final String _host;
  final int _port;

  Process? _process;

  // The name used to reference the server by fuchsia-pkg:// urls.
  final String name;

  int get port => _port;

  /// Uses [FuchsiaPM.newrepo] and [FuchsiaPM.serve] to spin up a new Fuchsia
  /// package server.
  ///
  /// Returns false if the repo could not be created or the server could not
  /// be spawned, and true otherwise.
  Future<bool> start() async {
    if (_process != null) {
      globals.printError('$this already started!');
      return false;
    }
    // initialize a new repo.
    final FuchsiaPM? fuchsiaPM = globals.fuchsiaSdk?.fuchsiaPM;
    if (fuchsiaPM == null || !await fuchsiaPM.newrepo(_repo)) {
      globals.printError('Failed to create a new package server repo');
      return false;
    }
    _process = await fuchsiaPM.serve(_repo, _host, _port);
    // Put a completer on _process.exitCode to watch for error.
    unawaited(_process?.exitCode.whenComplete(() {
      // If _process is null, then the server was stopped deliberately.
      if (_process != null) {
        globals.printError('Error running Fuchsia pm tool "serve" command');
      }
    }));
    return true;
  }

  /// Forcefully stops the package server process by sending it SIGTERM.
  void stop() {
    if (_process != null) {
      _process?.kill();
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
    return (await globals.fuchsiaSdk?.fuchsiaPM.publish(_repo, package.path)) ?? false;
  }

  @override
  String toString() {
    final String p = (_process == null) ? 'stopped' : 'running ${_process?.pid}';
    return 'FuchsiaPackageServer at $_host:$_port ($p)';
  }
}
