// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12

// This is a dummy dart:ui package for the sample code analyzer tests to use.

library dart.ui;

/// Annotation used by Flutter's Dart compiler to indicate that an
/// [Object.toString] override should not be replaced with a supercall.
///
/// {@tool sample --template=stateless_widget_material}
/// A sample if using keepToString to prevent replacement by a supercall.
///
/// ```dart
/// class MyStringBuffer {
///   error;
///
///   StringBuffer _buffer = StringBuffer();
///
///   @keepToString
///   @override
///   String toString() {
///     return _buffer.toString();
///   }
/// }
/// ```
/// {@end-tool}
const Object keepToString = _KeepToString();

class _KeepToString {
  const _KeepToString();
}
