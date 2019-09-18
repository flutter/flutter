// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

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

/// Attempts to match the current browser state with the screenshot [filename].
Future<void> matchGoldenFile(String filename, { bool write = false, Rect region = null }) async {
  final String response = await _callScreenshotServer(<String, dynamic>{
    'filename': filename,
    'write': write,
    'region': region == null ? null : {'x': region.left, 'y': region.top, 'width': region.width, 'height': region.height},
  });
  if (response == 'OK') {
    // Pass
    return;
  }
  fail(response);
}
