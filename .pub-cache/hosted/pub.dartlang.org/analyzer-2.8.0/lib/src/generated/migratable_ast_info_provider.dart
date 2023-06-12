// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// Abstraction layer allowing the NNBD migration engine to customize the
/// mechanism for looking up various pieces of information AST nodes.
///
/// The information that is abstracted is precisely the information that the
/// migration process might change, for example the elements of collections
/// (which might disappear or change due to dead code elimination) and whether
/// or not a property access is null aware.
///
/// This base class implementation gets elements directly from the AST nodes;
/// for other behaviors, create a class that extends or implements this class.
class MigratableAstInfoProvider {
  const MigratableAstInfoProvider();

  /// Gets the elements contained in a [ListLiteral].
  List<CollectionElement> getListElements(ListLiteral node) => node.elements;

  /// Gets the elements contained in a [SetOrMapLiteral].
  List<CollectionElement> getSetOrMapElements(SetOrMapLiteral node) =>
      node.elements;

  /// Queries whether the given [node] is null-aware.
  bool isIndexExpressionNullAware(IndexExpression node) => node.isNullAware;

  /// Queries whether the given [node] is null-aware.
  bool isMethodInvocationNullAware(MethodInvocation node) => node.isNullAware;

  /// Queries whether the given [node] is null-aware.
  bool isPropertyAccessNullAware(PropertyAccess node) => node.isNullAware;
}
