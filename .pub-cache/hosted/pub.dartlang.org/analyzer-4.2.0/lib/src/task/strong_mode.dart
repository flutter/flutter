// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:collection/collection.dart';

/// An object used to infer the type of instance fields and the return types of
/// instance methods within a single compilation unit.
class InstanceMemberInferrer {
  final InheritanceManager3 inheritance;
  final Set<ClassElement> elementsBeingInferred = HashSet<ClassElement>();

  late TypeSystemImpl typeSystem;
  late bool isNonNullableByDefault;
  late ClassElement currentClassElement;

  /// Initialize a newly create inferrer.
  InstanceMemberInferrer(this.inheritance);

  DartType get _dynamicType => DynamicTypeImpl.instance;

  /// Infer type information for all of the instance members in the given
  /// compilation [unit].
  void inferCompilationUnit(CompilationUnitElement unit) {
    typeSystem = unit.library.typeSystem as TypeSystemImpl;
    isNonNullableByDefault = typeSystem.isNonNullableByDefault;
    _inferClasses(unit.classes);
    _inferClasses(unit.mixins);
  }

  /// Return `true` if the elements corresponding to the [elements] have the
  /// same kind as the [element].
  bool _allSameElementKind(
      ExecutableElement element, List<ExecutableElement> elements) {
    var elementKind = element.kind;
    for (int i = 0; i < elements.length; i++) {
      if (elements[i].kind != elementKind) {
        return false;
      }
    }
    return true;
  }

  /// Given a method, return the parameter in the method that corresponds to the
  /// given [parameter]. If the parameter is positional, then it appears at the
  /// given [index] in its enclosing element's list of parameters.
  ParameterElement? _getCorrespondingParameter(ParameterElement parameter,
      int index, List<ParameterElement> methodParameters) {
    //
    // Find the corresponding parameter.
    //
    if (parameter.isNamed) {
      //
      // If we're looking for a named parameter, only a named parameter with
      // the same name will be matched.
      //
      return methodParameters.lastWhereOrNull(
          (ParameterElement methodParameter) =>
              methodParameter.isNamed &&
              methodParameter.name == parameter.name);
    }
    //
    // If we're looking for a positional parameter we ignore the difference
    // between required and optional parameters.
    //
    if (index < methodParameters.length) {
      var matchingParameter = methodParameters[index];
      if (!matchingParameter.isNamed) {
        return matchingParameter;
      }
    }
    return null;
  }

