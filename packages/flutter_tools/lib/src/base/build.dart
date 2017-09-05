// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;

import 'package:crypto/crypto.dart' show md5;
import 'package:meta/meta.dart';
import 'package:quiver/core.dart' show hash4;

import '../artifacts.dart';
import '../build_info.dart';
import '../globals.dart';
import '../version.dart';
import 'context.dart';
import 'file_system.dart';
import 'process.dart';

GenSnapshot get genSnapshot => context.putIfAbsent(GenSnapshot, () => const GenSnapshot());

/// A snapshot build configuration.
class SnapshotType {
  const SnapshotType(this.platform, this.mode);

  final TargetPlatform platform;
  final BuildMode mode;
}

/// Interface to the gen_snapshot command-line tool.
class GenSnapshot {
  const GenSnapshot();

  Future<int> run({
    @required SnapshotType snapshotType,
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

    final String snapshotterPath = artifacts.getArtifactPath(Artifact.genSnapshot, snapshotType.platform, snapshotType.mode);
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
  Checksum.fromFiles(SnapshotType type, this._mainPath, Set<String> inputPaths) {
    final Iterable<File> files = inputPaths.map(fs.file);
    final Iterable<File> missingInputs = files.where((File file) => !file.existsSync());
    if (missingInputs.isNotEmpty)
      throw new ArgumentError('Missing input files:\n' + missingInputs.join('\n'));

    _buildMode = type.mode.toString();
    _targetPlatform = type.platform?.toString() ?? '';
    _checksums = <String, String>{};
    for (File file in files) {
      final List<int> bytes = file.readAsBytesSync();
      _checksums[file.path] = md5.convert(bytes).toString();
    }
  }

  /// Creates a checksum from serialized JSON.
  ///
  /// Throws [ArgumentError] in the following cases:
  /// * Version mismatch between the serializing framework and this framework.
  /// * buildMode is unspecified.
  /// * targetPlatform is unspecified.
  /// * File checksum map is unspecified.
  Checksum.fromJson(String json) {
    final Map<String, dynamic> content = JSON.decode(json);

    final String version = content['version'];
    if (version != FlutterVersion.instance.frameworkRevision)
      throw new ArgumentError('Incompatible checksum version: $version');

    _buildMode = content['buildMode'];
    if (_buildMode == null || _buildMode.isEmpty)
      throw new ArgumentError('Build mode unspecified in checksum JSON');

    _targetPlatform = content['targetPlatform'];
    if (_targetPlatform == null)
      throw new ArgumentError('Target platform unspecified in checksum JSON');

    _mainPath = content['entrypoint'];
    if (_mainPath == null)
      throw new ArgumentError('Entrypoint unspecified in checksum JSON');

    _checksums = content['files'];
    if (_checksums == null)
      throw new ArgumentError('File checksums unspecified in checksum JSON');
  }

  String _mainPath;
  String _buildMode;
  String _targetPlatform;
  Map<String, String> _checksums;

  String toJson() => JSON.encode(<String, dynamic>{
    'version': FlutterVersion.instance.frameworkRevision,
    'buildMode': _buildMode,
    'entrypoint': _mainPath,
    'targetPlatform': _targetPlatform,
    'files': _checksums,
  });

  @override
  bool operator==(dynamic other) {
    return other is Checksum &&
        _buildMode == other._buildMode &&
        _targetPlatform == other._targetPlatform &&
        _mainPath == other._mainPath &&
        _checksums.length == other._checksums.length &&
        _checksums.keys.every((String key) => _checksums[key] == other._checksums[key]);
  }

  @override
  int get hashCode => hash4(_buildMode, _targetPlatform, _mainPath, _checksums);
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
///   * Script snapshot: architecture-independent snapshot of a Dart script
///     and core libraries.
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
    const SnapshotType type = const SnapshotType(null, BuildMode.debug);
    final List<String> args = <String>[
      '--snapshot_kind=script',
      '--script_snapshot=$snapshotPath',
      mainPath,
    ];

    final String checksumsPath = '$depfilePath.checksums';
    final int exitCode = await _build(
      snapshotType: type,
      outputSnapshotPath: snapshotPath,
      packagesPath: packagesPath,
      snapshotArgs: args,
      depfilePath: depfilePath,
      mainPath: mainPath,
      checksumsPath: checksumsPath,
    );
    if (exitCode != 0)
      return exitCode;
    await _writeChecksum(type, snapshotPath, depfilePath, mainPath, checksumsPath);
    return exitCode;
  }

  /// Builds an architecture-specific ahead-of-time compiled snapshot of the specified script.
  Future<Null> buildAotSnapshot() async {
    throw new UnimplementedError('AOT snapshotting not yet implemented');
  }

  Future<int> _build({
    @required SnapshotType snapshotType,
    @required List<String> snapshotArgs,
    @required String outputSnapshotPath,
    @required String packagesPath,
    @required String depfilePath,
    @required String mainPath,
    @required String checksumsPath,
  }) async {
    if (!await _isBuildRequired(snapshotType, outputSnapshotPath, depfilePath, mainPath, checksumsPath)) {
      printTrace('Skipping snapshot build. Checksums match.');
      return 0;
    }

    // Build the snapshot.
    final int exitCode = await genSnapshot.run(
        snapshotType: snapshotType,
        packagesPath: packagesPath,
        depfilePath: depfilePath,
        additionalArgs: snapshotArgs,
    );
    if (exitCode != 0)
      return exitCode;

    _writeChecksum(snapshotType, outputSnapshotPath, depfilePath, mainPath, checksumsPath);
    return 0;
  }

  Future<bool> _isBuildRequired(SnapshotType type, String outputSnapshotPath, String depfilePath, String mainPath, String checksumsPath) async {
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
        final Checksum newChecksum = new Checksum.fromFiles(type, mainPath, checksumPaths);
        return oldChecksum != newChecksum;
      }
    } catch (e, s) {
      // Log exception and continue, this step is a performance improvement only.
      printTrace('Error during snapshot checksum output: $e\n$s');
    }
    return true;
  }

  Future<Null> _writeChecksum(SnapshotType type, String outputSnapshotPath, String depfilePath, String mainPath, String checksumsPath) async {
    try {
      final Set<String> checksumPaths = await readDepfile(depfilePath)
        ..addAll(<String>[outputSnapshotPath, mainPath]);
      final Checksum checksum = new Checksum.fromFiles(type, mainPath, checksumPaths);
      await fs.file(checksumsPath).writeAsString(checksum.toJson());
    } catch (e, s) {
      // Log exception and continue, this step is a performance improvement only.
      print('Error during snapshot checksum output: $e\n$s');
    }
  }
}
