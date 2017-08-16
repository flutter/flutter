// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;

import 'package:crypto/crypto.dart' show md5;
import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../build_info.dart';
import '../globals.dart';
import 'context.dart';
import 'file_system.dart';
import 'process.dart';

GenSnapshot get genSnapshot => context.putIfAbsent(GenSnapshot, () => const GenSnapshot());

class GenSnapshot {
  const GenSnapshot();

  Future<int> run({
    @required TargetPlatform targetPlatform,
    @required BuildMode buildMode,
    @required String packagesPath,
    @required String depfilePath,
    Iterable<String> additionalArgs: const <String>[],
  }) {
    final String vmSnapshotData = artifacts.getArtifactPath(Artifact.vmSnapshotData);
    final String isolateSnapshotData = artifacts.getArtifactPath(Artifact.isolateSnapshotData);
    final List<String> args = <String>[
      '--assert_initializer',
      '--await_is_keyword',
      '--causal_async_stacks',
      '--vm_snapshot_data=$vmSnapshotData',
      '--isolate_snapshot_data=$isolateSnapshotData',
      '--packages=$packagesPath',
      '--dependencies=$depfilePath',
      '--print_snapshot_sizes',
    ]..addAll(additionalArgs);

    final String snapshotterPath = artifacts.getArtifactPath(Artifact.genSnapshot, targetPlatform, buildMode);
    return runCommandAndStreamOutput(<String>[snapshotterPath]..addAll(args));
  }
}

/// A collection of checksums for a set of input files.
///
/// This class can be used during build actions to compute a checksum of the
/// build action inputs, and if unchanged from the previous build, skip the
/// build step. This assumes that build outputs are strictly a product of the
/// input files.
class Checksum {
  Checksum.fromFiles(Set<String> inputPaths) : _checksums = <String, String>{} {
    final Iterable<File> files = inputPaths.map(fs.file);
    final Iterable<File> missingInputs = files.where((File file) => !file.existsSync());
    if (missingInputs.isNotEmpty)
      throw new ArgumentError('Missing input files:\n' + missingInputs.join('\n'));
    for (File file in files) {
      final List<int> bytes = file.readAsBytesSync();
      _checksums[file.path] = md5.convert(bytes).toString();
    }
  }

  Checksum.fromJson(String json) : _checksums = JSON.decode(json);

  final Map<String, String> _checksums;

  String toJson() => JSON.encode(_checksums);

  @override
  bool operator==(dynamic other) {
    return other is Checksum &&
        _checksums.length == other._checksums.length &&
        _checksums.keys.every((String key) => _checksums[key] == other._checksums[key]);
  }

  @override
  int get hashCode => _checksums.hashCode;
}

final RegExp _separatorExpr = new RegExp(r'([^\\]) ');
final RegExp _escapeExpr = new RegExp(r'\\(.)');

/// Parses a VM snapshot dependency file.
///
/// Snapshot dependency files are a single line mapping the output snapshot to a
/// space-separated list of input files used to generate that output. Spaces and
/// backslashes are escaped with a backslash. e.g,
///
/// outfile : file1.dart fil\\e2.dart fil\ e3.dart
///
/// will return a set containing: 'file1.dart', 'fil\e2.dart', 'fil e3.dart'.
Future<Set<String>> readDepfile(String depfilePath) async {
  // Depfile format:
  // outfile1 outfile2 : file1.dart file2.dart file3.dart
  final String contents = await fs.file(depfilePath).readAsString();
  final String dependencies = contents.split(': ')[1];
  return dependencies
      .replaceAllMapped(_separatorExpr, (Match match) => '${match.group(1)}\n')
      .split('\n')
      .map((String path) => path.replaceAllMapped(_escapeExpr, (Match match) => match.group(1)).trim())
      .where((String path) => path.isNotEmpty)
      .toSet();
}