  /// If the given [accessor] represents a non-synthetic instance property
  /// accessor for which no type was provided, infer its types.
  ///
  /// If the given [field] represents a non-synthetic instance field for
  /// which no type was provided, infer the type of the field.
  void _inferAccessorOrField({
    PropertyAccessorElementImpl? accessor,
    FieldElementImpl? field,
  }) {
    Uri elementLibraryUri;
    String elementName;

    if (accessor != null) {
      if (accessor.isSynthetic || accessor.isStatic) {
        return;
      }
      elementLibraryUri = accessor.library.source.uri;
      elementName = accessor.displayName;
    } else if (field != null) {
      if (field.isSynthetic || field.isStatic) {
        return;
      }
      elementLibraryUri = field.library.source.uri;
      elementName = field.name;
    } else {
      throw UnimplementedError();
    }

    var getterName = Name(elementLibraryUri, elementName);
    var overriddenGetters = inheritance.getOverridden2(
      currentClassElement,
      getterName,
    );
    if (overriddenGetters != null) {
      overriddenGetters = overriddenGetters.where((e) {
        return e is PropertyAccessorElement && e.isGetter;
      }).toList();
    } else {
      overriddenGetters = const [];
    }

    var setterName = Name(elementLibraryUri, '$elementName=');
    var overriddenSetters = inheritance.getOverridden2(
      currentClassElement,
      setterName,
    );
    overriddenSetters ??= const [];

    DartType combinedGetterType() {
      var combinedGetter = inheritance.combineSignatures(
        targetClass: currentClassElement,
        candidates: overriddenGetters!,
        doTopMerge: true,
        name: getterName,
      );
      if (combinedGetter != null) {
        var returnType = combinedGetter.returnType;
        return typeSystem.nonNullifyLegacy(returnType);
      }
      return DynamicTypeImpl.instance;
    }

    DartType combinedSetterType() {
      var combinedSetter = inheritance.combineSignatures(
        targetClass: currentClassElement,
        candidates: overriddenSetters!,
        doTopMerge: true,
        name: setterName,
      );
      if (combinedSetter != null) {
        var parameters = combinedSetter.parameters;
        if (parameters.isNotEmpty) {
          var type = parameters[0].type;
          return typeSystem.nonNullifyLegacy(type);
        }
      }
      return DynamicTypeImpl.instance;
    }

    if (accessor != null && accessor.isGetter) {
      if (!accessor.hasImplicitReturnType) {
        return;
      }

      // The return type of a getter, parameter type of a setter or type of a
      // field which overrides/implements only one or more getters is inferred
      // to be the return type of the combined member signature of said getter
      // in the direct superinterfaces.
      //
      // The return type of a getter which overrides/implements both a setter
      // and a getter is inferred to be the return type of the combined member
      // signature of said getter in the direct superinterfaces.
      if (overriddenGetters.isNotEmpty) {
        accessor.returnType = combinedGetterType();
        return;
      }

      // The return type of a getter, parameter type of a setter or type of
      // field which overrides/implements only one or more setters is inferred
      // to be the parameter type of the combined member signature of said
      // setter in the direct superinterfaces.
      if (overriddenGetters.isEmpty && overriddenSetters.isNotEmpty) {
        accessor.returnType = combinedSetterType();
        return;
      }

      return;
    }

    if (accessor != null && accessor.isSetter) {
      var parameters = accessor.parameters;
      if (parameters.isEmpty) {
        return;
      }
      var parameter = parameters[0] as ParameterElementImpl;

      if (overriddenSetters.any(_isCovariantSetter)) {
        parameter.inheritsCovariant = true;
      }

      if (!parameter.hasImplicitType) {
        return;
      }

      // The return type of a getter, parameter type of a setter or type of a
      // field which overrides/implements only one or more getters is inferred
      // to be the return type of the combined member signature of said getter
      // in the direct superinterfaces.
      if (overriddenGetters.isNotEmpty && overriddenSetters.isEmpty) {
        parameter.type = combinedGetterType();
        return;
      }

      // The return type of a getter, parameter type of a setter or type of
      // field which overrides/implements only one or more setters is inferred
      // to be the parameter type of the combined member signature of said
      // setter in the direct superinterfaces.
      //
      // The parameter type of a setter which overrides/implements both a
      // setter and a getter is inferred to be the parameter type of the
      // combined member signature of said setter in the direct superinterfaces.
      if (overriddenSetters.isNotEmpty) {
        parameter.type = combinedSetterType();
        return;
      }

      return;
    }

    if (field != null) {
      if (field.setter != null) {
        if (overriddenSetters.any(_isCovariantSetter)) {
          var parameter = field.setter!.parameters[0] as ParameterElementImpl;
          parameter.inheritsCovariant = true;
        }
      }

      if (!field.hasImplicitType) {
        return;
      }

      // The return type of a getter, parameter type of a setter or type of a
      // field which overrides/implements only one or more getters is inferred
      // to be the return type of the combined member signature of said getter
      // in the direct superinterfaces.
      if (overriddenGetters.isNotEmpty && overriddenSetters.isEmpty) {
        field.type = combinedGetterType();
        field.hasTypeInferred = true;
        return;
      }

      // The return type of a getter, parameter type of a setter or type of
      // field which overrides/implements only one or more setters is inferred
      // to be the parameter type of the combined member signature of said
      // setter in the direct superinterfaces.
      if (overriddenGetters.isEmpty && overriddenSetters.isNotEmpty) {
        var type = combinedSetterType();
        _setFieldType(field, type);
        return;
      }

      if (overriddenGetters.isNotEmpty && overriddenSetters.isNotEmpty) {
        // The type of a final field which overrides/implements both a setter
        // and a getter is inferred to be the return type of the combined
        // member signature of said getter in the direct superinterfaces.
        if (field.isFinal) {
          var type = combinedGetterType();
          _setFieldType(field, type);
          return;
        }

        // The type of a non-final field which overrides/implements both a
        // setter and a getter is inferred to be the parameter type of the
        // combined member signature of said setter in the direct
        // superinterfaces, if this type is the same as the return type of the
        // combined member signature of said getter in the direct
        // superinterfaces. If the types are not the same then inference
        // fails with an error.
        if (!field.isFinal) {
          var getterType = combinedGetterType();
          var setterType = combinedSetterType();

          if (getterType == setterType) {
            var type = getterType;
            type = typeSystem.nonNullifyLegacy(type);
            _setFieldType(field, type);
          } else {
            field.typeInferenceError = TopLevelInferenceError(
              kind: TopLevelInferenceErrorKind.overrideConflictFieldType,
              arguments: const <String>[],
            );
          }
          return;
        }
      }

      // Otherwise, declarations of static variables and fields that omit a
      // type will be inferred from their initializer if present.
      field.typeInference?.perform();

      return;
    }
  }

