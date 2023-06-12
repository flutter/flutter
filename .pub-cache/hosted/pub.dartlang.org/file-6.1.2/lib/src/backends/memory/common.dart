// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/src/common.dart' as common;

/// Generates a path to use in error messages.
typedef PathGenerator = dynamic Function();

/// Throws a `FileSystemException` if [object] is null.
void checkExists(Object? object, PathGenerator path) {
  if (object == null) {
    throw common.noSuchFileOrDirectory(path() as String);
  }
}
