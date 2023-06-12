// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/parser_test_base.dart';
import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompilationUnitImplTest);
    defineReflectiveTests(ExpressionImplTest);
    defineReflectiveTests(InstanceCreationExpressionImplTest);
    defineReflectiveTests(IntegerLiteralImplTest);
  });
}

@reflectiveTest
class CompilationUnitImplTest extends ParserTestCase {
  late final String testSource;
  late final CompilationUnitImpl testUnit;

  parse(String source) {
    testSource = source;
    testUnit = parseCompilationUnit(source) as CompilationUnitImpl;
  }

  test_languageVersionComment_afterScriptTag() {
    parse('''
#!/bin/false
// @dart=2.9
void main() {}
''');
    var token = testUnit.languageVersionToken!;
    expect(token.major, 2);
    expect(token.minor, 9);
    expect(token.offset, 13);
  }

  test_languageVersionComment_afterScriptTag_andComment() {
    parse('''
#!/bin/false
// A normal comment.
// @dart=2.9
void main() {}
''');
    var token = testUnit.languageVersionToken!;
    expect(token.major, 2);
    expect(token.minor, 9);
    expect(token.offset, 34);
  }

  test_languageVersionComment_firstComment() {
    parse('''
// @dart=2.6
void main() {}
''');
    expect(
        testUnit.languageVersionToken, testUnit.beginToken.precedingComments);
  }

  test_languageVersionComment_none() {
    parse('''
void main() {}
''');
    expect(testUnit.languageVersionToken, null);
  }

  test_languageVersionComment_none_onlyNormalComment() {
    parse('''
// A normal comment.
void main() {}
''');
    expect(testUnit.languageVersionToken, null);
  }

  test_languageVersionComment_secondComment() {
    parse('''
// A normal comment.
// @dart=2.6
void main() {}
''');
    expect(testUnit.languageVersionToken,
        testUnit.beginToken.precedingComments!.next);
  }

  test_languageVersionComment_thirdComment() {
    parse('''
// A normal comment.
// Another normal comment.
// @dart=2.6
void main() {}
''');
    expect(testUnit.languageVersionToken,
        testUnit.beginToken.precedingComments!.next!.next);
  }
}

@reflectiveTest
class ExpressionImplTest extends ParserTestCase {
  late final String testSource;
  late final CompilationUnitImpl testUnit;

  assertInContext(String snippet, bool isInContext) {
    int index = testSource.indexOf(snippet);
    expect(index >= 0, isTrue);
    NodeLocator visitor = NodeLocator(index);
    var node = visitor.searchWithin(testUnit) as AstNodeImpl;
    expect(node, TypeMatcher<ExpressionImpl>());
    expect((node as ExpressionImpl).inConstantContext,
        isInContext ? isTrue : isFalse);
  }

  parse(String source) {
    testSource = source;
    testUnit = parseCompilationUnit(source) as CompilationUnitImpl;
  }

  test_inConstantContext_instanceCreation_annotation_true() {
    parse('''
@C(C(0))
class C {
  const C(_);
}
''');
    assertInContext("C(0", true);
  }

  test_inConstantContext_instanceCreation_fieldWithConstConstructor() {
    parse('''
class C {
  final d = D();
  const C();
}
class D {
  const D();
}
''');
    assertInContext("D()", false);
  }

  test_inConstantContext_instanceCreation_fieldWithoutConstConstructor() {
    parse('''
class C {
  final d = D();
  C();
}
class D {
  const D();
}
''');
    assertInContext("D()", false);
  }

  test_inConstantContext_instanceCreation_functionLiteral() {
    parse('''
const V = () => C();
class C {
  const C();
}
''');
    assertInContext("C()", false);
  }

  test_inConstantContext_instanceCreation_instanceCreation_false() {
    parse('''
f() {
  return new C(C());
}
class C {
  const C(_);
}
''');
    assertInContext("C())", false);
  }

  test_inConstantContext_instanceCreation_instanceCreation_true() {
    parse('''
f() {
  return new C(C());
}
class C {
  const C(_);
}
''');
    assertInContext("C())", false);
  }

  test_inConstantContext_instanceCreation_listLiteral_false() {
    parse('''
f() {
  return [C()];
}
class C {
  const C();
}
''');
    assertInContext("C()]", false);
  }

