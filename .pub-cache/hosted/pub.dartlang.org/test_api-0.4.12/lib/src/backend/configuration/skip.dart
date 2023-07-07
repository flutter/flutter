// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta_meta.dart';

/// An annotation for marking a test suite as skipped.
@Target({TargetKind.library})
class Skip {
  /// The reason the test suite is skipped, or `null` if no reason is given.
  final String? reason;

  /// Marks a suite as skipped.
  ///
  /// If [reason] is passed, it's included in the test output as the reason the
  /// test is skipped.
  const Skip([this.reason]);
}
