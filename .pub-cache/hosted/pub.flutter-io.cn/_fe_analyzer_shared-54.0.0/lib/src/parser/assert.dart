// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.parser.Assert;

/// Syntactic forms of `assert`.
///
/// An assertion can legally occur as a statement. However, assertions are also
/// experimentally allowed in initializers. For improved error recovery, we
/// also attempt to parse asserts as expressions.
enum Assert {
  Expression,
  Initializer,
  Statement,
}
