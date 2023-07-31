// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:path/path.dart' as p;

import 'shared.dart';

/// Wrapper around the incremental frontend server compiler.
class FrontendServerClient {
  final String _entrypoint;
  final Process _feServer;
  final StreamQueue<String> _feServerStdoutLines;
  final bool _verbose;

  _ClientState _state;

  FrontendServerClient._(
      this._entrypoint, this._feServer, this._feServerStdoutLines,
      {bool? verbose})
      : _verbose = verbose ?? false,
        _state = _ClientState.waitingForFirstCompile {
    _feServer.stderr.transform(utf8.decoder).listen(stderr.write);
  }

  /// Starts the frontend server.
  ///
  /// Most arguments directly mirror the command line arguments for the
  /// frontend_server (see `pkg/frontend_server/lib/frontend_server.dart` in
  /// the sdk). Options are exposed on an as-needed basis.
  ///
  /// The [entrypoint] and [packagesJson] may be a relative path or any uri
  /// supported by the frontend server.
  ///
  /// The [outputDillPath] determines where the primary output should be, and
  /// some targets may output additional files based on that file name (by
  /// adding file extensions for instance).
  static Future<FrontendServerClient> start(
    String entrypoint,
    String outputDillPath,
    String platformKernel, {
    String dartdevcModuleFormat = 'amd',
    bool debug = false,
    List<String>? enabledExperiments,
    bool enableHttpUris = false,
    List<String> fileSystemRoots = const [], // For `fileSystemScheme` uris,
    String fileSystemScheme =
        'org-dartlang-root', // Custom scheme for virtual `fileSystemRoots`.
    String? frontendServerPath, // Defaults to the snapshot in the sdk.
    String packagesJson = '.dart_tool/package_config.json',
    String? sdkRoot, // Defaults to the current SDK root.
    String target = 'vm', // The kernel target type.
    bool verbose = false, // Verbose logs, including server/client messages
    bool printIncrementalDependencies = true,
  }) async {
    var feServer = await Process.start(Platform.resolvedExecutable, [
      if (debug) '--observe',
      frontendServerPath ?? _feServerPath,
      '--sdk-root',
      sdkRoot ?? sdkDir,
      '--platform=$platformKernel',
      '--target=$target',
      if (target == 'dartdevc')
        '--dartdevc-module-format=$dartdevcModuleFormat',
      for (var root in fileSystemRoots) '--filesystem-root=$root',
      '--filesystem-scheme',
      fileSystemScheme,
      '--output-dill',
      outputDillPath,
      '--packages=$packagesJson',
      if (enableHttpUris) '--enable-http-uris',
      '--incremental',
      if (verbose) '--verbose',
      if (!printIncrementalDependencies) '--no-print-incremental-dependencies',
      if (enabledExperiments != null)
        for (var experiment in enabledExperiments)
          '--enable-experiment=$experiment',
    ]);
    var feServerStdoutLines = StreamQueue(feServer.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter()));

    // The frontend_server doesn't appear to recursively create files, so we
    //  need to make sure the output dir already exists.
    var outputDir = Directory(p.dirname(outputDillPath));
    if (!await outputDir.exists()) await outputDir.create();

