// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

/// decodes a base64 screenshot stored in the devicelab.
///
/// Usage dart tool/screenshot_decoder.dart path/to/log_file
void main(List<String> arguments) {
  int screenshot = 0;
  final String logFile = arguments.first;
  for (final String line in File(logFile).readAsLinesSync()) {
    if (!line.contains('BASE64 SCREENSHOT:')) {
      continue;
    }
    final String message = line.split('BASE64 SCREENSHOT:')[1];
    final List<int> bytes = base64.decode(message);
    File('flutter_screenshot_$screenshot.png').writeAsBytesSync(bytes);
    screenshot += 1;
  }
}