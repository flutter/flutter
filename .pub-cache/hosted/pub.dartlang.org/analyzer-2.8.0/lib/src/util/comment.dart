// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// Return the raw text of the given comment node.
String? getCommentNodeRawText(Comment? node) {
  if (node == null) return null;

  var tokens = node.tokens;
  var count = tokens.length;
  if (count == 1) {
    // The comment might be a block-style doc comment with embedded end-of-line
    // markers.
    return tokens[0].lexeme.replaceAll('\r\n', '\n');
  }

  var buffer = StringBuffer();
  for (var i = 0; i < count; i++) {
    if (i > 0) {
      buffer.write('\n');
    }
    buffer.write(tokens[i].lexeme);
  }
  return buffer.toString();
}

/// Return the plain text from the given DartDoc [rawText], without delimiters.
String? getDartDocPlainText(String? rawText) {
  if (rawText == null) return null;

  // Remove /** */.
  var isBlock = false;
  if (rawText.startsWith('/**')) {
    isBlock = true;
    rawText = rawText.substring(3);
    if (rawText.endsWith('*/')) {
      rawText = rawText.substring(0, rawText.length - 2);
    }
  }
  rawText = rawText.trim();

  // Remove leading '* ' and '/// '.
  var result = StringBuffer();
  var lines = rawText.split('\n');
  for (var line in lines) {
    line = line.trim();
    if (isBlock && line.startsWith('*')) {
      line = line.substring(1);
      if (line.startsWith(' ')) {
        line = line.substring(1);
      }
    } else if (!isBlock && line.startsWith('///')) {
      line = line.substring(3);
      if (line.startsWith(' ')) {
        line = line.substring(1);
      }
    }
    if (result.isNotEmpty) {
      result.write('\n');
    }
    result.write(line);
  }

  return result.toString();
}

/// Return the DartDoc summary, i.e. the portion before the first empty line.
String? getDartDocSummary(String? completeText) {
  if (completeText == null) {
    return null;
  }
  var lines = completeText.split('\n');
  int count = lines.length;
  if (count == 1) {
    return lines[0];
  }
  var result = StringBuffer();
  for (var i = 0; i < count; i++) {
    var line = lines[i];
    if (i > 0) {
      if (line.isEmpty) {
        return result.toString();
      }
      result.write('\n');
    }
    result.write(line);
  }
  return result.toString();
}