    return FrontendServerClient._(
      entrypoint,
      feServer,
      feServerStdoutLines,
      verbose: verbose,
    );
  }

  /// Compiles [_entrypoint], using an incremental recompile if possible.
  ///
  /// [invalidatedUris] must not be null for all but the very first compile.
  ///
  /// The frontend server _does not_ do any of its own invalidation.
  Future<CompileResult?> compile([List<Uri>? invalidatedUris]) async {
    String action;
    switch (_state) {
      case _ClientState.waitingForFirstCompile:
        action = 'compile';
        break;
      case _ClientState.waitingForRecompile:
        action = 'recompile';
        break;
      case _ClientState.waitingForAcceptOrReject:
        throw StateError(
            'Previous `CompileResult` must be accepted or rejected by '
            'calling `accept` or `reject`.');
      case _ClientState.compiling:
        throw StateError(
            'App is already being compiled, you must wait for that to '
            'complete and `accept` or `reject` the result before compiling '
            'again.');
      case _ClientState.rejecting:
        throw StateError('Still waiting for previous `reject` call to finish. '
            'You must await that before compiling again.');
    }
    _state = _ClientState.compiling;

    try {
      var command = StringBuffer('$action $_entrypoint');
      if (action == 'recompile') {
        if (invalidatedUris == null || invalidatedUris.isEmpty) {
          throw StateError(
              'Subsequent compile invocations must provide a non-empty list '
              'of invalidated uris.');
        }
        var boundaryKey = generateUuidV4();
        command.writeln(' $boundaryKey');
        for (var uri in invalidatedUris) {
          command.writeln('$uri');
        }
        command.write(boundaryKey);
      }

      _sendCommand(command.toString());
      var state = _CompileState.started;
      late String feBoundaryKey;
      var newSources = <Uri>{};
      var removedSources = <Uri>{};
      var compilerOutputLines = <String>[];
      var errorCount = 0;
      String? outputDillPath;
      while (
          state != _CompileState.done && await _feServerStdoutLines.hasNext) {
        var line = await _nextInputLine();
        switch (state) {
          case _CompileState.started:
            assert(line.startsWith('result'));
            feBoundaryKey = line.substring(line.indexOf(' ') + 1);
            state = _CompileState.waitingForKey;
            continue;
          case _CompileState.waitingForKey:
            if (line == feBoundaryKey) {
              state = _CompileState.gettingSourceDiffs;
            } else {
              compilerOutputLines.add(line);
            }
            continue;
          case _CompileState.gettingSourceDiffs:
            if (line.startsWith(feBoundaryKey)) {
              state = _CompileState.done;
              var parts = line.split(' ');
              outputDillPath = parts.getRange(1, parts.length - 1).join(' ');
              errorCount = int.parse(parts.last);
              continue;
            }
            var diffUri = Uri.parse(line.substring(1));
            if (line.startsWith('+')) {
              newSources.add(diffUri);
            } else if (line.startsWith('-')) {
              removedSources.add(diffUri);
            } else {
              throw StateError(
                  'unrecognized diff line, should start with a + or - but got: $line');
            }
            continue;
          case _CompileState.done:
            throw StateError('Unreachable');
        }
      }

      if (outputDillPath == null) {
        return null;
      }

      return CompileResult._(
          dillOutput: outputDillPath,
          errorCount: errorCount,
          newSources: newSources,
          removedSources: removedSources,
          compilerOutputLines: compilerOutputLines);
    } finally {
      _state = _ClientState.waitingForAcceptOrReject;
    }
  }

  /// TODO: Document
  Future<CompileResult> compileExpression({
    required String expression,
    required List<String> definitions,
    required bool isStatic,
    required String klass,
    required String libraryUri,
    required List<String> typeDefinitions,
  }) =>
      throw UnimplementedError();

  /// TODO: Document
  Future<CompileResult> compileExpressionToJs({
    required String expression,
    required int column,
    required Map<String, String> jsFrameValues,
    required Map<String, String> jsModules,
    required String libraryUri,
    required int line,
    required String moduleName,
  }) =>
      throw UnimplementedError();

  /// Should be invoked when results of compilation are accepted by the client.
  ///
  /// Either [accept] or [reject] should be called after every [compile] call.
  void accept() {
    if (_state != _ClientState.waitingForAcceptOrReject) {
      throw StateError(
          'Called `accept` but there was no previous compile to accept.');
    }
    _sendCommand('accept');
    _state = _ClientState.waitingForRecompile;
  }

  /// Should be invoked when results of compilation are rejected by the client.
  ///
  /// Either [accept] or [reject] should be called after every [compile] call.
  ///
  /// The result of this call must be awaited before a new [compile] can be
  /// done.
  Future<void> reject() async {
    if (_state != _ClientState.waitingForAcceptOrReject) {
      throw StateError(
          'Called `reject` but there was no previous compile to reject.');
    }
    _state = _ClientState.rejecting;
    _sendCommand('reject');
    late String boundaryKey;
    var rejectState = _RejectState.started;
    while (rejectState != _RejectState.done &&
        await _feServerStdoutLines.hasNext) {
      var line = await _nextInputLine();
      switch (rejectState) {
        case _RejectState.started:
          if (!line.startsWith('result')) {
            throw StateError(
                'Expected a line like `result <boundary-key>` after a `reject` '
                'command, but got:\n$line');
          }
          boundaryKey = line.split(' ').last;
          rejectState = _RejectState.waitingForKey;
          continue;
        case _RejectState.waitingForKey:
          if (line != boundaryKey) {
            throw StateError('Expected exactly `$boundaryKey` but got:\n$line');
          }
          rejectState = _RejectState.done;
          continue;
        case _RejectState.done:
          throw StateError('Unreachable');
      }
    }
    _state = _ClientState.waitingForRecompile;
  }

  /// Should be invoked when frontend server compiler should forget what was
  /// accepted previously so that next call to [compile] produces complete
  /// kernel file.
  void reset() {
    if (_state == _ClientState.compiling) {
      throw StateError(
          'Called `reset` during an active compile, you must wait for that to '
          'complete first.');
    }
    _sendCommand('reset');
    _state = _ClientState.waitingForRecompile;
  }

  /// Stop the service gracefully (using the shutdown command)
  Future<int> shutdown() async {
    _sendCommand('quit');
    var timer = Timer(const Duration(seconds: 1), _feServer.kill);
    var exitCode = await _feServer.exitCode;
    timer.cancel();
    await _feServerStdoutLines.cancel();
    return exitCode;
  }

  /// Kills the server forcefully by calling `kill` on the process, and
  /// returns the result.
  bool kill({ProcessSignal processSignal = ProcessSignal.sigterm}) {
    _feServerStdoutLines.cancel();
    return _feServer.kill(processSignal);
  }

  /// Sends [command] to the [_feServer] via stdin, and logs it if [_verbose].
  void _sendCommand(String command) {
    if (_verbose) {
      var lines = const LineSplitter().convert(command);
      for (var line in lines) {
        print('>> $line');
      }
    }
    _feServer.stdin.writeln(command);
  }

  /// Reads a line from [_feServerStdoutLines] and logs it if [_verbose].
  Future<String> _nextInputLine() async {
    var line = await _feServerStdoutLines.next;
    if (_verbose) print('<< $line');
    return line;
  }
}

