// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show min;

String? getRelativePathIfInside(String libraryPath, String filePath) {
  int minLength = min(libraryPath.length, filePath.length);

  // Find how far the strings are the same.
  int same = 0;
  for (int i = 0; i < minLength; i++) {
    if (libraryPath.codeUnitAt(i) == filePath.codeUnitAt(i)) {
      same++;
    } else {
      break;
    }
  }
  // They're the same up to and including index [same].
  // If there isn't a path seperator left in the string [libPath],
  // [filePath] is inside the same dir as [libPath] (possibly within
  // subdirs).
  const int forwardSlash = 47;
  const int backwardsSlash = 92;
  for (int i = same; i < libraryPath.length; i++) {
    int c = libraryPath.codeUnitAt(i);
    if (c == forwardSlash || c == backwardsSlash) {
      return null;
    }
  }

  // To get the relative path we need to go back to the previous path
  // seperator.
  for (int i = same; i >= 0; i--) {
    int c = libraryPath.codeUnitAt(i);
    if (c == forwardSlash || c == backwardsSlash) {
      return filePath.substring(i + 1);
    }
  }
  throw UnsupportedError("Unsupported input: $libraryPath and $filePath");
}
