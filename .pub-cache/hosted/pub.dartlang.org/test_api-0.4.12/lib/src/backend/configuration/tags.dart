// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta_meta.dart';

/// An annotation for applying a set of user-defined tags to a test suite.
///
/// See [the documentation on tagging tests][tagging tests].
///
/// [tagging tests]: https://github.com/dart-lang/test/blob/master/pkgs/test/README.md#tagging-tests
@Target({TargetKind.library})
class Tags {
  /// The tags for the test suite.
  Set<String> get tags => _tags.toSet();

  final Iterable<String> _tags;

  /// Applies a set of user-defined tags to a test suite.
  const Tags(this._tags);
}
