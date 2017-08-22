// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show JSON;

import 'package:crypto/crypto.dart' show md5;

import 'file_system.dart';

/// Fingerprint of build inputs.
///
/// Consists of checksums for a set of input files and the values of a set of
/// property keys.
///
/// This class can be used during build actions to compute the fingerprint of
/// the build action inputs, and if unchanged from the previous build, skip the
/// build step. This assumes that build outputs are strictly a product of the
/// input files and properties provided.
class Fingerprint {
  Fingerprint.fromInputs({Set<String> filePaths, Map<String, String> properties}) : _fingerprint = <String, String>{} {
    filePaths ??= new Set<String>();
    properties ??= <String, String>{};
    if (properties.keys.any(filePaths.contains))
      throw new ArgumentError('File path and property key collision');
    final Iterable<File> files = filePaths.map(fs.file);
    final Iterable<File> missingInputs = files.where((File file) => !file.existsSync());
    if (missingInputs.isNotEmpty)
      throw new ArgumentError('Missing input files:\n' + missingInputs.join('\n'));
    for (File file in files) {
      final List<int> bytes = file.readAsBytesSync();
      _fingerprint[file.path] = md5.convert(bytes).toString();
    }
    _fingerprint.addAll(properties);
  }

  Fingerprint.fromJson(String json) : _fingerprint = JSON.decode(json);

  final Map<String, String> _fingerprint;

  String toJson() => JSON.encode(_fingerprint);

  @override
  bool operator==(dynamic other) {
    return other is Fingerprint &&
        _fingerprint.length == other._fingerprint.length &&
        _fingerprint.keys.every((String key) => _fingerprint[key] == other._fingerprint[key]);
  }

  @override
  int get hashCode {
    int accumulator = 0;
    for (String key in new List<String>.from(_fingerprint.keys)..sort()) {
      accumulator ^= key.hashCode;
      accumulator ^= _fingerprint[key].hashCode;
    }
    return accumulator;
  }
}
