// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/expect.dart';

import 'error_code_info.dart';

/// Check that the file 'messages.yaml' has corresponding parameters count
/// between the errors 'problemMessage'/'correctionMessage' and 'comment'.
void main() {
  var classValues = analyzerMessages.values;
  for (var classValue in classValues) {
    for (var errorEntry in classValue.entries) {
      var error = errorEntry.value;
      if (_getMessagesParameters(error) !=
          _getCommentParameters(error.comment ?? '')) {
        fail(
            "Parameters don't match between the problemMessage and comment in ${errorEntry.key}");
      }
    }
  }
}

int _getCommentParameters(String message) {
  var i = 0;
  while (message.contains('\n$i: ')) {
    i++;
  }
  return i;
}

int _getMessagesParameters(ErrorCodeInfo info) {
  var i = 0;
  while (info.problemMessage.contains('{$i}')) {
    i++;
  }
  while (info.correctionMessage?.contains('{$i}') ?? false) {
    i++;
  }
  return i;
}
