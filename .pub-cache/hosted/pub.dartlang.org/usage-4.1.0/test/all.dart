// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.all_test;

import 'hit_types_test.dart' as hit_types_test;
import 'usage_impl_io_test.dart' as usage_impl_io_test;
import 'usage_impl_test.dart' as usage_impl_test;
import 'usage_test.dart' as usage_test;
import 'uuid_test.dart' as uuid_test;

void main() {
  hit_types_test.defineTests();
  usage_impl_io_test.defineTests();
  usage_impl_test.defineTests();
  usage_test.defineTests();
  uuid_test.defineTests();
}
