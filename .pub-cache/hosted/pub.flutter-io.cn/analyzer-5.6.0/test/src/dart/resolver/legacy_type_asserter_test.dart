// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/legacy_type_asserter.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LegacyTypeAsserterTest);
  });
}

@reflectiveTest
class LegacyTypeAsserterTest extends PubPackageResolutionTest {
  InterfaceType get _intNone {
    return typeProvider.intElement.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType get _intQuestion {
    return typeProvider.intElement.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType get _intStar {
    return typeProvider.intElement.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  test_nullableUnit_expressionStaticType_bottom() async {
    await _buildUnit(() => NeverTypeImpl.instance);
    expect(() {
      LegacyTypeAsserter.assertLegacyTypes(result.unit);
    }, throwsStateError);
  }

  test_nullableUnit_expressionStaticType_bottomQuestion() async {
    await _buildUnit(() => NeverTypeImpl.instanceNullable);
    LegacyTypeAsserter.assertLegacyTypes(result.unit);
  }

  test_nullableUnit_expressionStaticType_dynamic() async {
    await _buildUnit(() => typeProvider.dynamicType);
    LegacyTypeAsserter.assertLegacyTypes(result.unit);
  }

  test_nullableUnit_expressionStaticType_nonNull() async {
    await _buildUnit(() => _intNone);
    expect(() {
      LegacyTypeAsserter.assertLegacyTypes(result.unit);
    }, throwsStateError);
  }

  test_nullableUnit_expressionStaticType_nonNullTypeArgument() async {
    await _buildUnit(
      () => typeProvider.listElement.instantiate(
        typeArguments: [_intNone],
        nullabilitySuffix: NullabilitySuffix.star,
      ),
    );
    expect(() {
      LegacyTypeAsserter.assertLegacyTypes(result.unit);
    }, throwsStateError);
  }

  test_nullableUnit_expressionStaticType_nonNullTypeParameter() async {
    await _buildUnit(
      () => typeProvider.listElement.instantiate(
        typeArguments: [
          findElement.typeParameter('T').instantiate(
                nullabilitySuffix: NullabilitySuffix.none,
              ),
        ],
        nullabilitySuffix: NullabilitySuffix.star,
      ),
    );
    expect(() {
      LegacyTypeAsserter.assertLegacyTypes(result.unit);
    }, throwsStateError);
  }

  test_nullableUnit_expressionStaticType_null() async {
    await _buildUnit(
      () => typeProvider.nullElement.instantiate(
        typeArguments: [],
        nullabilitySuffix: NullabilitySuffix.star,
      ),
    );
    LegacyTypeAsserter.assertLegacyTypes(result.unit);
  }

  test_nullableUnit_expressionStaticType_question() async {
    await _buildUnit(() => _intQuestion);
    expect(() {
      LegacyTypeAsserter.assertLegacyTypes(result.unit);
    }, throwsStateError);
  }

  test_nullableUnit_expressionStaticType_star() async {
    await _buildUnit(() => _intStar);
    LegacyTypeAsserter.assertLegacyTypes(result.unit);
  }

  test_nullableUnit_expressionStaticType_void() async {
    await _buildUnit(() => typeProvider.voidType);
    LegacyTypeAsserter.assertLegacyTypes(result.unit);
  }

  Future<void> _buildUnit(DartType Function() getType) async {
    await resolveTestCode(r'''
// @dart = 2.9
void f<T>(Object? foo) {
  foo;
}
''');

    final foo = findNode.simple('foo;');
    foo as SimpleIdentifierImpl;
    foo.staticType = getType();
  }
}
