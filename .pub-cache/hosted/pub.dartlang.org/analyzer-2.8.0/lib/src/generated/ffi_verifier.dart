// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/error/ffi_code.dart';

/// A visitor used to find problems with the way the `dart:ffi` APIs are being
/// used. See 'pkg/vm/lib/transformations/ffi_checks.md' for the specification
/// of the desired hints.
class FfiVerifier extends RecursiveAstVisitor<void> {
  static const _allocatorClassName = 'Allocator';
  static const _allocateExtensionMethodName = 'call';
  static const _allocatorExtensionName = 'AllocatorAlloc';
  static const _arrayClassName = 'Array';
  static const _dartFfiLibraryName = 'dart.ffi';
  static const _isLeafParamName = 'isLeaf';
  static const _opaqueClassName = 'Opaque';
  static const _ffiNativeName = 'FfiNative';

  static const Set<String> _primitiveIntegerNativeTypes = {
    'Int8',
    'Int16',
    'Int32',
    'Int64',
    'Uint8',
    'Uint16',
    'Uint32',
    'Uint64',
    'IntPtr'
  };

  static const Set<String> _primitiveDoubleNativeTypes = {
    'Float',
    'Double',
  };

  static const _primitiveBoolNativeType = 'Bool';

  static const _structClassName = 'Struct';

  static const _unionClassName = 'Union';

  /// The type system used to check types.
  final TypeSystemImpl typeSystem;

  /// The error reporter used to report errors.
  final ErrorReporter _errorReporter;

  /// A flag indicating whether we are currently visiting inside a subclass of
  /// `Struct`.
  bool inCompound = false;

  /// Subclass of `Struct` or `Union` we are currently visiting, or `null`.
  ClassDeclaration? compound;

  /// Initialize a newly created verifier.
  FfiVerifier(this.typeSystem, this._errorReporter);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    inCompound = false;
    compound = null;
    // Only the Allocator, Opaque and Struct class may be extended.
    var extendsClause = node.extendsClause;
    if (extendsClause != null) {
      final NamedType superclass = extendsClause.superclass2;
      final ffiClass = superclass.ffiClass;
      if (ffiClass != null) {
        final className = ffiClass.name;
        if (className == _structClassName || className == _unionClassName) {
          inCompound = true;
          compound = node;
          if (node.declaredElement!.isEmptyStruct) {
            _errorReporter.reportErrorForNode(
                FfiCode.EMPTY_STRUCT, node.name, [node.name.name, className]);
          }
          if (className == _structClassName) {
            _validatePackedAnnotation(node.metadata);
          }
        } else if (className != _allocatorClassName &&
            className != _opaqueClassName) {
          _errorReporter.reportErrorForNode(
              FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS,
              superclass.name,
              [node.name.name, superclass.name.name]);
        }
      } else if (superclass.isCompoundSubtype) {
        _errorReporter.reportErrorForNode(
            FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS,
            superclass,
            [node.name.name, superclass.name.name]);
      }
    }

    // No classes from the FFI may be explicitly implemented.
    void checkSupertype(NamedType typename, FfiCode subtypeOfFfiCode,
        FfiCode subtypeOfStructCode) {
      final superName = typename.name.staticElement?.name;
      if (superName == _allocatorClassName) {
        return;
      }
      if (typename.ffiClass != null) {
        _errorReporter.reportErrorForNode(subtypeOfFfiCode, typename,
            [node.name.name, typename.name.toSource()]);
      } else if (typename.isCompoundSubtype) {
        _errorReporter.reportErrorForNode(subtypeOfStructCode, typename,
            [node.name.name, typename.name.toSource()]);
      }
    }

    var implementsClause = node.implementsClause;
    if (implementsClause != null) {
      for (NamedType type in implementsClause.interfaces2) {
        checkSupertype(type, FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS,
            FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS);
      }
    }
    var withClause = node.withClause;
    if (withClause != null) {
      for (NamedType type in withClause.mixinTypes2) {
        checkSupertype(type, FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH,
            FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH);
      }
    }

