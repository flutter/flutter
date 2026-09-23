// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:record_use/record_use.dart';

import '../../base/file_system.dart';
import '../../convert.dart';

/// The files a build directory holds recorded uses in: the kernel compiler's
/// for native builds, and dart2js's and dart2wasm's for web builds.
const recordedUsesFileNames = <String>[
  'recorded_uses.json',
  'recorded_uses_js.json',
  'recorded_uses_wasm.json',
];

/// Reads the recorded uses in [buildDir] and merges them into one
/// [Recordings].
///
/// A web build can compile the app to both JavaScript and WebAssembly, which
/// share one set of assets, so both compilers' recordings are merged. A file
/// that does not exist or is empty is skipped, and null is returned when every
/// file was. A file holding `{}`, which a build writes where a compiler
/// recorded nothing, reads as no uses.
///
/// Throws a [FormatException] when a file is not a recorded uses file.
Recordings? readRecordedUses(Directory buildDir) {
  Recordings? merged;
  for (final String name in recordedUsesFileNames) {
    final File file = buildDir.childFile(name);
    if (!file.existsSync() || file.lengthSync() == 0) {
      continue;
    }
    final Object? data;
    try {
      data = json.decode(file.readAsStringSync());
    } on FormatException catch (e) {
      throw FormatException('Failed to parse recorded uses file: $e');
    }
    if (data is! Map<String, Object?>) {
      throw const FormatException('Invalid recorded uses file: expected a top level JSON object.');
    }
    final Recordings recordings;
    try {
      recordings = Recordings.fromJson(data);
    } on Object catch (e) {
      // A malformed file can make it throw a TypeError or a RangeError, not
      // only a FormatException.
      throw FormatException('Failed to parse recorded uses file: $e');
    }
    merged = merged == null ? recordings : merged + recordings;
  }
  return merged;
}
