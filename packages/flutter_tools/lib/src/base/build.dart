// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show JSON;

import 'package:crypto/crypto.dart' show md5;

import 'file_system.dart';

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
