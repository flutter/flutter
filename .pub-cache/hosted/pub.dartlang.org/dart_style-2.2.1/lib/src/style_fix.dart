// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file

// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Enum-like class for the different syntactic fixes that can be applied while
/// formatting.
class StyleFix {
  static const docComments = StyleFix._(
      'doc-comments', 'Use triple slash for documentation comments.');

  static const functionTypedefs = StyleFix._(
      'function-typedefs', 'Use new syntax for function type typedefs.');

  static const namedDefaultSeparator = StyleFix._('named-default-separator',
      'Use "=" as the separator before named parameter default values.');

  static const optionalConst = StyleFix._(
      'optional-const', 'Remove "const" keyword inside constant context.');

  static const optionalNew =
      StyleFix._('optional-new', 'Remove "new" keyword.');

  static const singleCascadeStatements = StyleFix._('single-cascade-statements',
      'Remove unnecessary single cascades from expression statements.');

  static const all = [
    docComments,
    functionTypedefs,
    namedDefaultSeparator,
    optionalConst,
    optionalNew,
    singleCascadeStatements,
  ];

  final String name;
  final String description;

  const StyleFix._(this.name, this.description);
}
