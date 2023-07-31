// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';

/// Abstraction layer allowing the mechanism for looking up the types of
/// elements to be customized.
///
/// This is needed for the NNBD migration engine, which needs to analyze
/// NNBD-disabled code as though it has NNBD enabled.
///
/// This base class implementation gets types directly from the elements; for
/// other behaviors, create a class that extends or implements this class.
///
/// Getters in the ElementImpl classes are automatically wired into this
/// indirection mechanism, so it should be transparent to clients, as well as
/// most analyzer internal code.
class ElementTypeProvider {
  /// The [ElementTypeProvider] currently in use.  Change this value to cause
  /// element types to be looked up in a different way.
  static ElementTypeProvider current = const ElementTypeProvider();

  const ElementTypeProvider();

  /// Notifies the [ElementTypeProvider] that a fresh type parameter element has
  /// been created.  If the [ElementTypeProvider] is storing additional
  /// information about type parameter elements, this gives it an opportunity to
  /// copy that information.
  void freshTypeParameterCreated(TypeParameterElement newTypeParameter,
      TypeParameterElement oldTypeParameter) {}

  List<InterfaceType> getClassInterfaces(AbstractClassElementImpl element) =>
      element.interfacesInternal;

  /// Queries the parameters of an executable element's signature.
  ///
  /// Equivalent to `getExecutableType(...).parameters`.
  List<ParameterElement> getExecutableParameters(
          ExecutableElementImpl element) =>
      element.parametersInternal;

  /// Queries the return type of an executable element.
  ///
  /// Equivalent to `getExecutableType(...).returnType`.
  DartType getExecutableReturnType(ElementImplWithFunctionType element) =>
      element.returnTypeInternal;

  /// Queries the full type of an executable element.
  ///
  /// Guaranteed to be a function type.
  FunctionType getExecutableType(ElementImplWithFunctionType element) =>
      element.typeInternal;

  DartType getExtendedType(ExtensionElementImpl element) =>
      element.extendedTypeInternal;

  /// Queries the type of a field.
  DartType getFieldType(PropertyInducingElementImpl element) =>
      element.typeInternal;

  /// Queries the bound of a type parameter.
  DartType? getTypeParameterBound(TypeParameterElementImpl element) =>
      element.boundInternal;

  /// Queries the type of a variable element.
  DartType getVariableType(VariableElementImpl variable) =>
      variable.typeInternal;

  /// Queries whether NNBD is enabled for a library.
  bool isLibraryNonNullableByDefault(LibraryElementImpl element) =>
      element.isNonNullableByDefaultInternal;
}
