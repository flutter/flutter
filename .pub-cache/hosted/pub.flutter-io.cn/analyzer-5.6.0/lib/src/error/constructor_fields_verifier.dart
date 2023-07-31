// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';

/// Verifier for initializing fields in constructors.
class ConstructorFieldsVerifier {
  final TypeSystemImpl _typeSystem;
  final ErrorReporter _errorReporter;

  bool _isInNativeClass = false;

  /// When a new class or mixin is entered, [_initFieldsMap] initializes this
  /// map, and [leaveClass] resets it.
  ///
  /// [_InitState.notInit] or [_InitState.initInDeclaration] is set for each
  /// field. Later [verify] is called to verify each constructor of the class.
  Map<FieldElement, _InitState>? _initialFieldMap;

  /// The state of fields in the current constructor.
  Map<FieldElement, _InitState> _fieldMap = {};

  /// Set to `true` if the current constructor redirects.
  bool _hasRedirectingConstructorInvocation = false;

  ConstructorFieldsVerifier({
    required TypeSystemImpl typeSystem,
    required ErrorReporter errorReporter,
  })  : _typeSystem = typeSystem,
        _errorReporter = errorReporter;

  void enterClass(ClassDeclaration node, ClassElementImpl element) {
    _isInNativeClass = node.nativeClause != null;
    _initFieldsMap(element.fields);
  }

  void enterEnum(EnumDeclaration node, EnumElementImpl element) {
    _isInNativeClass = false;
    _initFieldsMap(
      element.fields,
      enumConstants: element.constants,
    );
  }

  void leaveClass() {
    _isInNativeClass = false;
    _initialFieldMap = null;
  }

  /// Verify that the given [node] declaration does not violate any of
  /// the error codes relating to the initialization of fields in the
  /// enclosing class.
  void verify(ConstructorDeclaration node) {
    if (node.factoryKeyword != null ||
        node.redirectedConstructor != null ||
        node.externalKeyword != null) {
      return;
    }

    if (!(node.parent is ClassDeclaration || node.parent is EnumDeclaration)) {
      return;
    }

    if (_isInNativeClass) {
      return;
    }

    _fieldMap = Map.of(_initialFieldMap!);
    _hasRedirectingConstructorInvocation = false;

    _updateWithParameters(node);
    _updateWithInitializers(node);

    if (_hasRedirectingConstructorInvocation) {
      return;
    }

    // Prepare lists of not initialized fields.
    var notInitFinalFields = <FieldElement>[];
    var notInitNonNullableFields = <FieldElement>[];
    _fieldMap.forEach((FieldElement field, _InitState state) {
      if (state != _InitState.notInit) return;
      if (field.isLate) return;
      if (field.isAbstract || field.isExternal) return;
      if (field.isStatic) return;

      if (field.isFinal) {
        notInitFinalFields.add(field);
      } else if (_typeSystem.isNonNullableByDefault &&
          _typeSystem.isPotentiallyNonNullable(field.type)) {
        notInitNonNullableFields.add(field);
      }
    });

    _reportNotInitializedFinal(node, notInitFinalFields);
    _reportNotInitializedNonNullable(node, notInitNonNullableFields);
  }

  void _initFieldsMap(
    List<FieldElement> fields, {
    List<FieldElement>? enumConstants,
  }) {
    _initialFieldMap = <FieldElement, _InitState>{};

    for (var field in fields) {
      if (field.isSynthetic) {
        continue;
      }
      if (enumConstants != null && field.name == 'index') {
        continue;
      }
      _initialFieldMap![field] = field.hasInitializer
          ? _InitState.initInDeclaration
          : _InitState.notInit;
    }

    if (enumConstants != null) {
      for (var field in enumConstants) {
        _initialFieldMap![field] = _InitState.initInDeclaration;
      }
    }
  }

  void _reportNotInitializedFinal(
    ConstructorDeclaration node,
    List<FieldElement> notInitFinalFields,
  ) {
    if (notInitFinalFields.isEmpty) {
      return;
    }

    var names = notInitFinalFields.map((item) => item.name).toList();
    names.sort();

    if (names.length == 1) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1,
        node.returnType,
        names,
      );
    } else if (names.length == 2) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2,
        node.returnType,
        names,
      );
    } else {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS,
        node.returnType,
        [names[0], names[1], names.length - 2],
      );
    }
  }

  void _reportNotInitializedNonNullable(
    ConstructorDeclaration node,
    List<FieldElement> notInitNonNullableFields,
  ) {
    if (notInitNonNullableFields.isEmpty) {
      return;
    }

    var names = notInitNonNullableFields.map((f) => f.name).toList();
    names.sort();

    for (var name in names) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode
            .NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD_CONSTRUCTOR,
        node.returnType,
        [name],
      );
    }
  }

  void _updateWithInitializers(ConstructorDeclaration node) {
    for (var initializer in node.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        _hasRedirectingConstructorInvocation = true;
      }
      if (initializer is ConstructorFieldInitializer) {
        SimpleIdentifier fieldName = initializer.fieldName;
        var element = fieldName.staticElement;
        if (element is FieldElement) {
          var state = _fieldMap[element];
          if (state == _InitState.notInit) {
            _fieldMap[element] = _InitState.initInInitializer;
          } else if (state == _InitState.initInDeclaration) {
            if (element.isFinal || element.isConst) {
              _errorReporter.reportErrorForNode(
                CompileTimeErrorCode
                    .FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION,
                fieldName,
              );
            }
          } else if (state == _InitState.initInFieldFormal) {
            _errorReporter.reportErrorForNode(
              CompileTimeErrorCode
                  .FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER,
              fieldName,
            );
          } else if (state == _InitState.initInInitializer) {
            _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS,
              fieldName,
              [element.displayName],
            );
          }
        }
      }
    }
  }

  void _updateWithParameters(ConstructorDeclaration node) {
    var formalParameters = node.parameters.parameters;
    for (FormalParameter parameter in formalParameters) {
      parameter = _baseParameter(parameter);
      if (parameter is FieldFormalParameter) {
        var fieldElement =
            (parameter.declaredElement as FieldFormalParameterElementImpl)
                .field;
        if (fieldElement == null) {
          continue;
        }
        _InitState? state = _fieldMap[fieldElement];
        if (state == _InitState.notInit) {
          _fieldMap[fieldElement] = _InitState.initInFieldFormal;
        } else if (state == _InitState.initInDeclaration) {
          if (fieldElement.isFinal || fieldElement.isConst) {
            _errorReporter.reportErrorForToken(
              CompileTimeErrorCode
                  .FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR,
              parameter.name,
              [fieldElement.displayName],
            );
          }
        } else if (state == _InitState.initInFieldFormal) {
          // Reported in DuplicateDefinitionVerifier._checkDuplicateIdentifier
        }
      }
    }
  }

  static FormalParameter _baseParameter(FormalParameter parameter) {
    if (parameter is DefaultFormalParameter) {
      return parameter.parameter;
    }
    return parameter;
  }
}

/// The four states of a field initialization state through a constructor
/// signature, not initialized, initialized in the field declaration,
/// initialized in the field formal, and finally, initialized in the
/// initializers list.
enum _InitState {
  /// The field is declared without an initializer.
  notInit,

  /// The field is declared with an initializer.
  initInDeclaration,

  /// The field is initialized in a field formal parameter of the constructor
  /// being verified.
  initInFieldFormal,

  /// The field is initialized in the list of initializers of the constructor
  /// being verified.
  initInInitializer,
}