  test_inConstantContext_instanceCreation_listLiteral_true() {
    parse('''
f() {
  return const [C()];
}
class C {
  const C();
}
''');
    assertInContext("C()]", true);
  }

  test_inConstantContext_instanceCreation_mapLiteral_false() {
    parse('''
f() {
  return {'a' : C()};
}
class C {
  const C();
}
''');
    assertInContext("C()}", false);
  }

  test_inConstantContext_instanceCreation_mapLiteral_true() {
    parse('''
f() {
  return const {'a' : C()};
}
class C {
  const C();
}
''');
    assertInContext("C()}", true);
  }

  test_inConstantContext_instanceCreation_nestedListLiteral_false() {
    parse('''
f() {
  return [[''], [C()]];
}
class C {
  const C();
}
''');
    assertInContext("C()]", false);
  }

  test_inConstantContext_instanceCreation_nestedListLiteral_true() {
    parse('''
f() {
  return const [[''], [C()]];
}
class C {
  const C();
}
''');
    assertInContext("C()]", true);
  }

  test_inConstantContext_instanceCreation_nestedMapLiteral_false() {
    parse('''
f() {
  return {'a' : {C() : C()}};
}
class C {
  const C();
}
''');
    assertInContext("C() :", false);
    assertInContext("C()}", false);
  }

  test_inConstantContext_instanceCreation_nestedMapLiteral_true() {
    parse('''
f() {
  return const {'a' : {C() : C()}};
}
class C {
  const C();
}
''');
    assertInContext("C() :", true);
    assertInContext("C()}", true);
  }

  test_inConstantContext_instanceCreation_switch_true() {
    parse('''
f(v) {
  switch (v) {
  case C():
    break;
  }
}
class C {
  const C();
}
''');
    assertInContext("C()", true);
  }

  test_inConstantContext_instanceCreation_topLevelVariable_false() {
    parse('''
var c = C();
class C {
  const C();
}
''');
    assertInContext("C()", false);
  }

  test_inConstantContext_instanceCreation_topLevelVariable_true() {
    parse('''
const c = C();
class C {
  const C();
}
''');
    assertInContext("C()", true);
  }

  test_inConstantContext_listLiteral_annotation_true() {
    parse('''
@C([])
class C {
  const C(_);
}
''');
    assertInContext("[]", true);
  }

  test_inConstantContext_listLiteral_functionLiteral() {
    parse('''
const V = () => [];
class C {
  const C();
}
''');
    assertInContext("[]", false);
  }

  test_inConstantContext_listLiteral_initializer_false() {
    parse('''
var c = [];
''');
    assertInContext("[]", false);
  }

  test_inConstantContext_listLiteral_initializer_true() {
    parse('''
const c = [];
''');
    assertInContext("[]", true);
  }

  test_inConstantContext_listLiteral_instanceCreation_false() {
    parse('''
f() {
  return new C([]);
}
class C {
  const C(_);
}
''');
    assertInContext("[]", false);
  }

  test_inConstantContext_listLiteral_instanceCreation_true() {
    parse('''
f() {
  return const C([]);
}
class C {
  const C(_);
}
''');
    assertInContext("[]", true);
  }

  test_inConstantContext_listLiteral_listLiteral_false() {
    parse('''
f() {
  return [[''], []];
}
''');
    assertInContext("['']", false);
    assertInContext("[]", false);
  }

  test_inConstantContext_listLiteral_listLiteral_true() {
    parse('''
f() {
  return const [[''], []];
}
''');
    assertInContext("['']", true);
    assertInContext("[]", true);
  }

  test_inConstantContext_listLiteral_mapLiteral_false() {
    parse('''
f() {
  return {'a' : [''], 'b' : []};
}
''');
    assertInContext("['']", false);
    assertInContext("[]", false);
  }

  test_inConstantContext_listLiteral_mapLiteral_true() {
    parse('''
f() {
  return const {'a' : [''], 'b' : []};
}
''');
    assertInContext("['']", true);
    assertInContext("[]", true);
  }

  test_inConstantContext_listLiteral_switch_true() {
    parse('''
f(v) {
  switch (v) {
  case []:
    break;
  }
}
''');
    assertInContext("[]", true);
  }

