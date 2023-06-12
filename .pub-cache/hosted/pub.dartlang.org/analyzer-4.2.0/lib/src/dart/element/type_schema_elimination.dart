// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/replacement_visitor.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';

/// Visitor that computes least and greatest closures of a type schema.
///
/// Each visitor method returns `null` if there are no `_`s contained in the
/// type, otherwise it returns the result of substituting `_` with [_bottomType]
/// or [_topType], as appropriate.
class TypeSchemaEliminationVisitor extends ReplacementVisitor {
  final DartType _topType;
  final DartType _bottomType;

  bool _isLeastClosure;

  TypeSchemaEliminationVisitor._(
    this._topType,
    this._bottomType,
    this._isLeastClosure,
  );

  @override
  void changeVariance() {
    _isLeastClosure = !_isLeastClosure;
  }

  @override
  DartType visitUnknownInferredType(UnknownInferredType type) {
    return _isLeastClosure ? _bottomType : _topType;
  }

  /// Runs an instance of the visitor on the given [schema] and returns the
  /// resulting type.  If the schema contains no instances of `_`, the original
  /// schema object is returned to avoid unnecessary allocation.
  static DartType run({
    required DartType topType,
    required DartType bottomType,
    required bool isLeastClosure,
    required DartType schema,
  }) {
    var visitor = TypeSchemaEliminationVisitor._(
      topType,
      bottomType,
      isLeastClosure,
    );
    var result = schema.accept(visitor);
    assert(visitor._isLeastClosure == isLeastClosure);
    return result ?? schema;
  }
}
