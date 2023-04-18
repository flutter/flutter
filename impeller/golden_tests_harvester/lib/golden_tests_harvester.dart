// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:skia_gold_client/skia_gold_client.dart';

import 'logger.dart';

export 'logger.dart';

/// Reads the digest inside of [workDirectory], sending tests to
/// [skiaGoldClient].
Future<void> harvest(SkiaGoldClient skiaGoldClient, Directory workDirectory,
    List<Object?> entries) async {
  await skiaGoldClient.auth();

  final List<Future<void>> pendingComparisons = <Future<void>>[];
  for (final Object? entry in entries) {
    final Map<String, Object?> map = (entry as Map<String, Object?>?)!;
    final String filename = (map['filename'] as String?)!;
    final int width = (map['width'] as int?)!;
    final int height = (map['height'] as int?)!;
    final double maxDiffPixelsPercent =
        (map['maxDiffPixelsPercent'] as double?)!;
    final int maxColorDelta = (map['maxColorDelta'] as int?)!;
    final File goldenImage = File(p.join(workDirectory.path, filename));
    final Future<void> future = skiaGoldClient
        .addImg(filename, goldenImage,
            screenshotSize: width * height,
            differentPixelsRate: maxDiffPixelsPercent,
            pixelColorDelta: maxColorDelta)
        .catchError((dynamic err) {
      Logger.instance.log('skia gold comparison failed: $err');
      throw Exception('Failed comparison: $filename');
    });
    pendingComparisons.add(future);
  }

  await Future.wait(pendingComparisons);
}