  test_inConstantContext_mapLiteral_annotation_true() {
    parse('''
@C({})
class C {
  const C(_);
}
''');
    assertInContext("{}", true);
  }

  test_inConstantContext_mapLiteral_functionLiteral() {
    parse('''
const V = () => {};
class C {
  const C();
}
''');
    assertInContext("{}", false);
  }

  test_inConstantContext_mapLiteral_initializer_false() {
    parse('''
var c = {};
''');
    assertInContext("{}", false);
  }

  test_inConstantContext_mapLiteral_initializer_true() {
    parse('''
const c = {};
''');
    assertInContext("{}", true);
  }

  test_inConstantContext_mapLiteral_instanceCreation_false() {
    parse('''
f() {
  return new C({});
}
class C {
  const C(_);
}
''');
    assertInContext("{}", false);
  }

  test_inConstantContext_mapLiteral_instanceCreation_true() {
    parse('''
f() {
  return const C({});
}
class C {
  const C(_);
}
''');
    assertInContext("{}", true);
  }

  test_inConstantContext_mapLiteral_listLiteral_false() {
    parse('''
f() {
  return [{'a' : 1}, {'b' : 2}];
}
''');
    assertInContext("{'a", false);
    assertInContext("{'b", false);
  }

  test_inConstantContext_mapLiteral_listLiteral_true() {
    parse('''
f() {
  return const [{'a' : 1}, {'b' : 2}];
}
''');
    assertInContext("{'a", true);
    assertInContext("{'b", true);
  }

  test_inConstantContext_mapLiteral_mapLiteral_false() {
    parse('''
f() {
  return {'a' : {'b' : 0}, 'c' : {'d' : 1}};
}
''');
    assertInContext("{'b", false);
    assertInContext("{'d", false);
  }

  test_inConstantContext_mapLiteral_mapLiteral_true() {
    parse('''
f() {
  return const {'a' : {'b' : 0}, 'c' : {'d' : 1}};
}
''');
    assertInContext("{'b", true);
    assertInContext("{'d", true);
  }

  test_inConstantContext_mapLiteral_switch_true() {
    parse('''
f(v) {
  switch (v) {
  case {}:
    break;
  }
}
''');
    assertInContext("{}", true);
  }
}

@reflectiveTest
class InstanceCreationExpressionImplTest extends PubPackageResolutionTest {
  assertIsConst(String search, bool expectedResult) {
    var node = findNode.instanceCreation(search);
    expect((node as InstanceCreationExpressionImpl).isConst, expectedResult);
  }

  test_isConst_notInContext_constructor_const_constParam_identifier() async {
    await resolveTestCode('''
var v = C(C.a);
class C {
  static const C a = C.c();
  const C(c);
  const C.c();
}
''');
    assertIsConst("C(C", false);
  }

  test_isConst_notInContext_constructor_const_constParam_named() async {
    await resolveTestCode('''
var v = C(c: C());
class C {
  const C({c});
}
''');
    assertIsConst("C(c", false);
  }

  test_isConst_notInContext_constructor_const_constParam_named_parens() async {
    await resolveTestCode('''
var v = C(c: (C()));
class C {
  const C({c});
}
''');
    assertIsConst("C(c", false);
  }

  test_isConst_notInContext_constructor_const_constParam_parens() async {
    await resolveTestCode('''
var v = C( (C.c()) );
class C {
  const C(c);
  const C.c();
}
''');
    assertIsConst("C( (", false);
  }

  test_isConst_notInContext_constructor_const_generic_named() async {
    await resolveTestCode('''
f() => <Object>[C<int>.n()];
class C<E> {
  const C.n();
}
''');
    assertIsConst("C<int>.n", false);
  }

  test_isConst_notInContext_constructor_const_generic_named_prefixed() async {
    newFile('$testPackageLibPath/c.dart', content: '''
class C<E> {
  const C.n();
}
''');
    await resolveTestCode('''
import 'c.dart' as p;
f() => <Object>[p.C<int>.n()];
''');
    assertIsConst("C<int>", false);
  }

  test_isConst_notInContext_constructor_const_generic_unnamed() async {
    await resolveTestCode('''
f() => <Object>[C<int>()];
class C<E> {
  const C();
}
''');
    assertIsConst("C<int>", false);
  }

