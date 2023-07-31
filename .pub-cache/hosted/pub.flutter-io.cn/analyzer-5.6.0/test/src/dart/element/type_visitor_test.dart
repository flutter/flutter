// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';
import 'string_types.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveTypeVisitorTest);
  });
}

@reflectiveTest
class RecursiveTypeVisitorTest extends AbstractTypeSystemTest with StringTypes {
  late final _MockRecursiveVisitor visitor;

  @override
  void setUp() {
    super.setUp();
    visitor = _MockRecursiveVisitor();
    defineStringTypes();
  }

  void test_callsDefaultBehavior() {
    expect(intNone.accept(visitor), true);
    visitor.assertVisitedType(intNone);
  }

  void test_functionType_complex() {
    final T = typeParameter('T', bound: intNone);
    final K = typeParameter('K', bound: stringNone);
    final a = positionalParameter(type: numNone);
    final b = positionalParameter(type: doubleNone);
    final c = namedParameter(name: 'c', type: voidNone);
    final d = namedParameter(name: 'd', type: objectNone);
    final type = functionType(
        returnType: dynamicType,
        typeFormals: [T, K],
        parameters: [a, b, c, d],
        nullabilitySuffix: NullabilitySuffix.none);
    expect(type.accept(visitor), true);
    visitor.assertVisitedTypes([
      dynamicType,
      intNone,
      stringNone,
      numNone,
      doubleNone,
      voidNone,
      objectNone
    ]);
  }

  void test_functionType_positionalParameter() {
    final a = positionalParameter(type: intNone);
    final type = functionType(
        returnType: dynamicType,
        typeFormals: [],
        parameters: [a],
        nullabilitySuffix: NullabilitySuffix.none);
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(intNone);
  }

  void test_functionType_returnType() {
    final type = functionType(
        returnType: intNone,
        typeFormals: [],
        parameters: [],
        nullabilitySuffix: NullabilitySuffix.none);
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(intNone);
  }

  void test_functionType_typeFormal_bound() {
    final T = typeParameter('T', bound: intNone);
    final type = functionType(
        returnType: dynamicType,
        typeFormals: [T],
        parameters: [],
        nullabilitySuffix: NullabilitySuffix.none);
    expect(type.accept(visitor), true);
    visitor.assertVisitedTypes([dynamicType, intNone]);
  }

  void test_functionType_typeFormal_noBound() {
    final T = typeParameter('T');
    final type = functionType(
        returnType: dynamicType,
        typeFormals: [T],
        parameters: [],
        nullabilitySuffix: NullabilitySuffix.none);
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(dynamicType);
  }

  void test_interfaceType_typeParameter() {
    final type = typeProvider.listType(intNone);
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(intNone);
  }

  void test_interfaceType_typeParameters() {
    final type = typeProvider.mapType(intNone, stringNone);
    expect(type.accept(visitor), true);
    visitor.assertVisitedTypes([intNone, stringNone]);
  }

  void test_interfaceType_typeParameters_nested() {
    final innerList = typeProvider.listType(intNone);
    final outerList = typeProvider.listType(innerList);
    expect(outerList.accept(visitor), true);
    visitor.assertVisitedType(intNone);
  }

  void test_recordType_named() {
    final type = typeOfString('({int f1, double f2})');
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(intNone);
    visitor.assertVisitedType(doubleNone);
  }

  void test_recordType_positional() {
    final type = typeOfString('(int, double)');
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(intNone);
    visitor.assertVisitedType(doubleNone);
  }

  void test_stopVisiting_first() {
    final T = typeParameter('T', bound: intNone);
    final K = typeParameter('K', bound: stringNone);
    final a = positionalParameter(type: numNone);
    final b = positionalParameter(type: doubleNone);
    final c = namedParameter(name: 'c', type: voidNone);
    final d = namedParameter(name: 'd', type: objectNone);
    final type = functionType(
        returnType: dynamicType,
        typeFormals: [T, K],
        parameters: [a, b, c, d],
        nullabilitySuffix: NullabilitySuffix.none);
    visitor.stopOnType = dynamicType;
    expect(type.accept(visitor), false);
    visitor.assertNotVisitedTypes(
        [intNone, stringNone, numNone, doubleNone, voidNone, objectNone]);
  }

  void test_stopVisiting_halfway() {
    final T = typeParameter('T', bound: intNone);
    final K = typeParameter('K', bound: stringNone);
    final a = positionalParameter(type: numNone);
    final b = positionalParameter(type: doubleNone);
    final c = namedParameter(name: 'c', type: voidNone);
    final d = namedParameter(name: 'd', type: objectNone);
    final type = functionType(
        returnType: dynamicType,
        typeFormals: [T, K],
        parameters: [a, b, c, d],
        nullabilitySuffix: NullabilitySuffix.none);
    visitor.stopOnType = intNone;
    expect(type.accept(visitor), false);
    visitor.assertNotVisitedTypes([stringNone, voidNone, objectNone]);
  }

  void test_stopVisiting_nested() {
    final innerType = typeProvider.mapType(intNone, stringNone);
    final outerList = typeProvider.listType(innerType);
    visitor.stopOnType = intNone;
    expect(outerList.accept(visitor), false);
    visitor.assertNotVisitedType(stringNone);
  }

  void test_stopVisiting_nested_parent() {
    final innerTypeStop = typeProvider.listType(intNone);
    final innerTypeSkipped = typeProvider.listType(stringNone);
    final outerType = typeProvider.mapType(innerTypeStop, innerTypeSkipped);
    visitor.stopOnType = intNone;
    expect(outerType.accept(visitor), false);
    visitor.assertNotVisitedType(stringNone);
  }

  void test_stopVisiting_typeParameters() {
    final type = typeProvider.mapType(intNone, stringNone);
    visitor.stopOnType = intNone;
    expect(type.accept(visitor), false);
    visitor.assertVisitedType(intNone);
    visitor.assertNotVisitedType(stringNone);
  }
}

class _MockRecursiveVisitor extends RecursiveTypeVisitor {
  final Set<DartType> visitedTypes = {};
  DartType? stopOnType;

  void assertNotVisitedType(DartType type) {
    expect(visitedTypes, isNot(contains(type)));
  }

  void assertNotVisitedTypes(Iterable<DartType> types) =>
      types.forEach(assertNotVisitedType);

  void assertVisitedType(DartType type) {
    expect(visitedTypes, contains(type));
  }

  void assertVisitedTypes(Iterable<DartType> types) =>
      types.forEach(assertVisitedType);

  @override
  bool visitDartType(DartType type) {
    expect(type, isNotNull);
    visitedTypes.add(type);
    return type != stopOnType;
  }

  @override
  bool visitInterfaceType(InterfaceType type) {
    visitedTypes.add(type);
    if (type == stopOnType) {
      return false;
    }
    return super.visitInterfaceType(type);
  }
}
