// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A fork of `package:flutter_goldens/flutter_goldens.dart` without the
/// dependency on `package:flutter_test` or `package:flutter`; this allows
/// the library to be used in a standalone Dart VM context.
library;

import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter_driver/src/native_driver.dart';
import 'package:flutter_goldens/skia_client.dart';
import 'package:path/path.dart' as path;

// TODO(matanlurey): Refactor flutter_goldens to just re-use that code instead.

/// Main method that can be used in manually in a `test_driver/*_test.dart` file
/// to set [goldenFileComparator] to an instance of
/// [FlutterGoldenFileComparator] that works for the current test. _Which_
/// FlutterGoldenFileComparator is instantiated is based on the current testing
/// environment.
///
/// When set, the `namePrefix` is prepended to the names of all gold images.
Future<void> testExecutable(
  FutureOr<void> Function() testMain, {
  String? namePrefix,
}) async {
  assert(
    goldenFileComparator is NaiveLocalFileComparator,
    'The flutter_goldens_fork library should be used from a *_test.dart file '
    'where the "goldenFileComparator" has not yet been set. This is to ensure '
    'that the correct comparator is used for the current test environment.',
  );
}

final class _GoldenFileComparator extends GoldenFileComparator {
  _GoldenFileComparator(
    this.skiaClient, {
    this.namePrefix,
    Uri? baseDir,
  }) : baseDir = baseDir ?? Uri.parse(path.dirname(io.Platform.script.path));

  final Uri baseDir;
  final SkiaGoldClient skiaClient;
  final String? namePrefix;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) {
    // TODO: implement compare
    throw UnimplementedError();
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final io.File goldenFile = _getGoldenFile(golden);
    await goldenFile.parent.create(recursive: true);
    await goldenFile.writeAsBytes(imageBytes, flush: true);
  }

  io.File _getGoldenFile(Uri uri) {
    return io.File.fromUri(baseDir.resolveUri(uri));
  }
}