  /// Infer type information for all of the instance members in the given
  /// [classElement].
  void _inferClass(ClassElement classElement) {
    if (classElement is ClassElementImpl) {
      if (classElement.hasBeenInferred) {
        return;
      }
      if (!elementsBeingInferred.add(classElement)) {
        // We have found a circularity in the class hierarchy. For now we just
        // stop trying to infer any type information for any classes that
        // inherit from any class in the cycle. We could potentially limit the
        // algorithm to only not inferring types in the classes in the cycle,
        // but it isn't clear that the results would be significantly better.
        throw _CycleException();
      }
      try {
        //
        // Ensure that all of instance members in the supertypes have had types
        // inferred for them.
        //
        _inferType(classElement.supertype);
        classElement.mixins.forEach(_inferType);
        classElement.interfaces.forEach(_inferType);
        classElement.superclassConstraints.forEach(_inferType);
        //
        // Then infer the types for the members.
        //
        currentClassElement = classElement;
        for (var field in classElement.fields) {
          _inferAccessorOrField(
            field: field as FieldElementImpl,
          );
        }
        for (var accessor in classElement.accessors) {
          _inferAccessorOrField(
            accessor: accessor as PropertyAccessorElementImpl,
          );
        }
        for (var method in classElement.methods) {
          _inferExecutable(method as MethodElementImpl);
        }
        //
        // Infer initializing formal parameter types. This must happen after
        // field types are inferred.
        //
        classElement.constructors.forEach(_inferConstructorFieldFormals);
        classElement.hasBeenInferred = true;
      } finally {
        elementsBeingInferred.remove(classElement);
      }
    }
  }

  void _inferClasses(List<ClassElement> elements) {
    for (ClassElement element in elements) {
      try {
        _inferClass(element);
      } on _CycleException {
        // This is a short circuit return to prevent types that inherit from
        // types containing a circular reference from being inferred.
      }
    }
  }

  void _inferConstructorFieldFormals(ConstructorElement constructor) {
    for (ParameterElement parameter in constructor.parameters) {
      if (parameter.hasImplicitType &&
          parameter is FieldFormalParameterElementImpl) {
        var field = parameter.field;
        if (field != null) {
          parameter.type = field.type;
        }
      }
    }
  }

  /// If the given [element] represents a non-synthetic instance method,
  /// getter or setter, infer the return type and any parameter type(s) where
  /// they were not provided.
  void _inferExecutable(MethodElementImpl element) {
    if (element.isSynthetic || element.isStatic) {
      return;
    }

    var name = Name(element.library.source.uri, element.name);
    var overriddenElements = inheritance.getOverridden2(
      currentClassElement,
      name,
    );
    if (overriddenElements == null ||
        !_allSameElementKind(element, overriddenElements)) {
      return;
    }

    FunctionType? combinedSignatureType;
    var hasImplicitType = element.hasImplicitReturnType ||
        element.parameters.any((e) => e.hasImplicitType);
    if (hasImplicitType) {
      var conflicts = <Conflict>[];
      var combinedSignature = inheritance.combineSignatures(
        targetClass: currentClassElement,
        candidates: overriddenElements,
        doTopMerge: true,
        name: name,
        conflicts: conflicts,
      );
      if (combinedSignature != null) {
        combinedSignatureType = _toOverriddenFunctionType(
          element,
          combinedSignature,
        );
        if (combinedSignatureType != null) {}
      } else {
        var conflictExplanation = '<unknown>';
        if (conflicts.length == 1) {
          var conflict = conflicts.single;
          if (conflict is CandidatesConflict) {
            conflictExplanation = conflict.candidates.map((candidate) {
              var className = candidate.enclosingElement.name;
              var typeStr = candidate.type.getDisplayString(
                withNullability: typeSystem.isNonNullableByDefault,
              );
              return '$className.${name.name} ($typeStr)';
            }).join(', ');
          }
        }

        element.typeInferenceError = TopLevelInferenceError(
          kind: TopLevelInferenceErrorKind.overrideNoCombinedSuperSignature,
          arguments: [conflictExplanation],
        );
      }
    }

    //
    // Infer the return type.
    //
    if (element.hasImplicitReturnType && element.displayName != '[]=') {
      if (combinedSignatureType != null) {
        var returnType = combinedSignatureType.returnType;
        returnType = typeSystem.nonNullifyLegacy(returnType);
        element.returnType = returnType;
      } else {
        element.returnType = DynamicTypeImpl.instance;
      }
    }

    //
    // Infer the parameter types.
    //
    List<ParameterElement> parameters = element.parameters;
    for (var index = 0; index < parameters.length; index++) {
      ParameterElement parameter = parameters[index];
      if (parameter is ParameterElementImpl) {
        _inferParameterCovariance(parameter, index, overriddenElements);

        if (parameter.hasImplicitType) {
          _inferParameterType(parameter, index, combinedSignatureType);
        }
      }
    }

    _resetOperatorEqualParameterTypeToDynamic(element, overriddenElements);
  }

