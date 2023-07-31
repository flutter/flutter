// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// A set of options related to coding style that apply to the code within a
/// single analysis context.
///
/// Clients may not extend, implement or mix-in this class.
abstract class CodeStyleOptions {
  /// Return `true` if the `require_trailing_commas` is enabled and trailing
  /// commas should be inserted in function calls and declarations.
  bool get addTrailingCommas;

  /// Return `true` if local variables should be `final` whenever possible.
  bool get makeLocalsFinal;

  /// Return the preferred quote based on the enabled lints, otherwise a single
  /// quote.
  String get preferredQuoteForStrings;

  /// Return `true` if constructors should be sorted first, before other
  /// class members.
  bool get sortConstructorsFirst;

  /// Return `true` if types should be specified whenever possible.
  bool get specifyTypes;

  /// Return `true` if the formatter should be used on code changes in this
  /// context.
  bool get useFormatter;

  /// Return `true` if URIs should be "relative", meaning without a scheme,
  /// whenever possible.
  bool get useRelativeUris;

  /// Return the preferred quote based on the enabled lints, otherwise based
  /// on the most common quote, otherwise a single quote.
  String preferredQuoteForUris(List<NamespaceDirective> directives);
}
