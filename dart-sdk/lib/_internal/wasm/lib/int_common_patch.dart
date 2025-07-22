// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;

@patch
class int {
  @patch
  external const factory int.fromEnvironment(
    String name, {
    int defaultValue = 0,
  });
}
