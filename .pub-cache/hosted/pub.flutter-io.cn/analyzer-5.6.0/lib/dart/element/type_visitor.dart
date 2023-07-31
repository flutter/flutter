// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';

/// Interface for type visitors.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class TypeVisitor<R> {
  const TypeVisitor();

  R visitDynamicType(DynamicType type);

  R visitFunctionType(FunctionType type);

  R visitInterfaceType(InterfaceType type);

  R visitNeverType(NeverType type);

  R visitRecordType(RecordType type);

  R visitTypeParameterType(TypeParameterType type);

  R visitVoidType(VoidType type);
}

/// Interface for type visitors that have one argument.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class TypeVisitorWithArgument<R, A> {
  const TypeVisitorWithArgument();

  R visitDynamicType(DynamicType type, A argument);

  R visitFunctionType(FunctionType type, A argument);

  R visitInterfaceType(InterfaceType type, A argument);

  R visitNeverType(NeverType type, A argument);

  R visitRecordType(RecordType type, A argument);

  R visitTypeParameterType(TypeParameterType type, A argument);

  R visitVoidType(VoidType type, A argument);
}

/// Invokes [visitDartType] from any other `visitXyz` method.
///
/// Clients may extend this class.
abstract class UnifyingTypeVisitor<R> implements TypeVisitor<R> {
  const UnifyingTypeVisitor();

  /// By default other `visitXyz` methods invoke this method.
  R visitDartType(DartType type);

  @override
  R visitDynamicType(DynamicType type) => visitDartType(type);

  @override
  R visitFunctionType(FunctionType type) => visitDartType(type);

  @override
  R visitInterfaceType(InterfaceType type) => visitDartType(type);

  @override
  R visitNeverType(NeverType type) => visitDartType(type);

  @override
  R visitTypeParameterType(TypeParameterType type) => visitDartType(type);

  @override
  R visitVoidType(VoidType type) => visitDartType(type);
}

/// Invokes [visitDartType] from any other `visitXyz` method.
///
/// Clients may extend this class.
abstract class UnifyingTypeVisitorWithArgument<R, A>
    implements TypeVisitorWithArgument<R, A> {
  const UnifyingTypeVisitorWithArgument();

  /// By default other `visitXyz` methods invoke this method.
  R visitDartType(DartType type, A argument);

  @override
  R visitDynamicType(DynamicType type, A argument) {
    return visitDartType(type, argument);
  }

  @override
  R visitFunctionType(FunctionType type, A argument) {
    return visitDartType(type, argument);
  }

  @override
  R visitInterfaceType(InterfaceType type, A argument) {
    return visitDartType(type, argument);
  }

  @override
  R visitNeverType(NeverType type, A argument) {
    return visitDartType(type, argument);
  }

  @override
  R visitTypeParameterType(TypeParameterType type, A argument) {
    return visitDartType(type, argument);
  }

  @override
  R visitVoidType(VoidType type, A argument) {
    return visitDartType(type, argument);
  }
}
