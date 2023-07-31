// Copyright (c) 2016, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/src/internal/copy_on_write_set.dart';
import 'package:test/test.dart';

void main() {
  group('CopyOnWriteSet', () {
    test('has toString equal to Set.toString', () {
      var set = <int>{1, 2, 3};
      expect(CopyOnWriteSet(set).toString(), set.toString());
    });
  });
}
