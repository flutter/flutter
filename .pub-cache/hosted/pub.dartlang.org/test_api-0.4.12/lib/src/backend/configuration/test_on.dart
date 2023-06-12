// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta_meta.dart';

/// An annotation indicating which platforms a test suite supports.
///
/// For the full syntax of [expression], see [the README][].
///
/// [the README]: https://github.com/dart-lang/test/tree/master/pkgs/test#platform-selectors
@Target({TargetKind.library})
class TestOn {
  /// The expression specifying the platform.
  final String expression;

  const TestOn(this.expression);
}
