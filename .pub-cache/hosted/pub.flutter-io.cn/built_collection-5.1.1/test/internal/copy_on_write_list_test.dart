// Copyright (c) 2016, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/src/internal/copy_on_write_list.dart';
import 'package:test/test.dart';

void main() {
  group('CopyOnWriteList', () {
    test('has toString equal to List.toString', () {
      var list = <int>[1, 2, 3];
      expect(CopyOnWriteList(list, false).toString(), list.toString());
    });
  });
}
