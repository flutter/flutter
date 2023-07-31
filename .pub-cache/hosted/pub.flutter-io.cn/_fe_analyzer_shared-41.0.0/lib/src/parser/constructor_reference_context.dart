// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Enum for the context in which a constructor occurs
enum ConstructorReferenceContext {
  /// A constructor reference in the context of a constructor invocation with
  /// an explicit `new`.
  New,

  /// A constructor reference in the context of a constant constructor
  /// invocation with an explicit `const`.
  Const,

  /// A constructor reference in the context of a constructor invocation with an
  /// implicit `new` or `const`.
  Implicit,

  /// A constructor reference in the context of a redirecting factory body.
  RedirectingFactory,
}
