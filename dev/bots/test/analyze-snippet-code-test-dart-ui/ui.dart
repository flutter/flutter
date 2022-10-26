// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12

// This is a dummy dart:ui package for the sample code analyzer tests to use.

library dart.ui;

/// Bla bla bla bla bla bla bla bla bla.
///
/// ```dart
/// class MyStringBuffer {
///   error; // error (missing_const_final_var_or_type, always_specify_types)
///
///   StringBuffer _buffer = StringBuffer(); // error (prefer_final_fields, unused_field)
/// }
/// ```
class Foo {
  const Foo();
}