  test_isConst_notInContext_constructor_const_generic_unnamed_prefixed() async {
    newFile('$testPackageLibPath/c.dart', content: '''
class C<E> {
  const C();
}
''');
    await resolveTestCode('''
import 'c.dart' as p;
f() => <Object>[p.C<int>()];
''');
    assertIsConst("C<int>", false);
  }

  test_isConst_notInContext_constructor_const_nonConstParam_constructor() async {
    await resolveTestCode('''
f() {
  return A(B());
}

class A {
  const A(B b);
}

class B {
  B();
}
''');
    assertIsConst("B())", false);
  }

  test_isConst_notInContext_constructor_const_nonConstParam_variable() async {
    await resolveTestCode('''
f(int i) => <Object>[C(i)];
class C {
  final int f;
  const C(this.f);
}
''');
    assertIsConst("C(i)", false);
  }

  test_isConst_notInContext_constructor_const_nonGeneric_named() async {
    await resolveTestCode('''
f() => <Object>[C.n()];
class C<E> {
  const C.n();
}
''');
    assertIsConst("C.n()]", false);
  }

  test_isConst_notInContext_constructor_const_nonGeneric_named_prefixed() async {
    newFile('$testPackageLibPath/c.dart', content: '''
class C {
  const C.n();
}
''');
    await resolveTestCode('''
import 'c.dart' as p;
f() => <Object>[p.C.n()];
''');
    assertIsConst("C.n()", false);
  }

  test_isConst_notInContext_constructor_const_nonGeneric_unnamed() async {
    await resolveTestCode('''
f() => <Object>[C()];
class C {
  const C();
}
''');
    assertIsConst("C()]", false);
  }

  test_isConst_notInContext_constructor_const_nonGeneric_unnamed_prefixed() async {
    newFile('$testPackageLibPath/c.dart', content: '''
class C {
  const C();
}
''');
    await resolveTestCode('''
import 'c.dart' as p;
f() => <Object>[p.C()];
''');
    assertIsConst("C()", false);
  }

  test_isConst_notInContext_constructor_nonConst() async {
    await resolveTestCode('''
f() => <Object>[C()];
class C {
  C();
}
''');
    assertIsConst("C()]", false);
  }
}

@reflectiveTest
class IntegerLiteralImplTest {
  test_isValidAsDouble_dec_1024Bits() {
    expect(
        IntegerLiteralImpl.isValidAsDouble(
            '179769313486231570814527423731704356798070567525844996598917476803'
            '157260780028538760589558632766878171540458953514382464234321326889'
            '464182768467546703537516986049910576551282076245490090389328944075'
            '868508455133942304583236903222948165808559332123348274797826204144'
            '723168738177180919299881250404026184124858369'),
        false);
  }

  test_isValidAsDouble_dec_11ExponentBits() {
    expect(
        IntegerLiteralImpl.isValidAsDouble(
            '359538626972463141629054847463408713596141135051689993197834953606'
            '314521560057077521179117265533756343080917907028764928468642653778'
            '928365536935093407075033972099821153102564152490980180778657888151'
            '737016910267884609166473806445896331617118664246696549595652408289'
            '446337476354361838599762500808052368249716736'),
        false);
  }

  test_isValidAsDouble_dec_16CharValue() {
    // 16 characters is used as a cutoff point for optimization
    expect(IntegerLiteralImpl.isValidAsDouble('9007199254740991'), true);
  }

  test_isValidAsDouble_dec_53BitsMax() {
    expect(
        IntegerLiteralImpl.isValidAsDouble(
            '179769313486231570814527423731704356798070567525844996598917476803'
            '157260780028538760589558632766878171540458953514382464234321326889'
            '464182768467546703537516986049910576551282076245490090389328944075'
            '868508455133942304583236903222948165808559332123348274797826204144'
            '723168738177180919299881250404026184124858368'),
        true);
  }

  test_isValidAsDouble_dec_54BitsMax() {
    expect(IntegerLiteralImpl.isValidAsDouble('18014398509481983'), false);
  }

  test_isValidAsDouble_dec_54BitsMin() {
    expect(IntegerLiteralImpl.isValidAsDouble('9007199254740993'), false);
  }

  test_isValidAsDouble_dec_fewDigits() {
    expect(IntegerLiteralImpl.isValidAsDouble('45'), true);
  }

