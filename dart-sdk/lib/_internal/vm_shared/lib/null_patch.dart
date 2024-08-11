// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;

@patch
@pragma('vm:deeply-immutable')
@pragma("vm:entry-point")
class Null {
  static const _HASH_CODE = 2011; // The year Dart was announced and a prime.

  @patch
  int get hashCode => _HASH_CODE;

  int get _identityHashCode => _HASH_CODE;
}
