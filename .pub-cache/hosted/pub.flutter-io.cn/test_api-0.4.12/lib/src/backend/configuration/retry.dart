// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta_meta.dart';

/// An annotation for marking a test suite to be retried.
///
/// A suite-level retry configuration will enable retries for every test in the
/// suite, unless the group or test is configured with a more specific retry.
@Target({TargetKind.library})
class Retry {
  /// The number of times the tests in the suite will be retried.
  final int count;

  /// Marks all tests in a test suite to be retried.
  const Retry(this.count);
}
