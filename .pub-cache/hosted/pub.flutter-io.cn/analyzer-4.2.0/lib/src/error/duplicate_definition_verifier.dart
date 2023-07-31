// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/error/codes.dart';

class DuplicateDefinitionVerifier {
  final InheritanceManager3 _inheritanceManager;
  final LibraryElement _currentLibrary;
  final ErrorReporter _errorReporter;

  DuplicateDefinitionVerifier(
    this._inheritanceManager,
    this._currentLibrary,
    this._errorReporter,
  );

  /// Check that the exception and stack trace parameters have different names.
  void checkCatchClause(CatchClause node) {
    var exceptionParameter = node.exceptionParameter;
    var stackTraceParameter = node.stackTraceParameter;
    if (exceptionParameter != null && stackTraceParameter != null) {
      String exceptionName = exceptionParameter.name;
      if (exceptionName == stackTraceParameter.name) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.DUPLICATE_DEFINITION,
            stackTraceParameter,
            [exceptionName]);
      }
    }
  }

  void checkClass(ClassDeclaration node) {
    _checkClassMembers(node.declaredElement!, node.members);
  }

  /// Check that there are no members with the same name.
  void checkEnum(EnumDeclaration node) {
    var enumElement = node.declaredElement as EnumElementImpl;
    var enumName = enumElement.name;

    var constructorNames = <String>{};
    var instanceGetters = <String, Element>{};
    var instanceSetters = <String, Element>{};
    var staticGetters = <String, Element>{};
    var staticSetters = <String, Element>{};

    for (EnumConstantDeclaration constant in node.constants) {
      _checkDuplicateIdentifier(staticGetters, constant.name);
      _checkValuesDeclarationInEnum(constant.name);
    }

    for (var member in node.members) {
      if (member is ConstructorDeclaration) {
        if (member.returnType.name == enumElement.name) {
          var name = member.declaredElement!.name;
          if (!constructorNames.add(name)) {
            if (name.isEmpty) {
              _errorReporter.reportErrorForName(
                CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT,
                member,
              );
            } else {
              _errorReporter.reportErrorForName(
                CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME,
                member,
                arguments: [name],
              );
            }
          }
        }
      } else if (member is FieldDeclaration) {
        for (var field in member.fields.variables) {
          var identifier = field.name;
          _checkDuplicateIdentifier(
            member.isStatic ? staticGetters : instanceGetters,
            identifier,
            setterScope: member.isStatic ? staticSetters : instanceSetters,
          );
          _checkValuesDeclarationInEnum(identifier);
        }
      } else if (member is MethodDeclaration) {
        _checkDuplicateIdentifier(
          member.isStatic ? staticGetters : instanceGetters,
          member.name,
          setterScope: member.isStatic ? staticSetters : instanceSetters,
        );
        if (!(member.isStatic && member.isSetter)) {
          _checkValuesDeclarationInEnum(member.name);
        }
      }
    }

    if (enumName == 'values') {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.ENUM_WITH_NAME_VALUES,
        node.name,
      );
    }

    for (var constant in node.constants) {
      if (constant.name.name == enumName) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ENUM_CONSTANT_SAME_NAME_AS_ENCLOSING,
          constant.name,
        );
      }
    }

    _checkConflictingConstructorAndStatic(
      classElement: enumElement,
      staticGetters: staticGetters,
      staticSetters: staticSetters,
    );

    for (var accessor in enumElement.accessors) {
      var baseName = accessor.displayName;
      if (accessor.isStatic) {
        var instance = _getInterfaceMember(enumElement, baseName);
        if (instance != null && baseName != 'values') {
          _errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
            accessor,
            [enumName, baseName, enumName],
          );
        }
      } else {
        var inherited = _getInheritedMember(enumElement, baseName);
        if (inherited is MethodElement) {
          _errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD,
            accessor,
            [
              enumElement.displayName,
              baseName,
              inherited.enclosingElement.displayName,
            ],
          );
        }
      }
    }

    for (var method in enumElement.methods) {
      var baseName = method.displayName;
      if (method.isStatic) {
        var instance = _getInterfaceMember(enumElement, baseName);
        if (instance != null) {
          _errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
            method,
            [enumName, baseName, enumName],
          );
        }
      } else {
        var inherited = _getInheritedMember(enumElement, baseName);
        if (inherited is PropertyAccessorElement) {
          _errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD,
            method,
            [
              enumElement.displayName,
              baseName,
              inherited.enclosingElement.displayName,
            ],
          );
        }
      }
    }
  }

  /// Check that there are no members with the same name.
  void checkExtension(ExtensionDeclaration node) {
    var instanceGetters = <String, Element>{};
    var instanceSetters = <String, Element>{};
    var staticGetters = <String, Element>{};
    var staticSetters = <String, Element>{};

    for (var member in node.members) {
      if (member is FieldDeclaration) {
        for (var field in member.fields.variables) {
          var identifier = field.name;
          _checkDuplicateIdentifier(
            member.isStatic ? staticGetters : instanceGetters,
            identifier,
            setterScope: member.isStatic ? staticSetters : instanceSetters,
          );
        }
      } else if (member is MethodDeclaration) {
        _checkDuplicateIdentifier(
          member.isStatic ? staticGetters : instanceGetters,
          member.name,
          setterScope: member.isStatic ? staticSetters : instanceSetters,
        );
      }
    }

    // Check for local static members conflicting with local instance members.
    for (var member in node.members) {
      if (member is FieldDeclaration) {
        if (member.isStatic) {
          for (var field in member.fields.variables) {
            var identifier = field.name;
            var name = identifier.name;
            if (instanceGetters.containsKey(name) ||
                instanceSetters.containsKey(name)) {
              _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE,
                identifier,
                [name],
              );
            }
          }
        }
      } else if (member is MethodDeclaration) {
        if (member.isStatic) {
          var identifier = member.name;
          var name = identifier.name;
          if (instanceGetters.containsKey(name) ||
              instanceSetters.containsKey(name)) {
            _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE,
              identifier,
              [name],
            );
          }
        }
      }
    }
  }

  /// Check that the given list of variable declarations does not define
  /// multiple variables of the same name.
  void checkForVariables(VariableDeclarationList node) {
    Map<String, Element> definedNames = HashMap<String, Element>();
    for (VariableDeclaration variable in node.variables) {
      _checkDuplicateIdentifier(definedNames, variable.name);
    }
  }

  void checkMixin(MixinDeclaration node) {
    _checkClassMembers(node.declaredElement!, node.members);
  }

  /// Check that all of the parameters have unique names.
  void checkParameters(FormalParameterList node) {
    Map<String, Element> definedNames = HashMap<String, Element>();
    for (FormalParameter parameter in node.parameters) {
      var identifier = parameter.identifier;
      if (identifier != null) {
        // The identifier can be null if this is a parameter list for a generic
        // function type.
        _checkDuplicateIdentifier(definedNames, identifier);
      }
    }
  }

  /// Check that all of the variables have unique names.
  void checkStatements(List<Statement> statements) {
    Map<String, Element> definedNames = HashMap<String, Element>();
    for (Statement statement in statements) {
      if (statement is VariableDeclarationStatement) {
        for (VariableDeclaration variable in statement.variables.variables) {
          _checkDuplicateIdentifier(definedNames, variable.name);
        }
      } else if (statement is FunctionDeclarationStatement) {
        _checkDuplicateIdentifier(
            definedNames, statement.functionDeclaration.name);
      }
    }
  }

  /// Check that all of the parameters have unique names.
  void checkTypeParameters(TypeParameterList node) {
    Map<String, Element> definedNames = HashMap<String, Element>();
    for (TypeParameter parameter in node.typeParameters) {
      _checkDuplicateIdentifier(definedNames, parameter.name);
    }
  }

  /// Check that there are no members with the same name.
  void checkUnit(CompilationUnit node) {
    Map<String, Element> definedGetters = HashMap<String, Element>();
    Map<String, Element> definedSetters = HashMap<String, Element>();

    void addWithoutChecking(CompilationUnitElement element) {
      for (PropertyAccessorElement accessor in element.accessors) {
        String name = accessor.name;
        if (accessor.isSetter) {
          name += '=';
        }
        definedGetters[name] = accessor;
      }
      for (ClassElement class_ in element.classes) {
        definedGetters[class_.name] = class_;
      }
      for (ClassElement type in element.enums) {
        definedGetters[type.name] = type;
      }
      for (FunctionElement function in element.functions) {
        definedGetters[function.name] = function;
      }
      for (TopLevelVariableElement variable in element.topLevelVariables) {
        definedGetters[variable.name] = variable;
        if (!variable.isFinal && !variable.isConst) {
          definedGetters['${variable.name}='] = variable;
        }
      }
      for (TypeAliasElement alias in element.typeAliases) {
        definedGetters[alias.name] = alias;
      }
    }

    for (ImportElement importElement in _currentLibrary.imports) {
      var prefix = importElement.prefix;
      if (prefix != null) {
        definedGetters[prefix.name] = prefix;
      }
    }
    CompilationUnitElement element = node.declaredElement!;
    if (element != _currentLibrary.definingCompilationUnit) {
      addWithoutChecking(_currentLibrary.definingCompilationUnit);
      for (CompilationUnitElement part in _currentLibrary.parts) {
        if (element == part) {
          break;
        }
        addWithoutChecking(part);
      }
    }
    for (CompilationUnitMember member in node.declarations) {
      if (member is ExtensionDeclaration) {
        var identifier = member.name;
        if (identifier != null) {
          _checkDuplicateIdentifier(definedGetters, identifier,
              setterScope: definedSetters);
        }
      } else if (member is NamedCompilationUnitMember) {
        _checkDuplicateIdentifier(definedGetters, member.name,
            setterScope: definedSetters);
      } else if (member is TopLevelVariableDeclaration) {
        for (VariableDeclaration variable in member.variables.variables) {
          _checkDuplicateIdentifier(definedGetters, variable.name,
              setterScope: definedSetters);
        }
      }
    }
  }

  /// Check that there are no members with the same name.
  void _checkClassMembers(ClassElement element, List<ClassMember> members) {
    var constructorNames = HashSet<String>();
    var instanceGetters = HashMap<String, Element>();
    var instanceSetters = HashMap<String, Element>();
    var staticGetters = HashMap<String, Element>();
    var staticSetters = HashMap<String, Element>();

    for (ClassMember member in members) {
      if (member is ConstructorDeclaration) {
        if (member.returnType.name != element.name) {
          // [member] is erroneous; do not count it as a possible duplicate.
          continue;
        }
        var name = member.name?.name ?? '';
        if (name == 'new') {
          name = '';
        }
        if (!constructorNames.add(name)) {
          if (name.isEmpty) {
            _errorReporter.reportErrorForName(
                CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, member);
          } else {
            _errorReporter.reportErrorForName(
                CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME, member,
                arguments: [name]);
          }
        }
      } else if (member is FieldDeclaration) {
        for (VariableDeclaration field in member.fields.variables) {
          SimpleIdentifier identifier = field.name;
          _checkDuplicateIdentifier(
            member.isStatic ? staticGetters : instanceGetters,
            identifier,
            setterScope: member.isStatic ? staticSetters : instanceSetters,
          );
        }
      } else if (member is MethodDeclaration) {
        _checkDuplicateIdentifier(
          member.isStatic ? staticGetters : instanceGetters,
          member.name,
          setterScope: member.isStatic ? staticSetters : instanceSetters,
        );
      }
    }

    _checkConflictingConstructorAndStatic(
      classElement: element,
      staticGetters: staticGetters,
      staticSetters: staticSetters,
    );

    // Check for local static members conflicting with local instance members.
    // TODO(scheglov) This code is duplicated for enums. But for classes it is
    // separated also into ErrorVerifier - where we check inherited.
    for (ClassMember member in members) {
      if (member is FieldDeclaration) {
        if (member.isStatic) {
          for (VariableDeclaration field in member.fields.variables) {
            SimpleIdentifier identifier = field.name;
            String name = identifier.name;
            if (instanceGetters.containsKey(name) ||
                instanceSetters.containsKey(name)) {
              String className = element.displayName;
              _errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
                  identifier,
                  [className, name, className]);
            }
          }
        }
      } else if (member is MethodDeclaration) {
        if (member.isStatic) {
          SimpleIdentifier identifier = member.name;
          String name = identifier.name;
          if (instanceGetters.containsKey(name) ||
              instanceSetters.containsKey(name)) {
            String className = element.name;
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
                identifier,
                [className, name, className]);
          }
        }
      }
    }
  }

  void _checkConflictingConstructorAndStatic({
    required ClassElement classElement,
    required Map<String, Element> staticGetters,
    required Map<String, Element> staticSetters,
  }) {
    for (var constructor in classElement.constructors) {
      var name = constructor.name;
      var staticMember = staticGetters[name] ?? staticSetters[name];
      if (staticMember is PropertyAccessorElement) {
        CompileTimeErrorCode errorCode;
        if (staticMember.isSynthetic) {
          errorCode =
              CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD;
        } else if (staticMember.isGetter) {
          errorCode =
              CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_GETTER;
        } else {
          errorCode =
              CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_SETTER;
        }
        _errorReporter.reportErrorForElement(errorCode, constructor, [name]);
      } else if (staticMember is MethodElement) {
        _errorReporter.reportErrorForElement(
          CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD,
          constructor,
          [name],
        );
      }
    }
  }

  /// Check whether the given [element] defined by the [identifier] is already
  /// in one of the scopes - [getterScope] or [setterScope], and produce an
  /// error if it is.
  void _checkDuplicateIdentifier(
      Map<String, Element> getterScope, SimpleIdentifier identifier,
      {Element? element, Map<String, Element>? setterScope}) {
    if (identifier.isSynthetic) {
      return;
    }
    element ??= identifier.staticElement!;

    // Fields define getters and setters, so check them separately.
    if (element is PropertyInducingElement) {
      _checkDuplicateIdentifier(getterScope, identifier,
          element: element.getter, setterScope: setterScope);
      if (!element.isConst && !element.isFinal) {
        _checkDuplicateIdentifier(getterScope, identifier,
            element: element.setter, setterScope: setterScope);
      }
      return;
    }

    ErrorCode getError(Element previous, Element current) {
      if (previous is FieldFormalParameterElement &&
          current is FieldFormalParameterElement) {
        return CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER;
      } else if (previous is PrefixElement) {
        return CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER;
      }
      return CompileTimeErrorCode.DUPLICATE_DEFINITION;
    }

    var name = identifier.name;
    if (element is MethodElement) {
      name = element.name;
    }

    var previous = getterScope[name];
    if (previous != null) {
      if (!_isGetterSetterPair(element, previous)) {
        _errorReporter.reportErrorForNode(
          getError(previous, element),
          identifier,
          [name],
        );
      }
    } else {
      getterScope[name] = element;
    }

    if (setterScope != null) {
      if (element is PropertyAccessorElement && element.isSetter) {
        previous = setterScope[name];
        if (previous != null) {
          _errorReporter.reportErrorForNode(
            getError(previous, element),
            identifier,
            [name],
          );
        } else {
          setterScope[name] = element;
        }
      }
    }
  }

  void _checkValuesDeclarationInEnum(SimpleIdentifier name) {
    if (name.name == 'values') {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM,
        name,
      );
    }
  }

  ExecutableElement? _getInheritedMember(
      ClassElement element, String baseName) {
    var libraryUri = _currentLibrary.source.uri;

    var getterName = Name(libraryUri, baseName);
    var getter = _inheritanceManager.getInherited2(element, getterName);
    if (getter != null) {
      return getter;
    }

    var setterName = Name(libraryUri, '$baseName=');
    return _inheritanceManager.getInherited2(element, setterName);
  }

  ExecutableElement? _getInterfaceMember(
      ClassElement element, String baseName) {
    var libraryUri = _currentLibrary.source.uri;

    var getterName = Name(libraryUri, baseName);
    var getter = _inheritanceManager.getMember2(element, getterName);
    if (getter != null) {
      return getter;
    }

    var setterName = Name(libraryUri, '$baseName=');
    return _inheritanceManager.getMember2(element, setterName);
  }

  static bool _isGetterSetterPair(Element a, Element b) {
    if (a is PropertyAccessorElement && b is PropertyAccessorElement) {
      return a.isGetter && b.isSetter || a.isSetter && b.isGetter;
    }
    return false;
  }
}
