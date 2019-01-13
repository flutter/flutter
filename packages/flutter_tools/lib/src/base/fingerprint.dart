// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;

import 'package:crypto/crypto.dart' show md5;
import 'package:meta/meta.dart';
import 'package:quiver/core.dart' show hash2;

import '../globals.dart';
import '../version.dart';
import 'file_system.dart';

typedef FingerprintPathFilter = bool Function(String path);

/// A tool that can be used to compute, compare, and write [Fingerprint]s for a
/// set of input files and associated build settings.
///
/// This class can be used during build actions to compute a fingerprint of the
/// build action inputs and options, and if unchanged from the previous build,
/// skip the build step. This assumes that build outputs are strictly a product
/// of the fingerprint inputs.
class Fingerprinter {
  Fingerprinter({
    @required this.fingerprintPath,
    @required Iterable<String> paths,
    @required Map<String, String> properties,
    Iterable<String> depfilePaths = const <String>[],
    FingerprintPathFilter pathFilter,
  }) : _paths = paths.toList(),
       _properties = Map<String, String>.from(properties),
       _depfilePaths = depfilePaths.toList(),
       _pathFilter = pathFilter,
       assert(fingerprintPath != null),
       assert(paths != null && paths.every((String path) => path != null)),
       assert(properties != null),
       assert(depfilePaths != null && depfilePaths.every((String path) => path != null));

  final String fingerprintPath;
  final List<String> _paths;
  final Map<String, String> _properties;
  final List<String> _depfilePaths;
  final FingerprintPathFilter _pathFilter;

  Future<Fingerprint> buildFingerprint() async {
    final List<String> paths = await _getPaths();
    return Fingerprint.fromBuildInputs(_properties, paths);
  }

  Future<bool> doesFingerprintMatch() async {
    try {
      final File fingerprintFile = fs.file(fingerprintPath);
      if (!fingerprintFile.existsSync())
        return false;

      if (!_depfilePaths.every(fs.isFileSync))
        return false;

      final List<String> paths = await _getPaths();
      if (!paths.every(fs.isFileSync))
        return false;

      final Fingerprint oldFingerprint = Fingerprint.fromJson(await fingerprintFile.readAsString());
      final Fingerprint newFingerprint = await buildFingerprint();
      return oldFingerprint == newFingerprint;
    } catch (e) {
      // Log exception and continue, fingerprinting is only a performance improvement.
      printTrace('Fingerprint check error: $e');
    }
    return false;
  }

  Future<void> writeFingerprint() async {
    try {
      final Fingerprint fingerprint = await buildFingerprint();
      fs.file(fingerprintPath).writeAsStringSync(fingerprint.toJson());
    } catch (e) {
      // Log exception and continue, fingerprinting is only a performance improvement.
      printTrace('Fingerprint write error: $e');
    }
  }

  Future<List<String>> _getPaths() async {
    final Set<String> paths = _paths.toSet();
    for (String depfilePath in _depfilePaths)
      paths.addAll(await readDepfile(depfilePath));
    final FingerprintPathFilter filter = _pathFilter ?? (String path) => true;
    return paths.where(filter).toList()..sort();
  }
}

/// A fingerprint that uniquely identifies a set of build input files and
/// properties.
///
/// See [Fingerprinter].
class Fingerprint {
  Fingerprint.fromBuildInputs(Map<String, String> properties, Iterable<String> inputPaths) {
    final Iterable<File> files = inputPaths.map<File>(fs.file);
    final Iterable<File> missingInputs = files.where((File file) => !file.existsSync());
    if (missingInputs.isNotEmpty)
      throw ArgumentError('Missing input files:\n' + missingInputs.join('\n'));

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
      throw ArgumentError('Incompatible fingerprint version: $version');
    _checksums = content['files']?.cast<String,String>() ?? <String, String>{};
    _properties = content['properties']?.cast<String,String>() ?? <String, String>{};
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

  @override
  String toString() => '{checksums: $_checksums, properties: $_properties}';
}

final RegExp _separatorExpr = RegExp(r'([^\\]) ');
final RegExp _escapeExpr = RegExp(r'\\(.)');

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
      .map<String>((String path) => path.replaceAllMapped(_escapeExpr, (Match match) => match.group(1)).trim())
      .where((String path) => path.isNotEmpty)
      .toSet();
}


