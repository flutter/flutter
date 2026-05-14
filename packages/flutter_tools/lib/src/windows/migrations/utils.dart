// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Creates a new string with the first occurrence of [before] replaced by
/// [after].
///
/// If the [originalContents] uses CRLF line endings, the [before] and [after]
/// will be converted to CRLF line endings before the replacement is made.
/// This is necessary for users that have git autocrlf enabled.
///
/// Example:
/// ```dart
/// 'a\n'.replaceFirst('a\n', 'b\n'); // 'b\n'
/// 'a\r\n'.replaceFirst('a\n', 'b\n'); // 'b\r\n'
/// ```
String replaceFirst(String originalContents, String before, String after) {
  final String result = originalContents.replaceFirst(before, after);
  if (result != originalContents) {
    return result;
  }

  final String beforeCrlf = before.replaceAll('\n', '\r\n');
  final String afterCrlf = after.replaceAll('\n', '\r\n');

  return originalContents.replaceFirst(beforeCrlf, afterCrlf);
}
