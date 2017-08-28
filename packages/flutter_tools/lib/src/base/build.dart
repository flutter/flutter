// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show JSON;

import 'package:crypto/crypto.dart' show md5;
import 'package:quiver/core.dart' show hash2;

import '../build_info.dart';
import '../version.dart';
import 'file_system.dart';

/// A collection of checksums for a set of input files.
///
/// This class can be used during build actions to compute a checksum of the
/// build action inputs, and if unchanged from the previous build, skip the
/// build step. This assumes that build outputs are strictly a product of the
/// input files.
class Checksum {
  Checksum.fromFiles(BuildMode buildMode, Set<String> inputPaths) {
    final Iterable<File> files = inputPaths.map(fs.file);
    final Iterable<File> missingInputs = files.where((File file) => !file.existsSync());
    if (missingInputs.isNotEmpty)
      throw new ArgumentError('Missing input files:\n' + missingInputs.join('\n'));

    _buildMode = buildMode.toString();
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
  /// * BuildMode is unspecified.
  /// * File checksum map is unspecified.
  Checksum.fromJson(String json) {
    final Map<String, dynamic> content = JSON.decode(json);

    final String version = content['version'];
    if (version != FlutterVersion.instance.frameworkRevision)
      throw new ArgumentError('Incompatible checksum version: $version');

    _buildMode = content['buildMode'];
    if (_buildMode == null || _buildMode.isEmpty)
      throw new ArgumentError('BuildMode unspecified in checksum JSON');

    _checksums = content['files'];
    if (_checksums == null)
      throw new ArgumentError('File checksums unspecified in checksum JSON');
  }

  String _buildMode;
  Map<String, String> _checksums;

  String toJson() => JSON.encode(<String, dynamic>{
    'version': FlutterVersion.instance.frameworkRevision,
    'buildMode': _buildMode,
    'files': _checksums,
  });

  @override
  bool operator==(dynamic other) {
    return other is Checksum &&
        _buildMode == other._buildMode &&
        _checksums.length == other._checksums.length &&
        _checksums.keys.every((String key) => _checksums[key] == other._checksums[key]);
  }

  @override
  int get hashCode => hash2(_buildMode, _checksums);
}
