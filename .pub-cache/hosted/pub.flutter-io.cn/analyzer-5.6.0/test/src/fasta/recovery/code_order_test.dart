// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'recovery_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationTest);
    defineReflectiveTests(CompilationUnitMemberTest);
    defineReflectiveTests(ImportDirectiveTest);
    defineReflectiveTests(MisplacedMetadataTest);
    defineReflectiveTests(MixinDeclarationTest);
    defineReflectiveTests(TryStatementTest);
  });
}

/// Test how well the parser recovers when the clauses in a class declaration
/// are out of order.
@reflectiveTest
class ClassDeclarationTest extends AbstractRecoveryTest {
  void test_implementsBeforeExtends() {
    testRecovery('''
class A implements B extends C {}
''', [ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS], '''
class A extends C implements B {}
''');
  }

  void test_implementsBeforeWith() {
    testRecovery('''
class A extends B implements C with D {}
''', [ParserErrorCode.IMPLEMENTS_BEFORE_WITH], '''
class A extends B with D implements C {}
''');
  }

  void test_implementsBeforeWithBeforeExtends() {
    testRecovery('''
class A implements B with C extends D {}
''', [
      ParserErrorCode.IMPLEMENTS_BEFORE_WITH,
      ParserErrorCode.WITH_BEFORE_EXTENDS
    ], '''
class A extends D with C implements B {}
''');
  }

  void test_multipleExtends() {
    testRecovery('''
class A extends B extends C {}
''', [ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES], '''
class A extends B {}
''');
  }

  void test_multipleImplements() {
    testRecovery('''
class A implements B implements C, D {}
''', [ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES], '''
class A implements B, C, D {}
''');
  }

  void test_multipleWith() {
    testRecovery('''
class A extends B with C, D with E {}
''', [ParserErrorCode.MULTIPLE_WITH_CLAUSES], '''
class A extends B with C, D, E {}
''');
  }

  @failingTest
  void test_typing_extends() {
    testRecovery('''
class Foo exte
class UnrelatedClass extends Bar {}
''', [ParserErrorCode.MULTIPLE_WITH_CLAUSES], '''
class Foo {}
class UnrelatedClass extends Bar {}
''');
  }

  void test_typing_extends_identifier() {
    testRecovery('''
class Foo extends CurrentlyTypingHere
class UnrelatedClass extends Bar {}
''', [ParserErrorCode.EXPECTED_BODY], '''
class Foo extends CurrentlyTypingHere {}
class UnrelatedClass extends Bar {}
''');
  }

  void test_withBeforeExtends() {
    testRecovery('''
class A with B extends C {}
''', [ParserErrorCode.WITH_BEFORE_EXTENDS], '''
class A extends C with B {}
''');
  }
}

/// Test how well the parser recovers when the members of a compilation unit are
/// out of order.
@reflectiveTest
class CompilationUnitMemberTest extends AbstractRecoveryTest {
  void test_declarationBeforeDirective_export() {
    testRecovery('''
class C { }
export 'bar.dart';
''', [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION], '''
export 'bar.dart';
class C { }
''', adjustValidUnitBeforeComparison: _updateBeginToken);
  }

  void test_declarationBeforeDirective_import() {
    testRecovery('''
class C { }
import 'bar.dart';
''', [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION], '''
import 'bar.dart';
class C { }
''', adjustValidUnitBeforeComparison: _updateBeginToken);
  }

  void test_declarationBeforeDirective_part() {
    testRecovery('''
class C { }
part 'bar.dart';
''', [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION], '''
part 'bar.dart';
class C { }
''', adjustValidUnitBeforeComparison: _updateBeginToken);
  }

  void test_declarationBeforeDirective_part_of() {
    testRecovery('''
class C { }
part of foo;
''', [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION], '''
part of foo;
class C { }
''', adjustValidUnitBeforeComparison: _updateBeginToken);
  }

  void test_exportBeforeLibrary() {
    testRecovery('''
export 'bar.dart';
library l;
''', [ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST], '''
library l;
export 'bar.dart';
''', adjustValidUnitBeforeComparison: _moveFirstDirectiveToEnd);
  }

  void test_importBeforeLibrary() {
    testRecovery('''
import 'bar.dart';
library l;
''', [ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST], '''
library l;
import 'bar.dart';
''', adjustValidUnitBeforeComparison: _moveFirstDirectiveToEnd);
  }

  void test_partBeforeExport() {
    testRecovery('''
part 'foo.dart';
export 'bar.dart';
''', [ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE], '''
export 'bar.dart';
part 'foo.dart';
''', adjustValidUnitBeforeComparison: _moveFirstDirectiveToEnd);
  }

  void test_partBeforeImport() {
    testRecovery('''
part 'foo.dart';
import 'bar.dart';
''', [ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE], '''
import 'bar.dart';
part 'foo.dart';
''', adjustValidUnitBeforeComparison: _moveFirstDirectiveToEnd);
  }

  void test_partBeforeLibrary() {
    testRecovery('''
part 'foo.dart';
library l;
''', [ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST], '''
library l;
part 'foo.dart';
''', adjustValidUnitBeforeComparison: _moveFirstDirectiveToEnd);
  }

  CompilationUnitImpl _moveFirstDirectiveToEnd(CompilationUnitImpl unit) {
    return CompilationUnitImpl(
      beginToken: unit.directives.skip(1).first.beginToken,
      scriptTag: unit.scriptTag,
      directives: [
        ...unit.directives.skip(1),
        unit.directives.first,
      ],
      declarations: unit.declarations,
      endToken: unit.endToken,
      featureSet: unit.featureSet,
      lineInfo: unit.lineInfo,
    );
  }

