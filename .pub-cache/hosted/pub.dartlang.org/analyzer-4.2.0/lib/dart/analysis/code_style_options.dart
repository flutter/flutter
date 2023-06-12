// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A set of options related to coding style that apply to the code within a
/// single analysis context.
///
/// Clients may not extend, implement or mix-in this class.
abstract class CodeStyleOptions {
  /// Return `true` if local variables should be `final` whenever possible.
  bool get makeLocalsFinal;

  /// Return `true` if the formatter should be used on code changes in this
  /// context.
  bool get useFormatter;

  /// Return `true` if URIs should be "relative", meaning without a scheme,
  /// whenever possible.
  bool get useRelativeUris;
}
