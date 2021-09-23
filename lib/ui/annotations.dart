// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


// @dart = 2.12
part of dart.ui;

// TODO(dnfield): Update this if/when we default this to on in the tool,
// see: https://github.com/flutter/flutter/issues/52759
/// Annotation used by Flutter's Dart compiler to indicate that an
/// [Object.toString] override should not be replaced with a supercall.
///
/// Since `dart:ui` and `package:flutter` override `toString` purely for
/// debugging purposes, the frontend compiler is instructed to replace all
/// `toString` bodies with `return super.toString()` during compilation. This
/// significantly reduces release code size, and would make it impossible to
/// implement a meaningful override of `toString` for release mode without
/// disabling the feature and losing the size savings. If a package uses this
/// feature and has some unavoidable need to keep the `toString` implementation
/// for a specific class, applying this annotation will direct the compiler
/// to leave the method body as-is.
///
/// For example, in the following class the `toString` method will remain as
/// `return _buffer.toString();`, even if the  `--delete-tostring-package-uri`
/// option would otherwise apply and replace it with `return super.toString()`.
///
/// ```dart
/// class MyStringBuffer {
///   StringBuffer _buffer = StringBuffer();
///
///   // ...
///
///   @keepToString
///   @override
///   String toString() {
///     return _buffer.toString();
///   }
/// }
/// ```
const pragma keepToString = pragma('flutter:keep-to-string');
