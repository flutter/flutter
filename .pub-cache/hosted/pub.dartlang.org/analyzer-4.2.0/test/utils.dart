// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';

/// The type of an assertion which asserts properties of [T]s.
typedef Asserter<T> = void Function(T type);

/// The type of a function which given an [S], builds an assertion over [T]s.
typedef AsserterBuilder<S, T> = Asserter<T> Function(S arg);

/// The type of a function which given an [S0] and an S1, builds an assertion
/// over [T]s.
typedef AsserterBuilder2<S0, S1, T> = Asserter<T> Function(S0 arg0, S1 arg1);

/// The type of a function which given an [R] returns an [AsserterBuilder] over
/// [S]s and [T]s.  That is, it returns a function which given an [S], returns
/// a function over [T]s.
typedef AsserterBuilderBuilder<R, S, T> = AsserterBuilder<S, T> Function(R arg);

class AstFinder {
  /// Return the declaration of the class with the given [className] in the
  /// given compilation [unit].
  static ClassDeclaration getClass(CompilationUnit unit, String className) {
    NodeList<CompilationUnitMember> unitMembers = unit.declarations;
    for (CompilationUnitMember unitMember in unitMembers) {
      if (unitMember is ClassDeclaration && unitMember.name.name == className) {
        return unitMember;
      }
    }
    Source source = unit.declaredElement!.source;
    fail('No class named $className in $source');
  }

  /// Return the declaration of the constructor with the given [constructorName]
  /// in the class with the given [className] in the given compilation [unit].
  /// If constructorName is null, return the default constructor;
  static ConstructorDeclaration getConstructorInClass(
      CompilationUnit unit, String className, String? constructorName) {
    ClassDeclaration unitMember = getClass(unit, className);
    NodeList<ClassMember> classMembers = unitMember.members;
    for (ClassMember classMember in classMembers) {
      if (classMember is ConstructorDeclaration) {
        if (classMember.name?.name == constructorName) {
          return classMember;
        }
      }
    }
    fail('No constructor named $constructorName in $className');
  }

  /// Return the declaration of the field with the given [fieldName] in the
  /// class with the given [className] in the given compilation [unit].
  static VariableDeclaration getFieldInClass(
      CompilationUnit unit, String className, String fieldName) {
    ClassDeclaration unitMember = getClass(unit, className);
    NodeList<ClassMember> classMembers = unitMember.members;
    for (ClassMember classMember in classMembers) {
      if (classMember is FieldDeclaration) {
        NodeList<VariableDeclaration> fields = classMember.fields.variables;
        for (VariableDeclaration field in fields) {
          if (field.name.name == fieldName) {
            return field;
          }
        }
      }
    }
    fail('No field named $fieldName in $className');
  }

  /// Return the element of the field with the given [fieldName] in the class
  /// with the given [className] in the given compilation [unit].
  static FieldElement? getFieldInClassElement(
      CompilationUnit unit, String className, String fieldName) {
    return getFieldInClass(unit, className, fieldName).name.staticElement
        as FieldElement;
  }

  /// Return the declaration of the method with the given [methodName] in the
  /// class with the given [className] in the given compilation [unit].
  static MethodDeclaration getMethodInClass(
      CompilationUnit unit, String className, String methodName) {
    ClassDeclaration unitMember = getClass(unit, className);
    NodeList<ClassMember> classMembers = unitMember.members;
    for (ClassMember classMember in classMembers) {
      if (classMember is MethodDeclaration) {
        if (classMember.name.name == methodName) {
          return classMember;
        }
      }
    }
    fail('No method named $methodName in $className');
  }

  /// Return the statements in the body of a the method with the given
  /// [methodName] in the class with the given [className] in the given
  /// compilation [unit].
  static List<Statement> getStatementsInMethod(
      CompilationUnit unit, String className, String methodName) {
    MethodDeclaration method = getMethodInClass(unit, className, methodName);
    var body = method.body as BlockFunctionBody;
    return body.block.statements;
  }

  /// Return the statements in the body of the top-level function with the given
  /// [functionName] in the given compilation [unit].
  static List<Statement> getStatementsInTopLevelFunction(
      CompilationUnit unit, String functionName) {
    FunctionDeclaration function = getTopLevelFunction(unit, functionName);
    var body = function.functionExpression.body as BlockFunctionBody;
    return body.block.statements;
  }

