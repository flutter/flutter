// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stack_trace.src.utils;

/// Returns [string] with enough spaces added to the end to make it [length]
/// characters long.
String padRight(String string, int length) {
  if (string.length >= length) return string;

  var result = new StringBuffer();
  result.write(string);
  for (var i = 0; i < length - string.length; i++) {
    result.write(' ');
  }

  return result.toString();
}

/// Flattens nested lists inside an iterable into a single list containing only
/// non-list elements.
List flatten(Iterable nested) {
  var result = [];
  helper(list) {
    for (var element in list) {
      if (element is List) {
        helper(element);
      } else {
        result.add(element);
      }
    }
  }
  helper(nested);
  return result;
}
