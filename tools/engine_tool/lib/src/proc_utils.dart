// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:process_runner/process_runner.dart';

import 'environment.dart';
import 'json_utils.dart';
import 'worker_pool.dart';

/// Artifacts from an exited sub-process.
final class ProcessArtifacts {
  /// Constructs an instance of ProcessArtifacts from raw values.
  ProcessArtifacts(
      this.cwd, this.commandLine, this.exitCode, this.stdout, this.stderr,
      {this.pid});

  /// Constructs an instance of ProcessArtifacts from serialized JSON text.
  factory ProcessArtifacts.fromJson(String serialized) {
    final Map<String, dynamic> artifact =
        jsonDecode(serialized) as Map<String, dynamic>;
    final List<String> errors = <String>[];
    final Directory cwd = Directory(stringOfJson(artifact, 'cwd', errors)!);
    final List<String> commandLine =
        stringListOfJson(artifact, 'commandLine', errors)!;
    final int exitCode = intOfJson(artifact, 'exitCode', errors)!;
    final String stdout = stringOfJson(artifact, 'stdout', errors)!;
    final String stderr = stringOfJson(artifact, 'stderr', errors)!;
    return ProcessArtifacts(cwd, commandLine, exitCode, stdout, stderr);
  }

  /// Constructs an instance of ProcessArtifacts from a file containing JSON.
  factory ProcessArtifacts.fromFile(File file) {
    return ProcessArtifacts.fromJson(file.readAsStringSync());
  }

  /// Saves ProcessArtifacts into file.
  void save(File file) {
    final Map<String, Object> data = <String, Object>{};
    if (pid != null) {
      data['pid'] = pid!;
    }
    data['exitCode'] = exitCode;
    data['stdout'] = stdout;
    data['stderr'] = stderr;
    data['cwd'] = cwd.absolute.path;
    data['commandLine'] = commandLine;
    file.writeAsStringSync(jsonEncodePretty(data));
  }

  /// Creates a temporary file and saves the artifacts into it.
  /// Returns the File.
  File saveTemp() {
    final Directory systemTemp = Directory.systemTemp;
    final String prefix = pid != null ? 'et$pid' : 'et';
    final Directory artifacts = systemTemp.createTempSync(prefix);
    final File resultFile =
        File(p.join(artifacts.path, 'process_artifacts.json'));
    save(resultFile);
    return resultFile;
  }

  /// Current working directory of process when it was spawned.
  final Directory cwd;

  /// Full command line of process.
  final List<String> commandLine;

  /// Exit code.
  final int exitCode;

  /// Stdout (may be empty).
  final String stdout;

  /// Stdout (may be empty).
  final String stderr;

  /// Pid (when available).
  final int? pid;
}

/// A WorkerTask that runs a process
class ProcessTask extends WorkerTask {
  /// Construct a new process task with name, cwd, and command line.
  ProcessTask(super.name, this._environment, this._cwd, this._commandLine);

  final Environment _environment;
  final Directory _cwd;
  final List<String> _commandLine;
  late ProcessArtifacts? _processArtifacts;
  late String? _processArtifactsPath;

  @override
  Future<bool> run() async {
    final ProcessRunnerResult result = await _environment.processRunner
        .runProcess(_commandLine, failOk: true, workingDirectory: _cwd);
    _processArtifacts = ProcessArtifacts(
        _cwd, _commandLine, result.exitCode, result.stdout, result.stderr,
        pid: result.pid);
    _processArtifactsPath = _processArtifacts!.saveTemp().path;
    return result.exitCode == 0;
  }

  /// Returns the ProcessArtifacts after run completes.
  ProcessArtifacts get processArtifacts {
    return _processArtifacts!;
  }

  /// Returns the path that the process artifacts were saved in.
  String get processArtifactsPath {
    return _processArtifactsPath!;
  }
}