/// The result of a compile call.
class CompileResult {
  const CompileResult._(
      {required this.dillOutput,
      required this.compilerOutputLines,
      required this.errorCount,
      required this.newSources,
      required this.removedSources});

  /// The produced dill output file, this will either be a full dill file or an
  /// incremental dill file.
  final String dillOutput;

  /// All output from the compiler, typically this would contain errors or
  /// warnings.
  final Iterable<String> compilerOutputLines;

  /// The total count of errors, details should appear in
  /// [compilerOutputLines].
  final int errorCount;

  /// A single file containing all source maps for all JS outputs.
  ///
  /// Read [jsManifestOutput] for file offsets for each sourcemap.
  String get jsSourceMapsOutput => '$dillOutput.map';

  /// A single file containing all JS outputs.
  ///
  /// Read [jsManifestOutput] for file offsets for each source.
  String get jsSourcesOutput => '$dillOutput.sources';

  /// A JSON manifest containing offsets for the sources and source maps in
  /// the [jsSourcesOutput] and [jsSourceMapsOutput] files.
  String get jsManifestOutput => '$dillOutput.json';

  /// All the transitive source dependencies that were added as a part of this
  /// compile.
  final Iterable<Uri> newSources;

  /// All the transitive source dependencies that were removed as a part of
  /// this compile.
  final Iterable<Uri> removedSources;
}

/// Internal states for the client.
enum _ClientState {
  compiling,
  rejecting,
  waitingForAcceptOrReject,
  waitingForFirstCompile,
  waitingForRecompile,
}

/// Frontend server interaction states for a `compile` call.
enum _CompileState {
  started,
  waitingForKey,
  gettingSourceDiffs,
  done,
}

/// Frontend server interaction states for a `reject` call.
enum _RejectState {
  started,
  waitingForKey,
  done,
}

final _feServerPath =
    p.join(sdkDir, 'bin', 'snapshots', 'frontend_server.dart.snapshot');