  /// Return the declaration of the top-level function with the given
  /// [functionName] in the given compilation [unit].
  static FunctionDeclaration getTopLevelFunction(
      CompilationUnit unit, String functionName) {
    NodeList<CompilationUnitMember> unitMembers = unit.declarations;
    for (CompilationUnitMember unitMember in unitMembers) {
      if (unitMember is FunctionDeclaration) {
        if (unitMember.name.name == functionName) {
          return unitMember;
        }
      }
    }
    fail('No toplevel function named $functionName found');
  }

  /// Return the declaration of the top-level variable with the given
  /// [variableName] in the given compilation [unit].
  static VariableDeclaration getTopLevelVariable(
      CompilationUnit unit, String variableName) {
    NodeList<CompilationUnitMember> unitMembers = unit.declarations;
    for (CompilationUnitMember unitMember in unitMembers) {
      if (unitMember is TopLevelVariableDeclaration) {
        NodeList<VariableDeclaration> variables =
            unitMember.variables.variables;
        for (VariableDeclaration variable in variables) {
          if (variable.name.name == variableName) {
            return variable;
          }
        }
      }
    }
    fail('No toplevel variable named $variableName found');
  }

  /// Return the top-level variable element with the given [name].
  static TopLevelVariableElement getTopLevelVariableElement(
      CompilationUnit unit, String name) {
    return getTopLevelVariable(unit, name).name.staticElement
        as TopLevelVariableElement;
  }
}

/// Class for compositionally building up assertions on types
class TypeAssertions {
  // TODO(leafp): Make these matchers.
  // https://pub.dev/documentation/matcher/latest/matcher/Matcher-class.html

  /// Provides primitive types for basic type assertions.
  final TypeProvider _typeProvider;

  TypeAssertions(this._typeProvider);

  /// Primitive assertion for the dynamic type
  Asserter<DartType> get isDynamic => isType(_typeProvider.dynamicType);

  /// Primitive assertion for the int type
  Asserter<DartType> get isInt => isType(_typeProvider.intType);

  /// Primitive assertion for the list type
  Asserter<DartType> get isList => hasElement(_typeProvider.listElement);

  /// Primitive assertion for the map type
  Asserter<DartType> get isMap => hasElement(_typeProvider.mapElement);

  /// Primitive assertion for the Null type
  Asserter<DartType> get isNull => isType(_typeProvider.nullType);

  /// Primitive assertion for the num type
  Asserter<DartType> get isNum => isType(_typeProvider.numType);

  /// Primitive assertion for the Object type
  Asserter<DartType> get isObject => isType(_typeProvider.objectType);

  /// Primitive assertion for the string type
  Asserter<DartType> get isString => isType(_typeProvider.stringType);

  /// Assert that a type has the element that is equal to the [expected].
  Asserter<DartType> hasElement(Element expected) =>
      (DartType type) => expect(expected, type.element);

  /// Given assertions for the argument and return types, produce an
  /// assertion over unary function types.
  Asserter<DartType> isFunction2Of(
          Asserter<DartType> argType, Asserter<DartType> returnType) =>
      (DartType type) {
        FunctionType fType = type as FunctionType;
        argType(fType.normalParameterTypes[0]);
        returnType(fType.returnType);
      };

  /// Given an assertion for the base type and assertions over the type
  /// parameters, produce an assertion over instantiations.
  AsserterBuilder<List<Asserter<DartType>>, DartType> isInstantiationOf(
          Asserter<DartType> baseAssert) =>
      (List<Asserter<DartType>> argAsserts) => (DartType type) {
            InterfaceType t = type as InterfaceType;
            baseAssert(t);
            List<DartType> typeArguments = t.typeArguments;
            expect(typeArguments, hasLength(argAsserts.length));
            for (int i = 0; i < typeArguments.length; i++) {
              argAsserts[i](typeArguments[i]);
            }
          };

  /// Assert that a type is the List type, and that the given assertion holds
  /// over the type parameter.
  Asserter<InterfaceType> isListOf(Asserter<DartType> argAssert) =>
      isInstantiationOf(isList)([argAssert]);

  /// Assert that a type is the Map type, and that the given assertions hold
  /// over the type parameters.
  Asserter<InterfaceType> isMapOf(
          Asserter<DartType> argAssert0, Asserter<DartType> argAssert1) =>
      isInstantiationOf(isMap)([argAssert0, argAssert1]);

  /// Assert that a type is equal to the [expected].
  Asserter<DartType> isType(DartType expected) => (DartType t) {
        expect(t, expected);
      };
}
