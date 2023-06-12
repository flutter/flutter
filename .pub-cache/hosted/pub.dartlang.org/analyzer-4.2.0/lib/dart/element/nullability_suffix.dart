// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Suffix indicating the nullability of a type.
///
/// This enum describes whether a `?` or `*` would be used at the end of the
/// canonical representation of a type.  It's subtly different the notions of
/// "nullable", "non-nullable", "potentially nullable", and "potentially
/// non-nullable" defined by the spec.  For example, the type `Null` is
/// nullable, even though it lacks a trailing `?`.
enum NullabilitySuffix {
  /// An indication that the canonical representation of the type under
  /// consideration ends with `?`.  Types having this nullability suffix should
  /// be interpreted as being unioned with the Null type.
  question,

  /// An indication that the canonical representation of the type under
  /// consideration ends with `*`.  Types having this nullability suffix are
  /// called "legacy types"; it has not yet been determined whether they should
  /// be unioned with the Null type.
  star,

  /// An indication that the canonical representation of the type under
  /// consideration does not end with either `?` or `*`.
  none
}