  test_isValidAsDouble_dec_largest15CharValue() {
    // 16 characters is used as a cutoff point for optimization
    expect(IntegerLiteralImpl.isValidAsDouble('999999999999999'), true);
  }

  test_isValidAsDouble_hex_1024Bits() {
    expect(
        IntegerLiteralImpl.isValidAsDouble(
            '0xFFFFFFFFFFFFF800000000000000000000000000000000000000000000000000'
            '000000000000000000000000000000000000000000000000000000000000000000'
            '000000000000000000000000000000000000000000000000000000000000000000'
            '000000000000000000000000000000000000000000000000000000000001'),
        false);
  }

  test_isValidAsDouble_hex_11ExponentBits() {
    expect(
        IntegerLiteralImpl.isValidAsDouble(
            '0x1FFFFFFFFFFFFF00000000000000000000000000000000000000000000000000'
            '000000000000000000000000000000000000000000000000000000000000000000'
            '000000000000000000000000000000000000000000000000000000000000000000'
            '0000000000000000000000000000000000000000000000000000000000000'),
        false);
  }

  test_isValidAsDouble_hex_16CharValue() {
    // 16 characters is used as a cutoff point for optimization
    expect(IntegerLiteralImpl.isValidAsDouble('0x0FFFFFFFFFFFFF'), true);
  }

  test_isValidAsDouble_hex_53BitsMax() {
    expect(
        IntegerLiteralImpl.isValidAsDouble(
            '0xFFFFFFFFFFFFF800000000000000000000000000000000000000000000000000'
            '000000000000000000000000000000000000000000000000000000000000000000'
            '000000000000000000000000000000000000000000000000000000000000000000'
            '000000000000000000000000000000000000000000000000000000000000'),
        true);
  }

  test_isValidAsDouble_hex_54BitsMax() {
    expect(IntegerLiteralImpl.isValidAsDouble('0x3FFFFFFFFFFFFF'), false);
  }

  test_isValidAsDouble_hex_54BitsMin() {
    expect(IntegerLiteralImpl.isValidAsDouble('0x20000000000001'), false);
  }

  test_isValidAsDouble_hex_fewDigits() {
    expect(IntegerLiteralImpl.isValidAsDouble('0x45'), true);
  }

  test_isValidAsDouble_hex_largest15CharValue() {
    // 16 characters is used as a cutoff point for optimization
    expect(IntegerLiteralImpl.isValidAsDouble('0xFFFFFFFFFFFFF'), true);
  }

  test_isValidAsInteger_dec_negative_equalMax() {
    expect(
        IntegerLiteralImpl.isValidAsInteger('9223372036854775808', true), true);
  }

  test_isValidAsInteger_dec_negative_fewDigits() {
    expect(IntegerLiteralImpl.isValidAsInteger('24', true), true);
  }

