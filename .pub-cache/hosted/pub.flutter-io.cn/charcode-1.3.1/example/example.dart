// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:charcode/charcode.dart";

void main() {
  print(String.fromCharCodes([
    $E,
    $x,
    $a,
    $m,
    $p,
    $l,
    $e,
    $exclamation,
  ]));
}

/// Check whether `(` and `)` are balanced in [input].
bool checkBalancedParentheses(String input) {
  var openParenCount = 0;
  for (var i = 0; i < input.length; i++) {
    var char = input.codeUnitAt(i);
    if (char == $lparen) {
      openParenCount++;
    } else if (char == $rparen) {
      openParenCount--;
      if (openParenCount < 0) return false;
    }
  }
  return openParenCount == 0;
}