  CompilationUnitImpl _updateBeginToken(CompilationUnitImpl unit) {
    unit.beginToken = unit.declarations[0].beginToken;
    return unit;
  }
}

/// Test how well the parser recovers when the members of an import directive
/// are out of order.
@reflectiveTest
class ImportDirectiveTest extends AbstractRecoveryTest {
  void test_combinatorsBeforeAndAfterPrefix() {
    testRecovery('''
import 'bar.dart' show A as p show B;
''', [ParserErrorCode.PREFIX_AFTER_COMBINATOR], '''
import 'bar.dart' as p show A show B;
''');
  }

  void test_combinatorsBeforePrefix() {
    testRecovery('''
import 'bar.dart' show A as p;
''', [ParserErrorCode.PREFIX_AFTER_COMBINATOR], '''
import 'bar.dart' as p show A;
''');
  }

  void test_combinatorsBeforePrefixAfterDeferred() {
    testRecovery('''
import 'bar.dart' deferred show A as p;
''', [ParserErrorCode.PREFIX_AFTER_COMBINATOR], '''
import 'bar.dart' deferred as p show A;
''');
  }

  void test_deferredAfterPrefix() {
    testRecovery('''
import 'bar.dart' as p deferred;
''', [ParserErrorCode.DEFERRED_AFTER_PREFIX], '''
import 'bar.dart' deferred as p;
''');
  }

  void test_duplicatePrefix() {
    testRecovery('''
import 'bar.dart' as p as q;
''', [ParserErrorCode.DUPLICATE_PREFIX], '''
import 'bar.dart' as p;
''');
  }

  void test_unknownTokenAtEnd() {
    testRecovery('''
import 'bar.dart' as p sh;
''', [ParserErrorCode.UNEXPECTED_TOKEN], '''
import 'bar.dart' as p;
''');
  }

  void test_unknownTokenBeforePrefix() {
    testRecovery('''
import 'bar.dart' d as p;
''', [ParserErrorCode.UNEXPECTED_TOKEN], '''
import 'bar.dart' as p;
''');
  }

  void test_unknownTokenBeforePrefixAfterCombinatorMissingSemicolon() {
    testRecovery('''
import 'bar.dart' d show A as p
import 'b.dart';
''', [
      ParserErrorCode.UNEXPECTED_TOKEN,
      ParserErrorCode.PREFIX_AFTER_COMBINATOR,
      ParserErrorCode.EXPECTED_TOKEN
    ], '''
import 'bar.dart' as p show A;
import 'b.dart';
''');
  }

  void test_unknownTokenBeforePrefixAfterDeferred() {
    testRecovery('''
import 'bar.dart' deferred s as p;
''', [ParserErrorCode.UNEXPECTED_TOKEN], '''
import 'bar.dart' deferred as p;
''');
  }
}

/// Test how well the parser recovers when metadata appears in invalid places.
@reflectiveTest
class MisplacedMetadataTest extends AbstractRecoveryTest {
  @failingTest
  void test_field_afterType() {
    // This test fails because `findMemberName` doesn't recognize that the `@`
    // isn't a valid token in the stream leading up to a member name. That
    // causes `parseMethod` to attempt to parse from the `x` as a function body.
    testRecovery('''
class A {
  const A([x]);
}
class B {
  dynamic @A(const A()) x;
}
''', [ParserErrorCode.UNEXPECTED_TOKEN], '''
class A {
  const A([x]);
}
class B {
  @A(const A()) dynamic x;
}
''');
  }
}

/// Test how well the parser recovers when the clauses in a mixin declaration
/// are out of order.
@reflectiveTest
class MixinDeclarationTest extends AbstractRecoveryTest {
  void test_implementsBeforeOn() {
    testRecovery('''
mixin A implements B on C {}
''', [ParserErrorCode.IMPLEMENTS_BEFORE_ON], '''
mixin A on C implements B {}
''');
  }

  void test_multipleImplements() {
    testRecovery('''
mixin A implements B implements C, D {}
''', [ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES], '''
mixin A implements B, C, D {}
''');
  }

  void test_multipleOn() {
    testRecovery('''
mixin A on B on C {}
''', [ParserErrorCode.MULTIPLE_ON_CLAUSES], '''
mixin A on B, C {}
''');
  }

  @failingTest
  void test_typing_implements() {
    testRecovery('''
mixin Foo imple
mixin UnrelatedMixin on Bar {}
''', [ParserErrorCode.MULTIPLE_WITH_CLAUSES], '''
mixin Foo {}
mixin UnrelatedMixin on Bar {}
''');
  }

  void test_typing_implements_identifier() {
    testRecovery('''
mixin Foo implements CurrentlyTypingHere
mixin UnrelatedMixin on Bar {}
''', [ParserErrorCode.EXPECTED_BODY], '''
mixin Foo implements CurrentlyTypingHere {}
mixin UnrelatedMixin on Bar {}
''');
  }
}

/// Test how well the parser recovers when the clauses in a try statement are
/// out of order.
@reflectiveTest
class TryStatementTest extends AbstractRecoveryTest {
  @failingTest
  void test_finallyBeforeCatch() {
    testRecovery('''
f() {
  try {
  } finally {
  } catch (e) {
  }
}
''', [/*ParserErrorCode.CATCH_AFTER_FINALLY*/], '''
f() {
  try {
  } catch (e) {
  } finally {
  }
}
''');
  }

  @failingTest
  void test_finallyBeforeOn() {
    testRecovery('''
f() {
  try {
  } finally {
  } on String {
  }
}
''', [/*ParserErrorCode.CATCH_AFTER_FINALLY*/], '''
f() {
  try {
  } on String {
  } finally {
  }
}
''');
  }
}