  /// If a parameter is covariant, any parameters that override it are too.
  void _inferParameterCovariance(ParameterElementImpl parameter, int index,
      Iterable<ExecutableElement> overridden) {
    parameter.inheritsCovariant = overridden.any((f) {
      var param = _getCorrespondingParameter(parameter, index, f.parameters);
      return param != null && param.isCovariant;
    });
  }

  /// Set the type for the [parameter] at the given [index] from the given
  /// [combinedSignatureType], which might be `null` if there is no valid
  /// combined signature for signatures from direct superinterfaces.
  void _inferParameterType(ParameterElementImpl parameter, int index,
      FunctionType? combinedSignatureType) {
    if (combinedSignatureType != null) {
      var matchingParameter = _getCorrespondingParameter(
        parameter,
        index,
        combinedSignatureType.parameters,
      );
      if (matchingParameter != null) {
        var type = matchingParameter.type;
        type = typeSystem.nonNullifyLegacy(type);
        parameter.type = type;
      } else {
        parameter.type = DynamicTypeImpl.instance;
      }
    } else {
      parameter.type = DynamicTypeImpl.instance;
    }
  }

  /// Infer type information for all of the instance members in the given
  /// interface [type].
  void _inferType(InterfaceType? type) {
    if (type != null) {
      _inferClass(type.element);
    }
  }

  /// In legacy mode, an override of `operator==` with no explicit parameter
  /// type inherits the parameter type of the overridden method if any override
  /// of `operator==` between the overriding method and `Object.==` has an
  /// explicit parameter type.  Otherwise, the parameter type of the
  /// overriding method is `dynamic`.
  ///
  /// https://github.com/dart-lang/language/issues/569
  void _resetOperatorEqualParameterTypeToDynamic(
    MethodElementImpl element,
    List<ExecutableElement> overriddenElements,
  ) {
    if (element.name != '==') return;

    var parameters = element.parameters;
    if (parameters.length != 1) {
      element.isOperatorEqualWithParameterTypeFromObject = false;
      return;
    }

    var parameter = parameters[0] as ParameterElementImpl;
    if (!parameter.hasImplicitType) {
      element.isOperatorEqualWithParameterTypeFromObject = false;
      return;
    }

    for (var overridden in overriddenElements) {
      overridden = overridden.declaration;

      // Skip Object itself.
      var enclosingElement = overridden.enclosingElement;
      if (enclosingElement is ClassElement &&
          enclosingElement.isDartCoreObject) {
        continue;
      }

      // Keep the type if it is not directly from Object.
      if (overridden is MethodElementImpl &&
          !overridden.isOperatorEqualWithParameterTypeFromObject) {
        element.isOperatorEqualWithParameterTypeFromObject = false;
        return;
      }
    }

    // Reset the type.
    if (!isNonNullableByDefault) {
      parameter.type = _dynamicType;
    }
    element.isOperatorEqualWithParameterTypeFromObject = true;
  }

  /// Return the [FunctionType] of the [overriddenElement] that [element]
  /// overrides. Return `null`, in case of type parameters inconsistency.
  ///
  /// The overridden element must have the same number of generic type
  /// parameters as the target element, or none.
  ///
  /// If we do have generic type parameters on the element we're inferring,
  /// we must express its parameter and return types in terms of its own
  /// parameters. For example, given `m<T>(t)` overriding `m<S>(S s)` we
  /// should infer this as `m<T>(T t)`.
  FunctionType? _toOverriddenFunctionType(
      ExecutableElement element, ExecutableElement overriddenElement) {
    var elementTypeParameters = element.typeParameters;
    var overriddenTypeParameters = overriddenElement.typeParameters;

    if (elementTypeParameters.length != overriddenTypeParameters.length) {
      return null;
    }

    var overriddenType = overriddenElement.type as FunctionTypeImpl;
    if (elementTypeParameters.isEmpty) {
      return overriddenType;
    }

    return replaceTypeParameters(overriddenType, elementTypeParameters);
  }

  static bool _isCovariantSetter(ExecutableElement element) {
    if (element is PropertyAccessorElement) {
      var parameters = element.parameters;
      return parameters.isNotEmpty && parameters[0].isCovariant;
    }
    return false;
  }

  static void _setFieldType(FieldElementImpl field, DartType type) {
    field.type = type;
    field.hasTypeInferred = true;
  }
}

/// A class of exception that is not used anywhere else.
class _CycleException implements Exception {}
