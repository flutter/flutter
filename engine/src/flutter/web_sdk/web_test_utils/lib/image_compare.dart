// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:image/image.dart';
import 'package:path/path.dart' as p;
import 'package:skia_gold_client/skia_gold_client.dart';

import 'environment.dart';

/// Compares a screenshot taken through a test with its golden.
///
/// Used by Flutter Web Engine unit tests and the integration tests.
///
/// Returns the results of the tests as `String`. When tests passes the result
/// is simply `OK`, however when they fail it contains a detailed explanation
/// on which files are compared, their absolute locations and an HTML page
/// that the developer can see the comparison.
Future<String> compareImage(
  Image screenshot,
  bool doUpdateScreenshotGoldens,
  String filename,
  SkiaGoldClient? skiaClient, {
  required bool isCanvaskitTest,
  required bool verbose,
}) async {
  if (skiaClient == null) {
    return 'OK';
  }

  final String screenshotPath = _getFullScreenshotPath(filename);
  final File screenshotFile = File(screenshotPath);
  await screenshotFile.create(recursive: true);
  await screenshotFile.writeAsBytes(encodePng(screenshot), flush: true);

  if (isLuciEnv) {
    // This is temporary to get started by uploading existing screenshots to
    // Skia Gold. The next step would be to actually use Skia Gold for
    // comparison.
    final int screenshotSize = screenshot.width * screenshot.height;

    late int pixelColorDelta;
    if (isCanvaskitTest) {
      pixelColorDelta = 21;
    } else if (skiaClient.dimensions != null && skiaClient.dimensions!['Browser'] == 'ios-safari') {
      pixelColorDelta = 15;
    } else {
      pixelColorDelta = 3;
    }
    skiaClient.addImg(
      filename,
      screenshotFile,
      screenshotSize: screenshotSize,
      pixelColorDelta: pixelColorDelta,
    );
    return 'OK';
  }

  final Image? golden = await _getGolden(filename);

  if (doUpdateScreenshotGoldens) {
    return 'OK';
  }

  if (golden == null) {
    // This is a new screenshot that doesn't have an existing golden.

    // At the moment, we don't support local screenshot testing because we use
    // Skia Gold to handle our screenshots and diffing. In the future, we might
    // implement local screenshot testing if there's a need.
    if (verbose) {
      print('Screenshot generated: file://$screenshotPath'); // ignore: avoid_print
    }
    return 'OK';
  }

  // TODO(mdebbar): Use the Gold tool to locally diff the golden.
  return 'OK';
}

Future<Image?> _getGolden(String filename) {
  // TODO(mdebbar): Fetch the golden from Skia Gold.
  return Future<Image?>.value();
}

String _getFullScreenshotPath(String filename) {
  return p.join(environment.webUiSkiaGoldDirectory.path, filename);
}