/// Dart snapshot builder.
///
/// Builds Dart snapshots in one of three modes:
///   * Script snapshot: architecture-independent snapshot of a Dart script core
///     libraries.
///   * AOT snapshot: architecture-specific ahead-of-time compiled snapshot
///     suitable for loading with `mmap`.
///   * Assembly AOT snapshot: architecture-specific ahead-of-time compile to
///     assembly suitable for compilation as a static or dynamic library.
class Snapshotter {
  /// Builds an architecture-independent snapshot of the specified script.
  Future<int> buildScriptSnapshot({
    @required String mainPath,
    @required String snapshotPath,
    @required String depfilePath,
    @required String packagesPath
  }) async {
    final List<String> args = <String>[
      '--snapshot_kind=script',
      '--script_snapshot=$snapshotPath',
      mainPath,
    ];

    final String checksumsPath = '$depfilePath.checksums';
    final int exitCode = await _build(
      outputSnapshotPath: snapshotPath,
      packagesPath: packagesPath,
      snapshotArgs: args,
      depfilePath: depfilePath,
      mainPath: mainPath,
      checksumsPath: checksumsPath,
    );
    if (exitCode != 0)
      return exitCode;
    await _writeChecksum(snapshotPath, depfilePath, mainPath, checksumsPath);
    return exitCode;
  }

  /// Builds an architecture-specific ahead-of-time compiled snapshot of the specified script.
  Future<Null> buildAotSnapshot() async {
    throw new UnimplementedError('AOT snapshotting not yet implemented');
  }

  Future<int> _build({
    @required List<String> snapshotArgs,
    @required String outputSnapshotPath,
    @required String packagesPath,
    @required String depfilePath,
    @required String mainPath,
    @required String checksumsPath,
  }) async {
    if (!await _isBuildRequired(outputSnapshotPath, depfilePath, mainPath, checksumsPath)) {
      printTrace('Skipping snapshot build. Checksums match.');
      return 0;
    }

    // Build the snapshot.
    final int exitCode = await genSnapshot.run(
        targetPlatform: null,
        buildMode: BuildMode.debug,
        packagesPath: packagesPath,
        depfilePath: depfilePath,
        additionalArgs: snapshotArgs,
    );
    if (exitCode != 0)
      return exitCode;

    _writeChecksum(outputSnapshotPath, depfilePath, mainPath, checksumsPath);
    return 0;
  }

  Future<bool> _isBuildRequired(String outputSnapshotPath, String depfilePath, String mainPath, String checksumsPath) async {
    final File checksumFile = fs.file(checksumsPath);
    final File outputSnapshotFile = fs.file(outputSnapshotPath);
    final File depfile = fs.file(depfilePath);
    if (!outputSnapshotFile.existsSync() || !depfile.existsSync() || !checksumFile.existsSync())
      return true;

    try {
      if (checksumFile.existsSync()) {
        final Checksum oldChecksum = new Checksum.fromJson(await checksumFile.readAsString());
        final Set<String> checksumPaths = await readDepfile(depfilePath)
          ..addAll(<String>[outputSnapshotPath, mainPath]);
        final Checksum newChecksum = new Checksum.fromFiles(checksumPaths);
        return oldChecksum != newChecksum;
      }
    } catch (e, s) {
      // Log exception and continue, this step is a performance improvement only.
      printTrace('Error during snapshot checksum output: $e\n$s');
    }
    return true;
  }

  Future<Null> _writeChecksum(String outputSnapshotPath, String depfilePath, String mainPath, String checksumsPath) async {
    try {
      final Set<String> checksumPaths = await readDepfile(depfilePath)
        ..addAll(<String>[outputSnapshotPath, mainPath]);
      final Checksum checksum = new Checksum.fromFiles(checksumPaths);
      await fs.file(checksumsPath).writeAsString(checksum.toJson());
    } catch (e, s) {
      // Log exception and continue, this step is a performance improvement only.
      print('Error during snapshot checksum output: $e\n$s');
    }
  }
}
