// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const bool _kIsCompiledToJavaScript = identical(0, 0.0);
final RegExp _doubleFormatter = RegExp(r'(\d)\.0\b');

/// Automatically reformats a String containing doubles for the web.
///
/// In the Dart VM or native Dart runtimes, [double.toString()] on whole number
/// values will have a trailing `.0`. In Browsers, the equivalent
/// Number.toString does not include this trailing `.0`, which can result in
/// differently formatted output strings in places such as debug messages or
/// diagnostic nodes.
String ignoreWebNumericQuirks(String input) {
  if (_kIsCompiledToJavaScript) {
    return input.replaceAllMapped(_doubleFormatter, (Match match) {
      return match.group(1);
    });
  }
  return input;
}
