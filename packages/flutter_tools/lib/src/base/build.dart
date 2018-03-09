// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;

import 'package:crypto/crypto.dart' show md5;
import 'package:meta/meta.dart';
import 'package:quiver/core.dart' show hash2;

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
  SnapshotType(this.platform, this.mode)
    : assert(mode != null);

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

/// A fingerprint for a set of build input files and properties.
///
/// This class can be used during build actions to compute a fingerprint of the
/// build action inputs, and if unchanged from the previous build, skip the
/// build step. This assumes that build outputs are strictly a product of the
/// fingerprint inputs.
class Fingerprint {
  Fingerprint.fromBuildInputs(Map<String, String> properties, Iterable<String> inputPaths) {
    final Iterable<File> files = inputPaths.map(fs.file);
    final Iterable<File> missingInputs = files.where((File file) => !file.existsSync());
    if (missingInputs.isNotEmpty)
      throw new ArgumentError('Missing input files:\n' + missingInputs.join('\n'));

    _checksums = <String, String>{};
    for (File file in files) {
      final List<int> bytes = file.readAsBytesSync();
      _checksums[file.path] = md5.convert(bytes).toString();
    }
    _properties = <String, String>{}..addAll(properties);
  }

  /// Creates a Fingerprint from serialized JSON.
  ///
  /// Throws [ArgumentError], if there is a version mismatch between the
  /// serializing framework and this framework.
  Fingerprint.fromJson(String jsonData) {
    final Map<String, dynamic> content = json.decode(jsonData);

    final String version = content['version'];
    if (version != FlutterVersion.instance.frameworkRevision)
      throw new ArgumentError('Incompatible fingerprint version: $version');
    _checksums = content['files'] ?? <String, String>{};
    _properties = content['properties'] ?? <String, String>{};
  }

  Map<String, String> _checksums;
  Map<String, String> _properties;

  String toJson() => json.encode(<String, dynamic>{
    'version': FlutterVersion.instance.frameworkRevision,
    'properties': _properties,
    'files': _checksums,
  });

  @override
  bool operator==(dynamic other) {
    if (identical(other, this))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final Fingerprint typedOther = other;
    return _equalMaps(typedOther._checksums, _checksums)
        && _equalMaps(typedOther._properties, _properties);
  }

  bool _equalMaps(Map<String, String> a, Map<String, String> b) {
    return a.length == b.length
        && a.keys.every((String key) => a[key] == b[key]);
  }

  @override
  // Ignore map entries here to avoid becoming inconsistent with equals
  // due to differences in map entry order.
  int get hashCode => hash2(_properties.length, _checksums.length);
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
    final SnapshotType type = new SnapshotType(null, BuildMode.debug);
    final List<String> args = <String>[
      '--snapshot_kind=script',
      '--script_snapshot=$snapshotPath',
      '--enable-mirrors=false',
      mainPath,
    ];

    final String fingerprintPath = '$depfilePath.fingerprint';
    final int exitCode = await _build(
      snapshotType: type,
      outputSnapshotPath: snapshotPath,
      packagesPath: packagesPath,
      snapshotArgs: args,
      depfilePath: depfilePath,
      mainPath: mainPath,
      fingerprintPath: fingerprintPath,
    );
    if (exitCode != 0)
      return exitCode;
    await _writeFingerprint(type, snapshotPath, depfilePath, mainPath, fingerprintPath);
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
    @required String fingerprintPath,
  }) async {
    if (!await _isBuildRequired(snapshotType, outputSnapshotPath, depfilePath, mainPath, fingerprintPath)) {
      printTrace('Skipping snapshot build. Fingerprints match.');
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

    _writeFingerprint(snapshotType, outputSnapshotPath, depfilePath, mainPath, fingerprintPath);
    return 0;
  }

  Future<bool> _isBuildRequired(SnapshotType type, String outputSnapshotPath, String depfilePath, String mainPath, String fingerprintPath) async {
    final File fingerprintFile = fs.file(fingerprintPath);
    final File outputSnapshotFile = fs.file(outputSnapshotPath);
    final File depfile = fs.file(depfilePath);
    if (!outputSnapshotFile.existsSync() || !depfile.existsSync() || !fingerprintFile.existsSync())
      return true;

    try {
      if (fingerprintFile.existsSync()) {
        final Fingerprint oldFingerprint = new Fingerprint.fromJson(await fingerprintFile.readAsString());
        final Set<String> inputFilePaths = await readDepfile(depfilePath)..addAll(<String>[outputSnapshotPath, mainPath]);
        final Fingerprint newFingerprint = createFingerprint(type, mainPath, inputFilePaths);
        return oldFingerprint != newFingerprint;
      }
    } catch (e) {
      // Log exception and continue, this step is a performance improvement only.
      printTrace('Rebuilding snapshot due to fingerprint check error: $e');
    }
    return true;
  }

  Future<Null> _writeFingerprint(SnapshotType type, String outputSnapshotPath, String depfilePath, String mainPath, String fingerprintPath) async {
    try {
      final Set<String> inputFilePaths = await readDepfile(depfilePath)
        ..addAll(<String>[outputSnapshotPath, mainPath]);
      final Fingerprint fingerprint = createFingerprint(type, mainPath, inputFilePaths);
      await fs.file(fingerprintPath).writeAsString(fingerprint.toJson());
    } catch (e, s) {
      // Log exception and continue, this step is a performance improvement only.
      printStatus('Error during snapshot fingerprinting: $e\n$s');
    }
  }

  static Fingerprint createFingerprint(SnapshotType type, String mainPath, Iterable<String> inputFilePaths) {
    final Map<String, String> properties = <String, String>{
      'buildMode': type.mode.toString(),
      'targetPlatform': type.platform?.toString() ?? '',
      'entryPoint': mainPath,
    };
    final List<String> pathsWithSnapshotData = inputFilePaths.toList()
      ..add(artifacts.getArtifactPath(Artifact.vmSnapshotData))
      ..add(artifacts.getArtifactPath(Artifact.isolateSnapshotData));
    return new Fingerprint.fromBuildInputs(properties, pathsWithSnapshotData);
  }
}
