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

import 'package:file/local.dart';
import 'package:flutter_driver/src/native_driver.dart';
import 'package:flutter_goldens/skia_client.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart';
import 'package:process/process.dart';

const LocalFileSystem _localFs = LocalFileSystem();

// TODO(matanlurey): Refactor flutter_goldens to just re-use that code instead.
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
  final io.Directory tmpDir = io.Directory.systemTemp.createTempSync('android_driver_test');
  goldenFileComparator = _GoldenFileComparator(
    SkiaGoldClient(
      _localFs.directory(tmpDir.path),
      fs: _localFs,
      process: const LocalProcessManager(),
      platform: const LocalPlatform(),
      httpClient: io.HttpClient(),
      log: io.stderr.writeln,
    ),
    namePrefix: namePrefix,
    isPresubmit: false,
  );
}

final class _GoldenFileComparator extends GoldenFileComparator {
  _GoldenFileComparator(
    this.skiaClient, {
    required this.isPresubmit,
    this.namePrefix,
    Uri? baseDir,
  }) : baseDir = baseDir ?? Uri.parse(path.dirname(io.Platform.script.path));

  final Uri baseDir;
  final SkiaGoldClient skiaClient;
  final String? namePrefix;
  final bool isPresubmit;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    if (isPresubmit) {
      await skiaClient.tryjobInit();
    } else {
      await skiaClient.imgtestInit();
    }

    golden = _addPrefix(golden);
    await update(golden, imageBytes);

    final io.File goldenFile = _getGoldenFile(golden);
    if (isPresubmit) {
      await skiaClient.tryjobAdd(golden.path, _localFs.file(goldenFile.path));
      return true;
    } else {
      return skiaClient.imgtestAdd(golden.path, _localFs.file(goldenFile.path));
    }
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

  Uri _addPrefix(Uri golden) {
    assert(
      golden.toString().split('.').last == 'png',
      'Golden files in the Flutter framework must end with the file extension '
      '.png.',
    );
    return Uri.parse(<String>[
      if (namePrefix != null) namePrefix!,
      baseDir.pathSegments[baseDir.pathSegments.length - 2],
      golden.toString(),
    ].join('.'));
  }
}
