// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/feature_sets.dart';
import 'parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NewAsIdentifierParserTest);
  });
}

/// Tests exercising the fasta parser's handling of generic instantiations.
@reflectiveTest
class NewAsIdentifierParserTest extends FastaParserTestCase {
  void test_constructor_field_initializer() {
    // Even though `C() : this.new();` is allowed, `C() : this.new = ...;`
    // should not be.
    parseCompilationUnit('''
class C {
  C() : this.new = null;
}
''', errors: [
      expectedError(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 18, 4),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 23, 3),
      expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 23, 3),
      expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 23, 3),
      expectedError(ParserErrorCode.MISSING_KEYWORD_OPERATOR, 27, 1),
      expectedError(ParserErrorCode.INVALID_OPERATOR, 27, 1),
      expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 27, 1),
      expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 29, 4),
      expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 29, 4),
      expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 33, 1),
    ]);
  }

  void test_constructor_invocation_const() {
    var instanceCreationExpression =
        parseExpression('const C.new()') as InstanceCreationExpression;
    // Parsing treats `new` as an identifier, so `D.new` is classified as a
    // type.  Resolution will change the type to `D` and the name to `new` if
    // appropriate.
    var constructorName = instanceCreationExpression.constructorName;
    var typeName = constructorName.type.name as PrefixedIdentifier;
    expect(typeName.prefix.name, 'C');
    expect(typeName.identifier.name, 'new');
    expect(constructorName.type.typeArguments, isNull);
    expect(constructorName.name, isNull);
    expect(instanceCreationExpression.argumentList, isNotNull);
  }

  void test_constructor_invocation_const_generic() {
    var instanceCreationExpression =
        parseExpression('const C<int>.new()') as InstanceCreationExpression;
    var constructorName = instanceCreationExpression.constructorName;
    var typeName = constructorName.type.name as SimpleIdentifier;
    expect(typeName.name, 'C');
    expect(constructorName.type.typeArguments!.arguments, hasLength(1));
    expect(constructorName.name!.name, 'new');
    expect(instanceCreationExpression.argumentList, isNotNull);
  }

  void test_constructor_invocation_const_prefixed() {
    var instanceCreationExpression =
        parseExpression('const prefix.C.new()') as InstanceCreationExpression;
    var constructorName = instanceCreationExpression.constructorName;
    var typeName = constructorName.type.name as PrefixedIdentifier;
    expect(typeName.prefix.name, 'prefix');
    expect(typeName.identifier.name, 'C');
    expect(constructorName.type.typeArguments, isNull);
    expect(constructorName.name!.name, 'new');
    expect(instanceCreationExpression.argumentList, isNotNull);
  }

  void test_constructor_invocation_const_prefixed_generic() {
    var instanceCreationExpression = parseExpression(
      'const prefix.C<int>.new()',
    ) as InstanceCreationExpression;
    var constructorName = instanceCreationExpression.constructorName;
    var typeName = constructorName.type.name as PrefixedIdentifier;
    expect(typeName.prefix.name, 'prefix');
    expect(typeName.identifier.name, 'C');
    expect(constructorName.type.typeArguments!.arguments, hasLength(1));
    expect(constructorName.name!.name, 'new');
    expect(instanceCreationExpression.argumentList, isNotNull);
  }

  void test_constructor_invocation_explicit() {
    var instanceCreationExpression =
        parseExpression('new C.new()') as InstanceCreationExpression;
    // Parsing treats `new` as an identifier, so `D.new` is classified as a
    // type.  Resolution will change the type to `D` and the name to `new` if
    // appropriate.
    var constructorName = instanceCreationExpression.constructorName;
    var typeName = constructorName.type.name as PrefixedIdentifier;
    expect(typeName.prefix.name, 'C');
    expect(typeName.identifier.name, 'new');
    expect(constructorName.type.typeArguments, isNull);
    expect(constructorName.name, isNull);
    expect(instanceCreationExpression.argumentList, isNotNull);
  }

  void test_constructor_invocation_explicit_generic() {
    var instanceCreationExpression =
        parseExpression('new C<int>.new()') as InstanceCreationExpression;
    var constructorName = instanceCreationExpression.constructorName;
    var typeName = constructorName.type.name as SimpleIdentifier;
    expect(typeName.name, 'C');
    expect(constructorName.type.typeArguments!.arguments, hasLength(1));
    expect(constructorName.name!.name, 'new');
    expect(instanceCreationExpression.argumentList, isNotNull);
  }

  void test_constructor_invocation_explicit_prefixed() {
    var instanceCreationExpression =
        parseExpression('new prefix.C.new()') as InstanceCreationExpression;
    var constructorName = instanceCreationExpression.constructorName;
    var typeName = constructorName.type.name as PrefixedIdentifier;
    expect(typeName.prefix.name, 'prefix');
    expect(typeName.identifier.name, 'C');
    expect(constructorName.type.typeArguments, isNull);
    expect(constructorName.name!.name, 'new');
    expect(instanceCreationExpression.argumentList, isNotNull);
  }

  void test_constructor_invocation_explicit_prefixed_generic() {
    var instanceCreationExpression = parseExpression(
      'new prefix.C<int>.new()',
    ) as InstanceCreationExpression;
    var constructorName = instanceCreationExpression.constructorName;
    var typeName = constructorName.type.name as PrefixedIdentifier;
    expect(typeName.prefix.name, 'prefix');
    expect(typeName.identifier.name, 'C');
    expect(constructorName.type.typeArguments!.arguments, hasLength(1));
    expect(constructorName.name!.name, 'new');
    expect(instanceCreationExpression.argumentList, isNotNull);
  }

  void test_constructor_invocation_implicit() {
    var methodInvocation = parseExpression('C.new()') as MethodInvocation;
    var target = methodInvocation.target as SimpleIdentifier;
    expect(target.name, 'C');
    expect(methodInvocation.methodName.name, 'new');
    expect(methodInvocation.typeArguments, isNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void test_constructor_invocation_implicit_generic() {
    var instanceCreationExpression =
        parseExpression('C<int>.new()') as InstanceCreationExpression;
    var constructorName = instanceCreationExpression.constructorName;
    var typeName = constructorName.type.name as SimpleIdentifier;
    expect(typeName.name, 'C');
    expect(constructorName.type.typeArguments!.arguments, hasLength(1));
    expect(constructorName.name!.name, 'new');
    expect(instanceCreationExpression.argumentList, isNotNull);
  }

  void test_constructor_invocation_implicit_prefixed() {
    var methodInvocation =
        parseExpression('prefix.C.new()') as MethodInvocation;
    var target = methodInvocation.target as PrefixedIdentifier;
    expect(target.prefix.name, 'prefix');
    expect(target.identifier.name, 'C');
    expect(methodInvocation.methodName.name, 'new');
    expect(methodInvocation.typeArguments, isNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void test_constructor_invocation_implicit_prefixed_generic() {
    var instanceCreationExpression =
        parseExpression('prefix.C<int>.new()') as InstanceCreationExpression;
    var constructorName = instanceCreationExpression.constructorName;
    var typeName = constructorName.type.name as PrefixedIdentifier;
    expect(typeName.prefix.name, 'prefix');
    expect(typeName.identifier.name, 'C');
    expect(constructorName.type.typeArguments!.arguments, hasLength(1));
    expect(constructorName.name!.name, 'new');
    expect(instanceCreationExpression.argumentList, isNotNull);
  }

  void test_constructor_name() {
    var unit = parseCompilationUnit('''
class C {
  C.new();
}
''');
    var classDeclaration = unit.declarations.single as ClassDeclaration;
    var constructorDeclaration =
        classDeclaration.members.single as ConstructorDeclaration;
    expect(constructorDeclaration.name!.lexeme, 'new');
  }

  void test_constructor_name_factory() {
    var unit = parseCompilationUnit('''
class C {
  factory C.new() => C._();
  C._();
}
''');
    var classDeclaration = unit.declarations.single as ClassDeclaration;
    var constructorDeclaration =
        classDeclaration.members[0] as ConstructorDeclaration;
    expect(constructorDeclaration.name!.lexeme, 'new');
  }

  void test_constructor_tearoff() {
    var prefixedIdentifier = parseExpression('C.new') as PrefixedIdentifier;
    expect(prefixedIdentifier.prefix.name, 'C');
    expect(prefixedIdentifier.identifier.name, 'new');
  }

  void test_constructor_tearoff_generic() {
    var propertyAccess = parseExpression('C<int>.new') as PropertyAccess;
    var target = propertyAccess.target as FunctionReference;
    var className = target.function as SimpleIdentifier;
    expect(className.name, 'C');
    expect(target.typeArguments, isNotNull);
    expect(propertyAccess.propertyName.name, 'new');
  }

  void test_constructor_tearoff_generic_method_invocation() {
    var methodInvocation =
        parseExpression('C<int>.new.toString()') as MethodInvocation;
    var target = methodInvocation.target as PropertyAccess;
    var functionReference = target.target as FunctionReference;
    var className = functionReference.function as SimpleIdentifier;
    expect(className.name, 'C');
    expect(functionReference.typeArguments, isNotNull);
    expect(target.propertyName.name, 'new');
    expect(methodInvocation.methodName.name, 'toString');
    expect(methodInvocation.typeArguments, isNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void test_constructor_tearoff_in_comment_reference() {
    createParser('');
    var commentReference = parseCommentReference('C.new', 5)!;
    var identifier = commentReference.expression as PrefixedIdentifier;
    expect(identifier.prefix.name, 'C');
    expect(identifier.identifier.name, 'new');
  }

  void test_constructor_tearoff_method_invocation() {
    var methodInvocation =
        parseExpression('C.new.toString()') as MethodInvocation;
    var target = methodInvocation.target as PrefixedIdentifier;
    expect(target.prefix.name, 'C');
    expect(target.identifier.name, 'new');
    expect(methodInvocation.methodName.name, 'toString');
    expect(methodInvocation.typeArguments, isNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void test_constructor_tearoff_prefixed() {
    var propertyAccess = parseExpression('prefix.C.new') as PropertyAccess;
    var target = propertyAccess.target as PrefixedIdentifier;
    expect(target.prefix.name, 'prefix');
    expect(target.identifier.name, 'C');
    expect(propertyAccess.propertyName.name, 'new');
  }

  void test_constructor_tearoff_prefixed_generic() {
    var propertyAccess = parseExpression('prefix.C<int>.new') as PropertyAccess;
    var target = propertyAccess.target as FunctionReference;
    var className = target.function as PrefixedIdentifier;
    expect(className.prefix.name, 'prefix');
    expect(className.identifier.name, 'C');
    expect(target.typeArguments, isNotNull);
    expect(propertyAccess.propertyName.name, 'new');
  }

  void test_constructor_tearoff_prefixed_generic_method_invocation() {
    var methodInvocation = parseExpression(
      'prefix.C<int>.new.toString()',
    ) as MethodInvocation;
    var target = methodInvocation.target as PropertyAccess;
    var functionReference = target.target as FunctionReference;
    var className = functionReference.function as PrefixedIdentifier;
    expect(className.prefix.name, 'prefix');
    expect(className.identifier.name, 'C');
    expect(functionReference.typeArguments, isNotNull);
    expect(target.propertyName.name, 'new');
    expect(methodInvocation.methodName.name, 'toString');
    expect(methodInvocation.typeArguments, isNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void test_constructor_tearoff_prefixed_method_invocation() {
    var methodInvocation = parseExpression(
      'prefix.C.new.toString()',
    ) as MethodInvocation;
    var target = methodInvocation.target as PropertyAccess;
    var prefixedIdentifier = target.target as PrefixedIdentifier;
    expect(prefixedIdentifier.prefix.name, 'prefix');
    expect(prefixedIdentifier.identifier.name, 'C');
    expect(target.propertyName.name, 'new');
    expect(methodInvocation.methodName.name, 'toString');
    expect(methodInvocation.typeArguments, isNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void test_disabled() {
    var unit = parseCompilationUnit(
        '''
class C {
  C.new();
}
''',
        featureSet: FeatureSets.language_2_13,
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 14, 3),
        ]);
    var classDeclaration = unit.declarations.single as ClassDeclaration;
    var constructorDeclaration =
        classDeclaration.members.single as ConstructorDeclaration;
    expect(constructorDeclaration.name!.lexeme, 'new');
  }

  void test_factory_redirection() {
    var unit = parseCompilationUnit('''
class C {
  factory C() = D.new;
}
''');
    var classDeclaration = unit.declarations.single as ClassDeclaration;
    var constructorDeclaration =
        classDeclaration.members.single as ConstructorDeclaration;
    expect(constructorDeclaration.initializers, isEmpty);
    // Parsing treats `new` as an identifier, so `D.new` is classified as a
    // type.  Resolution will change the type to `D` and the name to `new` if
    // appropriate.
    var redirectedConstructor = constructorDeclaration.redirectedConstructor!;
    var typeName = redirectedConstructor.type.name as PrefixedIdentifier;
    expect(typeName.prefix.name, 'D');
    expect(typeName.identifier.name, 'new');
    expect(redirectedConstructor.type.typeArguments, isNull);
    expect(redirectedConstructor.name, isNull);
  }

  void test_factory_redirection_generic() {
    var unit = parseCompilationUnit('''
class C {
  factory C() = D<int>.new;
}
''');
    var classDeclaration = unit.declarations.single as ClassDeclaration;
    var constructorDeclaration =
        classDeclaration.members.single as ConstructorDeclaration;
    expect(constructorDeclaration.initializers, isEmpty);
    var redirectedConstructor = constructorDeclaration.redirectedConstructor!;
    var typeName = redirectedConstructor.type.name as SimpleIdentifier;
    expect(typeName.name, 'D');
    expect(redirectedConstructor.type.typeArguments!.arguments, hasLength(1));
    expect(redirectedConstructor.name!.name, 'new');
  }

  void test_factory_redirection_prefixed() {
    var unit = parseCompilationUnit('''
class C {
  factory C() = prefix.D.new;
}
''');
    var classDeclaration = unit.declarations.single as ClassDeclaration;
    var constructorDeclaration =
        classDeclaration.members.single as ConstructorDeclaration;
    expect(constructorDeclaration.initializers, isEmpty);
    var redirectedConstructor = constructorDeclaration.redirectedConstructor!;
    var typeName = redirectedConstructor.type.name as PrefixedIdentifier;
    expect(typeName.prefix.name, 'prefix');
    expect(typeName.identifier.name, 'D');
    expect(redirectedConstructor.type.typeArguments, isNull);
    expect(redirectedConstructor.name!.name, 'new');
  }

  void test_factory_redirection_prefixed_generic() {
    var unit = parseCompilationUnit('''
class C {
  factory C() = prefix.D<int>.new;
}
''');
    var classDeclaration = unit.declarations.single as ClassDeclaration;
    var constructorDeclaration =
        classDeclaration.members.single as ConstructorDeclaration;
    expect(constructorDeclaration.initializers, isEmpty);
    var redirectedConstructor = constructorDeclaration.redirectedConstructor!;
    var typeName = redirectedConstructor.type.name as PrefixedIdentifier;
    expect(typeName.prefix.name, 'prefix');
    expect(typeName.identifier.name, 'D');
    expect(redirectedConstructor.type.typeArguments!.arguments, hasLength(1));
    expect(redirectedConstructor.name!.name, 'new');
  }

  void test_super_invocation() {
    var unit = parseCompilationUnit('''
class C extends B {
  C() : super.new();
}
''');
    var classDeclaration = unit.declarations.single as ClassDeclaration;
    var constructorDeclaration =
        classDeclaration.members.single as ConstructorDeclaration;
    expect(constructorDeclaration.redirectedConstructor, isNull);
    var superConstructorInvocation = constructorDeclaration.initializers.single
        as SuperConstructorInvocation;
    expect(superConstructorInvocation.constructorName!.name, 'new');
  }

  void test_this_redirection() {
    var unit = parseCompilationUnit('''
class C {
  C.named() : this.new();
  C();
}
''');
    var classDeclaration = unit.declarations.single as ClassDeclaration;
    var constructorDeclaration =
        classDeclaration.members[0] as ConstructorDeclaration;
    expect(constructorDeclaration.redirectedConstructor, isNull);
    var redirectingConstructorInvocation = constructorDeclaration
        .initializers.single as RedirectingConstructorInvocation;
    expect(redirectingConstructorInvocation.constructorName!.name, 'new');
  }
}
