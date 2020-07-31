// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import 'package:test/test.dart';

Future<dynamic> _callScreenshotServer(dynamic requestData) async {
  final html.HttpRequest request = await html.HttpRequest.request(
    'screenshot',
    method: 'POST',
    sendData: json.encode(requestData),
  );

  return json.decode(request.responseText);
}

/// How to compare pixels within the image.
///
/// Keep this enum in sync with the one defined in `goldens.dart`.
enum PixelComparison {
  /// Allows minor blur and anti-aliasing differences by comparing a 3x3 grid
  /// surrounding the pixel rather than direct 1:1 comparison.
  fuzzy,

  /// Compares one pixel at a time.
  ///
  /// Anti-aliasing or blur will result in higher diff rate.
  precise,
}

/// Attempts to match the current browser state with the screenshot [filename].
///
/// If [write] is true, will overwrite the golden file and fail the test. Use
/// it to update golden files.
///
/// If [region] is not null, the golden will only include the part contained by
/// the rectangle.
///
/// [maxDiffRate] specifies the tolerance to the number of non-matching pixels
/// before the test is considered as failing. If [maxDiffRate] is null, applies
/// a default value defined in `test_platform.dart`.
///
/// [pixelComparison] determines the algorithm used to compare pixels. Uses
/// fuzzy comparison by default.
Future<void> matchGoldenFile(String filename,
    {bool write = false, Rect region = null, double maxDiffRatePercent = null, PixelComparison pixelComparison = PixelComparison.fuzzy}) async {
  Map<String, dynamic> serverParams = <String, dynamic>{
    'filename': filename,
    'write': write,
    'region': region == null
        ? null
        : <String, dynamic>{
            'x': region.left,
            'y': region.top,
            'width': region.width,
            'height': region.height
          },
    'pixelComparison': pixelComparison.toString(),
  };

  // Chrome on macOS renders slightly differently from Linux, so allow it an
  // extra 1% to deviate from the golden files.
  if (maxDiffRatePercent != null) {
    if (operatingSystem == OperatingSystem.macOs) {
      maxDiffRatePercent += 1.0;
    }
    serverParams['maxdiffrate'] = maxDiffRatePercent / 100;
  } else if (operatingSystem == OperatingSystem.macOs) {
    serverParams['maxdiffrate'] = 0.01;
  }
  final String response = await _callScreenshotServer(serverParams) as String;
  if (response == 'OK') {
    // Pass
    return;
  }
  fail(response);
}