  test_isValidAsInteger_dec_negative_leadingZeros_overMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('009923372036854775807', true),
        false);
  }

  test_isValidAsInteger_dec_negative_leadingZeros_underMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('004223372036854775807', true),
        true);
  }

  test_isValidAsInteger_dec_negative_oneOverMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('9223372036854775809', true),
        false);
  }

  test_isValidAsInteger_dec_negative_tooManyDigits() {
    expect(IntegerLiteralImpl.isValidAsInteger('10223372036854775808', true),
        false);
  }

  test_isValidAsInteger_dec_positive_equalMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('9223372036854775807', false),
        true);
  }

  test_isValidAsInteger_dec_positive_fewDigits() {
    expect(IntegerLiteralImpl.isValidAsInteger('42', false), true);
  }

  test_isValidAsInteger_dec_positive_leadingZeros_overMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('009923372036854775807', false),
        false);
  }

  test_isValidAsInteger_dec_positive_leadingZeros_underMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('004223372036854775807', false),
        true);
  }

  test_isValidAsInteger_dec_positive_oneOverMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('9223372036854775808', false),
        false);
  }

  test_isValidAsInteger_dec_positive_tooManyDigits() {
    expect(IntegerLiteralImpl.isValidAsInteger('10223372036854775808', false),
        false);
  }

  test_isValidAsInteger_hex_negative_equalMax() {
    expect(
        IntegerLiteralImpl.isValidAsInteger('0x8000000000000000', true), true);
  }

  test_isValidAsInteger_heX_negative_equalMax() {
    expect(
        IntegerLiteralImpl.isValidAsInteger('0X8000000000000000', true), true);
  }

  test_isValidAsInteger_hex_negative_fewDigits() {
    expect(IntegerLiteralImpl.isValidAsInteger('0xFF', true), true);
  }

  test_isValidAsInteger_heX_negative_fewDigits() {
    expect(IntegerLiteralImpl.isValidAsInteger('0XFF', true), true);
  }

  test_isValidAsInteger_heX_negative_leadingZeros_overMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('0X00FFFFFFFFFFFFFFFFF', true),
        false);
  }

  test_isValidAsInteger_hex_negative_leadingZeros_overMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('0x00FFFFFFFFFFFFFFFFF', true),
        false);
  }

  test_isValidAsInteger_hex_negative_leadingZeros_underMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('0x007FFFFFFFFFFFFFFF', true),
        true);
  }

  test_isValidAsInteger_heX_negative_leadingZeros_underMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('0X007FFFFFFFFFFFFFFF', true),
        true);
  }

  test_isValidAsInteger_hex_negative_oneBelowMax() {
    expect(
        IntegerLiteralImpl.isValidAsInteger('0x7FFFFFFFFFFFFFFF', true), true);
  }

  test_isValidAsInteger_heX_negative_oneBelowMax() {
    expect(
        IntegerLiteralImpl.isValidAsInteger('0X7FFFFFFFFFFFFFFF', true), true);
  }

  test_isValidAsInteger_hex_negative_oneOverMax() {
    expect(
        IntegerLiteralImpl.isValidAsInteger('0x8000000000000001', true), false);
  }

  test_isValidAsInteger_heX_negative_oneOverMax() {
    expect(
        IntegerLiteralImpl.isValidAsInteger('0X8000000000000001', true), false);
  }

  test_isValidAsInteger_hex_negative_tooManyDigits() {
    expect(IntegerLiteralImpl.isValidAsInteger('0x10000000000000000', true),
        false);
  }

  test_isValidAsInteger_heX_negative_tooManyDigits() {
    expect(IntegerLiteralImpl.isValidAsInteger('0X10000000000000000', true),
        false);
  }

  test_isValidAsInteger_heX_positive_equalMax() {
    expect(
        IntegerLiteralImpl.isValidAsInteger('0X7FFFFFFFFFFFFFFF', false), true);
  }

  test_isValidAsInteger_hex_positive_equalMax() {
    expect(
        IntegerLiteralImpl.isValidAsInteger('0x7FFFFFFFFFFFFFFF', false), true);
  }

  test_isValidAsInteger_heX_positive_fewDigits() {
    expect(IntegerLiteralImpl.isValidAsInteger('0XFF', false), true);
  }

  test_isValidAsInteger_hex_positive_fewDigits() {
    expect(IntegerLiteralImpl.isValidAsInteger('0xFF', false), true);
  }

  test_isValidAsInteger_heX_positive_leadingZeros_overMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('0X00FFFFFFFFFFFFFFFFF', false),
        false);
  }

  test_isValidAsInteger_hex_positive_leadingZeros_overMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('0x00FFFFFFFFFFFFFFFFF', false),
        false);
  }

  test_isValidAsInteger_heX_positive_leadingZeros_underMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('0X007FFFFFFFFFFFFFFF', false),
        true);
  }

  test_isValidAsInteger_hex_positive_leadingZeros_underMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('0x007FFFFFFFFFFFFFFF', false),
        true);
  }

  test_isValidAsInteger_heX_positive_oneOverMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('0X10000000000000000', false),
        false);
  }

  test_isValidAsInteger_hex_positive_oneOverMax() {
    expect(IntegerLiteralImpl.isValidAsInteger('0x10000000000000000', false),
        false);
  }

  test_isValidAsInteger_hex_positive_tooManyDigits() {
    expect(IntegerLiteralImpl.isValidAsInteger('0xFF0000000000000000', false),
        false);
  }

  test_isValidAsInteger_heX_positive_tooManyDigits() {
    expect(IntegerLiteralImpl.isValidAsInteger('0XFF0000000000000000', false),
        false);
  }
}