    if (inCompound && node.declaredElement!.typeParameters.isNotEmpty) {
      _errorReporter.reportErrorForNode(
          FfiCode.GENERIC_STRUCT_SUBCLASS, node.name, [node.name.name]);
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (!typeSystem.isNonNullableByDefault && inCompound) {
      _errorReporter.reportErrorForNode(
        FfiCode.FIELD_INITIALIZER_IN_STRUCT,
        node,
      );
    }
    super.visitConstructorFieldInitializer(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (inCompound) {
      _validateFieldsInCompound(node);
    }
    super.visitFieldDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkFfiNative(node);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    var element = node.staticElement;
    if (element is MethodElement) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement.isAllocatorExtension &&
          element.name == _allocateExtensionMethodName) {
        _validateAllocate(node);
      }
    }
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    var element = node.staticElement;
    if (element is MethodElement) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement.isNativeStructPointerExtension ||
          enclosingElement.isNativeStructArrayExtension) {
        if (element.name == '[]') {
          _validateRefIndexed(node);
        }
      }
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var constructor = node.constructorName.staticElement;
    var class_ = constructor?.enclosingElement;
    if (class_.isStructSubclass || class_.isUnionSubclass) {
      _errorReporter.reportErrorForNode(
        FfiCode.CREATION_OF_STRUCT_OR_UNION,
        node.constructorName,
      );
    }

    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _checkFfiNative(node);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var element = node.methodName.staticElement;
    if (element is MethodElement) {
      Element enclosingElement = element.enclosingElement;
      if (enclosingElement.isPointer) {
        if (element.name == 'fromFunction') {
          _validateFromFunction(node, element);
        } else if (element.name == 'elementAt') {
          _validateElementAt(node);
        }
      } else if (enclosingElement.isNativeFunctionPointerExtension) {
        if (element.name == 'asFunction') {
          _validateAsFunction(node, element);
        }
      } else if (enclosingElement.isDynamicLibraryExtension) {
        if (element.name == 'lookupFunction') {
          _validateLookupFunction(node);
        }
      }
    } else if (element is FunctionElement) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement is CompilationUnitElement) {
        if (element.library.name == 'dart.ffi') {
          if (element.name == 'sizeOf') {
            _validateSizeOf(node);
          }
        }
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    var element = node.staticElement;
    if (element != null) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement.isNativeStructPointerExtension) {
        if (element.name == 'ref') {
          _validateRefPrefixedIdentifier(node);
        }
      }
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    var element = node.propertyName.staticElement;
    if (element != null) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement.isNativeStructPointerExtension) {
        if (element.name == 'ref') {
          _validateRefPropertyAccess(node);
        }
      }
    }
    super.visitPropertyAccess(node);
  }

  void _checkFfiNative(Declaration node) {
    NodeList<Annotation> annotations = node.metadata;
    if (annotations.isEmpty) {
      return;
    }

    for (Annotation annotation in annotations) {
      if (annotation.name.name != _ffiNativeName) {
        continue;
      }

      final NodeList<Expression> arguments = annotation.arguments!.arguments;
      final NodeList<TypeAnnotation> typeArguments =
          annotation.typeArguments!.arguments;

      final ffiSignature = typeArguments[0].type! as FunctionType;

      // Leaf call FFI Natives can't use Handles.
      _validateFfiLeafCallUsesNoHandles(arguments, ffiSignature, node);

      if (node is MethodDeclaration) {
        if (!node.declaredElement!.isExternal) {
          _errorReporter.reportErrorForNode(
              FfiCode.FFI_NATIVE_MUST_BE_EXTERNAL, node);
        }

        List<DartType> ffiParameterTypes;
        if (!node.isStatic) {
          // Instance methods must have the receiver as an extra parameter in the
          // FfiNative annotation.
          if (node.parameters!.parameters.length + 1 !=
              ffiSignature.parameters.length) {
            _errorReporter.reportErrorForNode(
                FfiCode
                    .FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER,
                node,
                [
                  node.parameters!.parameters.length + 1,
                  ffiSignature.parameters.length
                ]);
            return;
          }

          // Receiver can only be Pointer if the class extends
          // NativeFieldWrapperClass1.
          if (ffiSignature.normalParameterTypes[0].isPointer) {
            final cls = node.declaredElement!.enclosingElement as ClassElement;
            if (!_extendsNativeFieldWrapperClass1(cls.thisType)) {
              _errorReporter.reportErrorForNode(
                  FfiCode
                      .FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER,
                  node);
            }
          }

          ffiParameterTypes = ffiSignature.normalParameterTypes.sublist(1);
        } else {
          // Number of parameters in the FfiNative annotation must match the
          // annotated declaration.
          if (node.parameters!.parameters.length !=
              ffiSignature.parameters.length) {
            _errorReporter.reportErrorForNode(
                FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS, node, [
              ffiSignature.parameters.length,
              node.parameters!.parameters.length
            ]);
            return;
          }

          ffiParameterTypes = ffiSignature.normalParameterTypes;
        }

        // Arguments can only be Pointer if the class extends
        // NativeFieldWrapperClass1.
        for (var i = 0; i < node.parameters!.parameters.length; i++) {
          if (ffiParameterTypes[i].isPointer) {
            final type = node.parameters!.parameters[i].declaredElement!.type;
            if (!_extendsNativeFieldWrapperClass1(type as InterfaceType)) {
              _errorReporter.reportErrorForNode(
                  FfiCode
                      .FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER,
                  node);
            }
          }
        }

        continue;
      }

      if (node is FunctionDeclaration) {
        if (!node.declaredElement!.isExternal) {
          _errorReporter.reportErrorForNode(
              FfiCode.FFI_NATIVE_MUST_BE_EXTERNAL, node);
        }

        // Number of parameters in the FfiNative annotation must match the
        // annotated declaration.
        if (node.functionExpression.parameters!.parameters.length !=
            ffiSignature.parameters.length) {
          _errorReporter.reportErrorForNode(
              FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS, node, [
            ffiSignature.parameters.length,
            node.functionExpression.parameters!.parameters.length
          ]);
          return;
        }

        // Arguments can only be Pointer if the class extends
        // NativeFieldWrapperClass1.
        for (var i = 0;
            i < node.functionExpression.parameters!.parameters.length;
            i++) {
          if (ffiSignature.normalParameterTypes[i].isPointer) {
            final type = node.functionExpression.parameters!.parameters[i]
                .declaredElement!.type;
            if (!_extendsNativeFieldWrapperClass1(type as InterfaceType)) {
              _errorReporter.reportErrorForNode(
                  FfiCode
                      .FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER,
                  node);
            }
          }
        }
      }
    }
  }

  bool _extendsNativeFieldWrapperClass1(InterfaceType? type) {
    while (type != null) {
      if (type.getDisplayString(withNullability: false) ==
          'NativeFieldWrapperClass1') {
        return true;
      }
      type = type.element.supertype;
    }
    return false;
  }

  bool _isConst(Expression expr) {
    if (expr is Literal) {
      return true;
    }
    if (expr is Identifier) {
      final staticElm = expr.staticElement;
      if (staticElm is ConstVariableElement) {
        return true;
      }
      if (staticElm is PropertyAccessorElementImpl) {
        if (staticElm.variable is ConstVariableElement) {
          return true;
        }
      }
    }
    return false;
  }

  /// Returns `true` if [nativeType] is a C type that has a size.
  bool _isSized(DartType nativeType) {
    switch (_primitiveNativeType(nativeType)) {
      case _PrimitiveDartType.double:
        return true;
      case _PrimitiveDartType.int:
        return true;
      case _PrimitiveDartType.bool:
        return true;
      case _PrimitiveDartType.void_:
        return false;
      case _PrimitiveDartType.handle:
        return false;
      case _PrimitiveDartType.none:
        break;
    }
    if (nativeType.isCompoundSubtype) {
      return true;
    }
    if (nativeType.isPointer) {
      return true;
    }
    if (nativeType.isArray) {
      return true;
    }
    return false;
  }

  /// Validates that the given type is a valid dart:ffi native function
  /// signature.
  bool _isValidFfiNativeFunctionType(DartType nativeType) {
    if (nativeType is FunctionType && !nativeType.isDartCoreFunction) {
      if (nativeType.namedParameterTypes.isNotEmpty ||
          nativeType.optionalParameterTypes.isNotEmpty) {
        return false;
      }
      if (!_isValidFfiNativeType(nativeType.returnType,
          allowVoid: true, allowEmptyStruct: false, allowHandle: true)) {
        return false;
      }

      for (final DartType typeArg in nativeType.normalParameterTypes) {
        if (!_isValidFfiNativeType(typeArg,
            allowVoid: false, allowEmptyStruct: false, allowHandle: true)) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  /// Validates that the given [nativeType] is a valid dart:ffi native type.
  bool _isValidFfiNativeType(DartType? nativeType,
      {bool allowVoid = false,
      bool allowEmptyStruct = false,
      bool allowArray = false,
      bool allowHandle = false}) {
    if (nativeType is InterfaceType) {
      final primitiveType = _primitiveNativeType(nativeType);
      switch (primitiveType) {
        case _PrimitiveDartType.void_:
          return allowVoid;
        case _PrimitiveDartType.handle:
          return allowHandle;
        case _PrimitiveDartType.double:
        case _PrimitiveDartType.int:
        case _PrimitiveDartType.bool:
          return true;
        case _PrimitiveDartType.none:
          // These are the cases below.
          break;
      }
      if (nativeType.isNativeFunction) {
        return _isValidFfiNativeFunctionType(nativeType.typeArguments.single);
      }
      if (nativeType.isPointer) {
        final nativeArgumentType = nativeType.typeArguments.single;
        return _isValidFfiNativeType(nativeArgumentType,
                allowVoid: true, allowEmptyStruct: true, allowHandle: true) ||
            nativeArgumentType.isCompoundSubtype ||
            nativeArgumentType.isNativeType;
      }
      if (nativeType.isCompoundSubtype) {
        if (!allowEmptyStruct) {
          if (nativeType.element.isEmptyStruct) {
            // TODO(dartbug.com/36780): This results in an error message not
            // mentioning empty structs at all.
            return false;
          }
        }
        return true;
      }
      if (nativeType.isOpaqueSubtype) {
        return true;
      }
      if (allowArray && nativeType.isArray) {
        return _isValidFfiNativeType(nativeType.typeArguments.single,
            allowVoid: false, allowEmptyStruct: false);
      }
    } else if (nativeType is FunctionType) {
      return _isValidFfiNativeFunctionType(nativeType);
    }
    return false;
  }

  /// Get the const bool value of [expr] if it exists.
  /// Return null if it isn't a const bool.
  bool? _maybeGetBoolConstValue(Expression expr) {
    if (expr is BooleanLiteral) {
      return expr.value;
    }
    if (expr is Identifier) {
      final staticElm = expr.staticElement;
      if (staticElm is ConstVariableElement) {
        return staticElm.computeConstantValue()?.toBoolValue();
      }
      if (staticElm is PropertyAccessorElementImpl) {
        final v = staticElm.variable;
        if (v is ConstVariableElement) {
          return v.computeConstantValue()?.toBoolValue();
        }
      }
    }
    return null;
  }

  _PrimitiveDartType _primitiveNativeType(DartType nativeType) {
    if (nativeType is InterfaceType) {
      final element = nativeType.element;
      if (element.isFfiClass) {
        final String name = element.name;
        if (_primitiveIntegerNativeTypes.contains(name)) {
          return _PrimitiveDartType.int;
        }
        if (_primitiveDoubleNativeTypes.contains(name)) {
          return _PrimitiveDartType.double;
        }
        if (name == _primitiveBoolNativeType) {
          return _PrimitiveDartType.bool;
        }
        if (name == 'Void') {
          return _PrimitiveDartType.void_;
        }
        if (name == 'Handle') {
          return _PrimitiveDartType.handle;
        }
      }
    }
    return _PrimitiveDartType.none;
  }

  /// Return an indication of the Dart type associated with the [annotation].
  _PrimitiveDartType _typeForAnnotation(Annotation annotation) {
    var element = annotation.element;
    if (element is ConstructorElement) {
      String name = element.enclosingElement.name;
      if (_primitiveIntegerNativeTypes.contains(name)) {
        return _PrimitiveDartType.int;
      } else if (_primitiveDoubleNativeTypes.contains(name)) {
        return _PrimitiveDartType.double;
      } else if (_primitiveBoolNativeType == name) {
        return _PrimitiveDartType.bool;
      }
    }
    return _PrimitiveDartType.none;
  }

  void _validateAllocate(FunctionExpressionInvocation node) {
    final typeArgumentTypes = node.typeArgumentTypes;
    if (typeArgumentTypes == null || typeArgumentTypes.length != 1) {
      return;
    }
    final DartType dartType = typeArgumentTypes[0];
    if (!_isValidFfiNativeType(dartType,
        allowVoid: true, allowEmptyStruct: true)) {
      final AstNode errorNode = node;
      _errorReporter.reportErrorForNode(
          FfiCode.NON_CONSTANT_TYPE_ARGUMENT,
          errorNode,
          ['$_allocatorExtensionName.$_allocateExtensionMethodName']);
    }
  }

  /// Validate that the [annotations] include exactly one annotation that
  /// satisfies the [requiredTypes]. If an error is produced that cannot be
  /// associated with an annotation, associate it with the [errorNode].
  void _validateAnnotations(AstNode errorNode, NodeList<Annotation> annotations,
      _PrimitiveDartType requiredType) {
    bool requiredFound = false;
    List<Annotation> extraAnnotations = [];
    for (Annotation annotation in annotations) {
      if (annotation.element.ffiClass != null) {
        if (requiredFound) {
          extraAnnotations.add(annotation);
        } else {
          _PrimitiveDartType foundType = _typeForAnnotation(annotation);
          if (foundType == requiredType) {
            requiredFound = true;
          } else {
            extraAnnotations.add(annotation);
          }
        }
      }
    }
    if (extraAnnotations.isNotEmpty) {
      if (!requiredFound) {
        Annotation invalidAnnotation = extraAnnotations.removeAt(0);
        _errorReporter.reportErrorForNode(
            FfiCode.MISMATCHED_ANNOTATION_ON_STRUCT_FIELD, invalidAnnotation);
      }
      for (Annotation extraAnnotation in extraAnnotations) {
        _errorReporter.reportErrorForNode(
            FfiCode.EXTRA_ANNOTATION_ON_STRUCT_FIELD, extraAnnotation);
      }
    } else if (!requiredFound) {
      _errorReporter.reportErrorForNode(
          FfiCode.MISSING_ANNOTATION_ON_STRUCT_FIELD, errorNode);
    }
  }

  /// Validate the invocation of the instance method
  /// `Pointer<T>.asFunction<F>()`.
  void _validateAsFunction(MethodInvocation node, MethodElement element) {
    var typeArguments = node.typeArguments?.arguments;
    if (typeArguments != null && typeArguments.length == 1) {
      if (_validateTypeArgument(typeArguments[0], 'asFunction')) {
        return;
      }
    }
    var target = node.realTarget!;
    var targetType = target.staticType;
    if (targetType is InterfaceType && targetType.isPointer) {
      final DartType T = targetType.typeArguments[0];
      if (!T.isNativeFunction) {
        return;
      }
      final DartType pointerTypeArg = (T as InterfaceType).typeArguments.single;
      if (pointerTypeArg is TypeParameterType) {
        _errorReporter.reportErrorForNode(
            FfiCode.NON_CONSTANT_TYPE_ARGUMENT, target, ['asFunction']);
        return;
      }
      if (!_isValidFfiNativeFunctionType(pointerTypeArg)) {
        final AstNode errorNode =
            typeArguments != null ? typeArguments[0] : node;
        _errorReporter.reportErrorForNode(
            FfiCode.NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER,
            errorNode,
            [T]);
        return;
      }

      final DartType TPrime = T.typeArguments[0];
      final DartType F = node.typeArgumentTypes![0];
      if (!_validateCompatibleFunctionTypes(F, TPrime)) {
        _errorReporter.reportErrorForNode(
            FfiCode.MUST_BE_A_SUBTYPE, node, [TPrime, F, 'asFunction']);
      }
      _validateFfiLeafCallUsesNoHandles(
          node.argumentList.arguments, TPrime, node);
    }
    _validateIsLeafIsConst(node);
  }

  /// Validates that the given [nativeType] is, when native types are converted
  /// to their Dart equivalent, a subtype of [dartType].
  bool _validateCompatibleFunctionTypes(
      DartType dartType, DartType nativeType) {
    // We require both to be valid function types.
    if (dartType is! FunctionType ||
        dartType.isDartCoreFunction ||
        nativeType is! FunctionType ||
        nativeType.isDartCoreFunction) {
      return false;
    }

    // We disallow any optional parameters.
    final int parameterCount = dartType.normalParameterTypes.length;
    if (parameterCount != nativeType.normalParameterTypes.length) {
      return false;
    }
    // We disallow generic function types.
    if (dartType.typeFormals.isNotEmpty || nativeType.typeFormals.isNotEmpty) {
      return false;
    }
    if (dartType.namedParameterTypes.isNotEmpty ||
        dartType.optionalParameterTypes.isNotEmpty ||
        nativeType.namedParameterTypes.isNotEmpty ||
        nativeType.optionalParameterTypes.isNotEmpty) {
      return false;
    }

    // Validate that the return types are compatible.
    if (!_validateCompatibleNativeType(
        dartType.returnType, nativeType.returnType, false)) {
      return false;
    }

    // Validate that the parameter types are compatible.
    for (int i = 0; i < parameterCount; ++i) {
      if (!_validateCompatibleNativeType(dartType.normalParameterTypes[i],
          nativeType.normalParameterTypes[i], true)) {
        return false;
      }
    }

    // Signatures have same number of parameters and the types match.
    return true;
  }

  /// Validates that, if we convert [nativeType] to it's corresponding
  /// [dartType] the latter is a subtype of the former if
  /// [checkCovariance].
  bool _validateCompatibleNativeType(
      DartType dartType, DartType nativeType, bool checkCovariance) {
    final nativeReturnType = _primitiveNativeType(nativeType);
    if (nativeReturnType == _PrimitiveDartType.int) {
      return dartType.isDartCoreInt;
    } else if (nativeReturnType == _PrimitiveDartType.double) {
      return dartType.isDartCoreDouble;
    } else if (nativeReturnType == _PrimitiveDartType.bool) {
      return dartType.isDartCoreBool;
    } else if (nativeReturnType == _PrimitiveDartType.void_) {
      return dartType.isVoid;
    } else if (nativeReturnType == _PrimitiveDartType.handle) {
      InterfaceType objectType = typeSystem.objectStar;
      return checkCovariance
          ? /* everything is subtype of objectStar */ true
          : typeSystem.isSubtypeOf(objectType, dartType);
    } else if (dartType is InterfaceType && nativeType is InterfaceType) {
      return checkCovariance
          ? typeSystem.isSubtypeOf(dartType, nativeType)
          : typeSystem.isSubtypeOf(nativeType, dartType);
    } else {
      // If the [nativeType] is not a primitive int/double type then it has to
      // be a Pointer type atm.
      return false;
    }
  }

  void _validateElementAt(MethodInvocation node) {
    var targetType = node.realTarget?.staticType;
    if (targetType is InterfaceType && targetType.isPointer) {
      final DartType T = targetType.typeArguments[0];

      if (!_isValidFfiNativeType(T, allowVoid: true, allowEmptyStruct: true)) {
        final AstNode errorNode = node;
        _errorReporter.reportErrorForNode(
            FfiCode.NON_CONSTANT_TYPE_ARGUMENT, errorNode, ['elementAt']);
      }
    }
  }

  void _validateFfiLeafCallUsesNoHandles(
      NodeList<Expression> args, DartType nativeType, AstNode errorNode) {
    if (args.isEmpty) {
      return;
    }
    for (final arg in args) {
      if (arg is! NamedExpression || arg.element?.name != _isLeafParamName) {
        continue;
      }
      // Handles are ok for regular (non-leaf) calls. Check `isLeaf:true`.
      final bool? isLeaf = _maybeGetBoolConstValue(arg.expression);
      if (isLeaf != null && isLeaf) {
        if (nativeType is FunctionType) {
          if (_primitiveNativeType(nativeType.returnType) ==
              _PrimitiveDartType.handle) {
            _errorReporter.reportErrorForNode(
                FfiCode.LEAF_CALL_MUST_NOT_RETURN_HANDLE, errorNode);
          }
          for (final param in nativeType.normalParameterTypes) {
            if (_primitiveNativeType(param) == _PrimitiveDartType.handle) {
              _errorReporter.reportErrorForNode(
                  FfiCode.LEAF_CALL_MUST_NOT_TAKE_HANDLE, errorNode);
            }
          }
        }
      }
    }
  }

  /// Validate that the fields declared by the given [node] meet the
  /// requirements for fields within a struct or union class.
  void _validateFieldsInCompound(FieldDeclaration node) {
    if (node.isStatic) {
      return;
    }

    VariableDeclarationList fields = node.fields;
    NodeList<Annotation> annotations = node.metadata;

    if (typeSystem.isNonNullableByDefault) {
      if (node.externalKeyword == null) {
        _errorReporter.reportErrorForNode(
          FfiCode.FIELD_MUST_BE_EXTERNAL_IN_STRUCT,
          fields.variables[0].name,
        );
      }
    }

    var fieldType = fields.type;
    if (fieldType == null) {
      _errorReporter.reportErrorForNode(
          FfiCode.MISSING_FIELD_TYPE_IN_STRUCT, fields.variables[0].name);
    } else {
      DartType declaredType = fieldType.typeOrThrow;
      if (declaredType.isDartCoreInt) {
        _validateAnnotations(fieldType, annotations, _PrimitiveDartType.int);
      } else if (declaredType.isDartCoreDouble) {
        _validateAnnotations(fieldType, annotations, _PrimitiveDartType.double);
      } else if (declaredType.isDartCoreBool) {
        _validateAnnotations(fieldType, annotations, _PrimitiveDartType.bool);
      } else if (declaredType.isPointer) {
        _validateNoAnnotations(annotations);
      } else if (declaredType.isArray) {
        final typeArg = (declaredType as InterfaceType).typeArguments.single;
        if (!_isSized(typeArg)) {
          AstNode errorNode = fieldType;
          if (fieldType is NamedType) {
            var typeArguments = fieldType.typeArguments?.arguments;
            if (typeArguments != null && typeArguments.isNotEmpty) {
              errorNode = typeArguments[0];
            }
          }
          _errorReporter.reportErrorForNode(FfiCode.NON_SIZED_TYPE_ARGUMENT,
              errorNode, [_arrayClassName, typeArg]);
        }
        final arrayDimensions = declaredType.arrayDimensions;
        _validateSizeOfAnnotation(fieldType, annotations, arrayDimensions);
        final arrayElement = declaredType.arrayElementType;
        if (arrayElement.isCompoundSubtype) {
          final elementClass = (arrayElement as InterfaceType).element;
          _validatePackingNesting(compound!.declaredElement!, elementClass,
              errorNode: fieldType);
        }
      } else if (declaredType.isCompoundSubtype) {
        final clazz = (declaredType as InterfaceType).element;
        if (clazz.isEmptyStruct) {
          _errorReporter.reportErrorForNode(FfiCode.EMPTY_STRUCT, node, [
            clazz.name,
            clazz.supertype!.getDisplayString(withNullability: false)
          ]);
        }
        _validatePackingNesting(compound!.declaredElement!, clazz,
            errorNode: fieldType);
      } else {
        _errorReporter.reportErrorForNode(FfiCode.INVALID_FIELD_TYPE_IN_STRUCT,
            fieldType, [fieldType.toSource()]);
      }
    }

    if (!typeSystem.isNonNullableByDefault) {
      for (VariableDeclaration field in fields.variables) {
        if (field.initializer != null) {
          _errorReporter.reportErrorForNode(
            FfiCode.FIELD_IN_STRUCT_WITH_INITIALIZER,
            field.name,
          );
        }
      }
    }
  }

  /// Validate the invocation of the static method
  /// `Pointer<T>.fromFunction(f, e)`.
  void _validateFromFunction(MethodInvocation node, MethodElement element) {
    final int argCount = node.argumentList.arguments.length;
    if (argCount < 1 || argCount > 2) {
      // There are other diagnostics reported against the invocation and the
      // diagnostics generated below might be inaccurate, so don't report them.
      return;
    }

    final DartType T = node.typeArgumentTypes![0];
    if (!_isValidFfiNativeFunctionType(T)) {
      AstNode errorNode = node.methodName;
      var typeArgument = node.typeArguments?.arguments[0];
      if (typeArgument != null) {
        errorNode = typeArgument;
      }
      _errorReporter.reportErrorForNode(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE,
          errorNode, [T, 'fromFunction']);
      return;
    }

    Expression f = node.argumentList.arguments[0];
    DartType FT = f.typeOrThrow;
    if (!_validateCompatibleFunctionTypes(FT, T)) {
      _errorReporter.reportErrorForNode(
          FfiCode.MUST_BE_A_SUBTYPE, f, [FT, T, 'fromFunction']);
      return;
    }

    // TODO(brianwilkerson) Validate that `f` is a top-level function.
    final DartType R = (T as FunctionType).returnType;
    if ((FT as FunctionType).returnType.isVoid ||
        R.isPointer ||
        R.isHandle ||
        R.isCompoundSubtype) {
      if (argCount != 1) {
        _errorReporter.reportErrorForNode(
            FfiCode.INVALID_EXCEPTION_VALUE, node.argumentList.arguments[1]);
      }
    } else if (argCount != 2) {
      _errorReporter.reportErrorForNode(
          FfiCode.MISSING_EXCEPTION_VALUE, node.methodName);
    } else {
      Expression e = node.argumentList.arguments[1];
      var eType = e.typeOrThrow;
      if (!_validateCompatibleNativeType(eType, R, true)) {
        _errorReporter.reportErrorForNode(
            FfiCode.MUST_BE_A_SUBTYPE, e, [eType, R, 'fromFunction']);
      }
      if (!_isConst(e)) {
        _errorReporter.reportErrorForNode(
            FfiCode.ARGUMENT_MUST_BE_A_CONSTANT, e, ['exceptionalReturn']);
      }
    }
  }

  /// Ensure `isLeaf` is const as we need the value at compile time to know
  /// which trampoline to generate.
  void _validateIsLeafIsConst(MethodInvocation node) {
    final args = node.argumentList.arguments;
    if (args.isNotEmpty) {
      for (final arg in args) {
        if (arg is NamedExpression) {
          if (arg.element?.name == _isLeafParamName) {
            if (!_isConst(arg.expression)) {
              _errorReporter.reportErrorForNode(
                  FfiCode.ARGUMENT_MUST_BE_A_CONSTANT,
                  arg.expression,
                  [_isLeafParamName]);
            }
          }
        }
      }
    }
  }

  /// Validate the invocation of the instance method
  /// `DynamicLibrary.lookupFunction<S, F>()`.
  void _validateLookupFunction(MethodInvocation node) {
    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.length != 2) {
      // There are other diagnostics reported against the invocation and the
      // diagnostics generated below might be inaccurate, so don't report them.
      return;
    }

    final List<DartType> argTypes = node.typeArgumentTypes!;
    final DartType S = argTypes[0];
    final DartType F = argTypes[1];
    if (!_isValidFfiNativeFunctionType(S)) {
      final AstNode errorNode = typeArguments[0];
      _errorReporter.reportErrorForNode(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE,
          errorNode, [S, 'lookupFunction']);
      return;
    }
    if (!_validateCompatibleFunctionTypes(F, S)) {
      final AstNode errorNode = typeArguments[1];
      _errorReporter.reportErrorForNode(
          FfiCode.MUST_BE_A_SUBTYPE, errorNode, [S, F, 'lookupFunction']);
    }
    _validateIsLeafIsConst(node);
    _validateFfiLeafCallUsesNoHandles(
        node.argumentList.arguments, S, typeArguments[0]);
  }

  /// Validate that none of the [annotations] are from `dart:ffi`.
  void _validateNoAnnotations(NodeList<Annotation> annotations) {
    for (Annotation annotation in annotations) {
      if (annotation.element.ffiClass != null) {
        _errorReporter.reportErrorForNode(
            FfiCode.ANNOTATION_ON_POINTER_FIELD, annotation);
      }
    }
  }

  /// Validate that the [annotations] include at most one packed annotation.
  void _validatePackedAnnotation(NodeList<Annotation> annotations) {
    final ffiPackedAnnotations =
        annotations.where((annotation) => annotation.isPacked).toList();

    if (ffiPackedAnnotations.isEmpty) {
      return;
    }

    if (ffiPackedAnnotations.length > 1) {
      final extraAnnotations = ffiPackedAnnotations.skip(1);
      for (final annotation in extraAnnotations) {
        _errorReporter.reportErrorForNode(
            FfiCode.PACKED_ANNOTATION, annotation);
      }
    }

    // Check number of dimensions.
    final annotation = ffiPackedAnnotations.first;
    final value = annotation.elementAnnotation?.packedMemberAlignment;
    if (![1, 2, 4, 8, 16].contains(value)) {
      AstNode errorNode = annotation;
      var arguments = annotation.arguments?.arguments;
      if (arguments != null && arguments.isNotEmpty) {
        errorNode = arguments[0];
      }
      _errorReporter.reportErrorForNode(
          FfiCode.PACKED_ANNOTATION_ALIGNMENT, errorNode);
    }
  }

  void _validatePackingNesting(ClassElement outer, ClassElement nested,
      {required TypeAnnotation errorNode}) {
    final outerPacking = outer.structPacking;
    if (outerPacking == null) {
      // No packing for outer class, so we're done.
      return;
    }
    bool error = false;
    final nestedPacking = nested.structPacking;
    if (nestedPacking == null) {
      // The outer struct packs, but the nested struct does not.
      error = true;
    } else if (outerPacking < nestedPacking) {
      // The outer struct packs tighter than the nested struct.
      error = true;
    }
    if (error) {
      _errorReporter.reportErrorForNode(FfiCode.PACKED_NESTING_NON_PACKED,
          errorNode, [nested.name, outer.name]);
    }
  }

  void _validateRefIndexed(IndexExpression node) {
    var targetType = node.realTarget.staticType;
    if (!_isValidFfiNativeType(targetType,
        allowVoid: false, allowEmptyStruct: true, allowArray: true)) {
      final AstNode errorNode = node;
      _errorReporter.reportErrorForNode(
          FfiCode.NON_CONSTANT_TYPE_ARGUMENT, errorNode, ['[]']);
    }
  }

  /// Validate the invocation of the extension method
  /// `Pointer<T extends Struct>.ref`.
  void _validateRefPrefixedIdentifier(PrefixedIdentifier node) {
    var targetType = node.prefix.typeOrThrow;
    if (!_isValidFfiNativeType(targetType,
        allowVoid: false, allowEmptyStruct: true)) {
      final AstNode errorNode = node;
      _errorReporter.reportErrorForNode(
          FfiCode.NON_CONSTANT_TYPE_ARGUMENT, errorNode, ['ref']);
    }
  }

  void _validateRefPropertyAccess(PropertyAccess node) {
    var targetType = node.realTarget.staticType;
    if (!_isValidFfiNativeType(targetType,
        allowVoid: false, allowEmptyStruct: true)) {
      final AstNode errorNode = node;
      _errorReporter.reportErrorForNode(
          FfiCode.NON_CONSTANT_TYPE_ARGUMENT, errorNode, ['ref']);
    }
  }

  void _validateSizeOf(MethodInvocation node) {
    final typeArgumentTypes = node.typeArgumentTypes;
    if (typeArgumentTypes == null || typeArgumentTypes.length != 1) {
      return;
    }
    final DartType T = typeArgumentTypes[0];
    if (!_isValidFfiNativeType(T, allowVoid: true, allowEmptyStruct: true)) {
      final AstNode errorNode = node;
      _errorReporter.reportErrorForNode(
          FfiCode.NON_CONSTANT_TYPE_ARGUMENT, errorNode, ['sizeOf']);
    }
  }

  /// Validate that the [annotations] include exactly one size annotation. If
  /// an error is produced that cannot be associated with an annotation,
  /// associate it with the [errorNode].
  void _validateSizeOfAnnotation(AstNode errorNode,
      NodeList<Annotation> annotations, int arrayDimensions) {
    final ffiSizeAnnotations =
        annotations.where((annotation) => annotation.isArray).toList();

    if (ffiSizeAnnotations.isEmpty) {
      _errorReporter.reportErrorForNode(
          FfiCode.MISSING_SIZE_ANNOTATION_CARRAY, errorNode);
      return;
    }

    if (ffiSizeAnnotations.length > 1) {
      final extraAnnotations = ffiSizeAnnotations.skip(1);
      for (final annotation in extraAnnotations) {
        _errorReporter.reportErrorForNode(
            FfiCode.EXTRA_SIZE_ANNOTATION_CARRAY, annotation);
      }
    }

    // Check number of dimensions.
    final annotation = ffiSizeAnnotations.first;
    final dimensions = annotation.elementAnnotation?.arraySizeDimensions ?? [];
    final annotationDimensions = dimensions.length;
    if (annotationDimensions != arrayDimensions) {
      _errorReporter.reportErrorForNode(
          FfiCode.SIZE_ANNOTATION_DIMENSIONS, annotation);
    }

    // Check dimensions are positive
    List<AstNode>? getArgumentNodes() {
      var arguments = annotation.arguments?.arguments;
      if (arguments != null && arguments.length == 1) {
        var firstArgument = arguments[0];
        if (firstArgument is ListLiteral) {
          return firstArgument.elements;
        }
      }
      return arguments;
    }

    for (int i = 0; i < dimensions.length; i++) {
      if (dimensions[i] <= 0) {
        AstNode errorNode = annotation;
        var argumentNodes = getArgumentNodes();
        if (argumentNodes != null && argumentNodes.isNotEmpty) {
          errorNode = argumentNodes[i];
        }
        _errorReporter.reportErrorForNode(
            FfiCode.NON_POSITIVE_ARRAY_DIMENSION, errorNode);
      }
    }
  }

  /// Validate that the given [typeArgument] has a constant value. Return `true`
  /// if a diagnostic was produced because it isn't constant.
  bool _validateTypeArgument(TypeAnnotation typeArgument, String functionName) {
    if (typeArgument.type is TypeParameterType) {
      _errorReporter.reportErrorForNode(
          FfiCode.NON_CONSTANT_TYPE_ARGUMENT, typeArgument, [functionName]);
      return true;
    }
    return false;
  }
}

enum _PrimitiveDartType {
  double,
  int,
  bool,
  void_,
  handle,
  none,
}

extension on Annotation {
  bool get isArray {
    final element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name == 'Array';
  }

  bool get isPacked {
    final element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name == 'Packed';
  }
}

extension on ElementAnnotation {
  bool get isArray {
    final element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name == 'Array';
    // Note: this is 'Array' instead of '_ArraySize' because it finds the
    // forwarding factory instead of the forwarded constructor.
  }

  bool get isPacked {
    final element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name == 'Packed';
  }

  List<int> get arraySizeDimensions {
    assert(isArray);
    final value = computeConstantValue();

    // Element of `@Array.multi([1, 2, 3])`.
    final listField = value?.getField('dimensions');
    if (listField != null) {
      final listValues = listField
          .toListValue()
          ?.map((dartValue) => dartValue.toIntValue())
          .whereType<int>()
          .toList();
      if (listValues != null) {
        return listValues;
      }
    }

    // Element of `@Array(1, 2, 3)`.
    const dimensionFieldNames = [
      'dimension1',
      'dimension2',
      'dimension3',
      'dimension4',
      'dimension5',
    ];
    var result = <int>[];
    for (final dimensionFieldName in dimensionFieldNames) {
      final dimensionValue = value?.getField(dimensionFieldName)?.toIntValue();
      if (dimensionValue != null) {
        result.add(dimensionValue);
      }
    }
    return result;
  }

  int? get packedMemberAlignment {
    assert(isPacked);
    final value = computeConstantValue();
    return value?.getField('memberAlignment')?.toIntValue();
  }
}

extension on Element? {
  /// Return `true` if this represents the extension `AllocatorAlloc`.
  bool get isAllocatorExtension {
    final element = this;
    return element is ExtensionElement &&
        element.name == FfiVerifier._allocatorExtensionName &&
        element.isFfiExtension;
  }

  bool get isNativeFunctionPointerExtension {
    final element = this;
    return element is ExtensionElement &&
        element.name == 'NativeFunctionPointer' &&
        element.isFfiExtension;
  }

  bool get isNativeStructArrayExtension {
    final element = this;
    return element is ExtensionElement &&
        element.name == 'StructArray' &&
        element.isFfiExtension;
  }

  bool get isNativeStructPointerExtension {
    final element = this;
    return element is ExtensionElement &&
        element.name == 'StructPointer' &&
        element.isFfiExtension;
  }

  /// Return `true` if this represents the extension `DynamicLibraryExtension`.
  bool get isDynamicLibraryExtension {
    final element = this;
    return element is ExtensionElement &&
        element.name == 'DynamicLibraryExtension' &&
        element.isFfiExtension;
  }

  /// Return `true` if this represents the class `Pointer`.
  bool get isPointer {
    final element = this;
    return element is ClassElement &&
        element.name == 'Pointer' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents the class `Struct`.
  bool get isStruct {
    final element = this;
    return element is ClassElement &&
        element.name == 'Struct' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents a subclass of the class `Struct`.
  bool get isStructSubclass {
    final element = this;
    return element is ClassElement && element.supertype.isStruct;
  }

  /// Return `true` if this represents the class `Union`.
  bool get isUnion {
    final element = this;
    return element is ClassElement &&
        element.name == 'Union' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents a subclass of the class `Struct`.
  bool get isUnionSubclass {
    final element = this;
    return element is ClassElement && element.supertype.isUnion;
  }

  /// If this is a class element from `dart:ffi`, return it.
  ClassElement? get ffiClass {
    var element = this;
    if (element is ConstructorElement) {
      element = element.enclosingElement;
    }
    if (element is ClassElement && element.isFfiClass) {
      return element;
    }
    return null;
  }
}

extension on ClassElement {
  bool get isEmptyStruct {
    for (final field in fields) {
      final declaredType = field.type;
      if (declaredType.isDartCoreInt) {
        return false;
      } else if (declaredType.isDartCoreDouble) {
        return false;
      } else if (declaredType.isDartCoreBool) {
        return false;
      } else if (declaredType.isPointer) {
        return false;
      } else if (declaredType.isCompoundSubtype) {
        return false;
      } else if (declaredType.isArray) {
        return false;
      }
    }
    return true;
  }

  bool get isFfiClass {
    return library.name == FfiVerifier._dartFfiLibraryName;
  }

  int? get structPacking {
    final packedAnnotations =
        metadata.where((annotation) => annotation.isPacked);

    if (packedAnnotations.isEmpty) {
      return null;
    }

    return packedAnnotations.first.packedMemberAlignment;
  }
}

extension on ExtensionElement {
  bool get isFfiExtension {
    return library.name == FfiVerifier._dartFfiLibraryName;
  }
}

extension on DartType? {
  bool get isStruct {
    final self = this;
    return self is InterfaceType && self.element.isStruct;
  }

  bool get isUnion {
    final self = this;
    return self is InterfaceType && self.element.isUnion;
  }
}

extension on DartType {
  /// Return `true` if this represents the class `Array`.
  bool get isArray {
    final self = this;
    if (self is InterfaceType) {
      final element = self.element;
      return element.name == FfiVerifier._arrayClassName && element.isFfiClass;
    }
    return false;
  }

  int get arrayDimensions {
    DartType iterator = this;
    int dimensions = 0;
    while (iterator is InterfaceType &&
        iterator.element.name == FfiVerifier._arrayClassName &&
        iterator.element.isFfiClass) {
      dimensions++;
      iterator = iterator.typeArguments.single;
    }
    return dimensions;
  }

  DartType get arrayElementType {
    DartType iterator = this;
    while (iterator is InterfaceType &&
        iterator.element.name == FfiVerifier._arrayClassName &&
        iterator.element.isFfiClass) {
      iterator = iterator.typeArguments.single;
    }
    return iterator;
  }

  bool get isPointer {
    final self = this;
    return self is InterfaceType && self.element.isPointer;
  }

  bool get isHandle {
    final self = this;
    if (self is InterfaceType) {
      final element = self.element;
      return element.name == 'Handle' && element.isFfiClass;
    }
    return false;
  }

  /// Returns `true` iff this is a `ffi.NativeFunction<???>` type.
  bool get isNativeFunction {
    final self = this;
    if (self is InterfaceType) {
      final element = self.element;
      return element.name == 'NativeFunction' && element.isFfiClass;
    }
    return false;
  }

  /// Returns `true` iff this is a `ffi.NativeType` type.
  bool get isNativeType {
    final self = this;
    if (self is InterfaceType) {
      final element = self.element;
      return element.name == 'NativeType' && element.isFfiClass;
    }
    return false;
  }

  /// Returns `true` iff this is a opaque type, i.e. a subtype of `Opaque`.
  bool get isOpaqueSubtype {
    final self = this;
    if (self is InterfaceType) {
      final superType = self.element.supertype;
      if (superType != null) {
        final superClassElement = superType.element;
        return superClassElement.name == FfiVerifier._opaqueClassName &&
            superClassElement.isFfiClass;
      }
    }
    return false;
  }

  bool get isCompound {
    final self = this;
    if (self is InterfaceType) {
      final element = self.element;
      final name = element.name;
      return (name == FfiVerifier._structClassName ||
              name == FfiVerifier._unionClassName) &&
          element.isFfiClass;
    }
    return false;
  }

  /// Returns `true` if this is a struct type, i.e. a subtype of `Struct`.
  bool get isCompoundSubtype {
    final self = this;
    if (self is InterfaceType) {
      final superType = self.element.supertype;
      if (superType != null) {
        return superType.isCompound;
      }
    }
    return false;
  }
}

extension on NamedType {
  /// If this is a name of class from `dart:ffi`, return it.
  ClassElement? get ffiClass {
    return name.staticElement.ffiClass;
  }

  /// Return `true` if this represents a subtype of `Struct` or `Union`.
  bool get isCompoundSubtype {
    var element = name.staticElement;
    if (element is ClassElement) {
      return element.allSupertypes.any((e) => e.isCompound);
    }
    return false;
  }
}
