// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstBuilderTest);
  });
}

@reflectiveTest
class AstBuilderTest extends FastaParserTestCase {
  void test_constructor_factory_misnamed() {
    CompilationUnit unit = parseCompilationUnit('''
class A {
  factory B() => throw 0;
}
''');
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration, isNotNull);
    expect(declaration.members, hasLength(1));
    var member = declaration.members[0] as ConstructorDeclaration;
    expect(member, isNotNull);
    expect(member.factoryKeyword, isNotNull);
    expect(member.name, isNull);
    expect(member.returnType.name, 'B');
  }

  void test_constructor_wrongName() {
    CompilationUnit unit = parseCompilationUnit('''
class A {
  B() : super();
}
''', errors: [
      expectedError(ParserErrorCode.INVALID_CONSTRUCTOR_NAME, 12, 1),
    ]);
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration, isNotNull);
    expect(declaration.members, hasLength(1));
    var member = declaration.members[0] as ConstructorDeclaration;
    expect(member, isNotNull);
    expect(member.initializers, hasLength(1));
  }

  void test_getter_sameNameAsClass() {
    CompilationUnit unit = parseCompilationUnit('''
class A {
  get A => 0;
}
''', errors: [
      expectedError(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 16, 1),
    ]);
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
    var declaration = unit.declarations[0] as ClassDeclaration;
    expect(declaration, isNotNull);
    expect(declaration.members, hasLength(1));
    var member = declaration.members[0] as MethodDeclaration;
    expect(member, isNotNull);
    expect(member.isGetter, isTrue);
    expect(member.name.name, 'A');
  }
}
