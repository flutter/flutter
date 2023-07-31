// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/factory_type_test_helper.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:test/test.dart' as test;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../../../generated/test_analysis_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FactorTypeTest);
  });
}

@reflectiveTest
class FactorTypeTest with FactorTypeTestMixin<DartType>, ElementsTypesMixin {
  @override
  late final TypeProvider typeProvider;

  late final TypeSystemImpl typeSystem;

  @override
  DartType get voidType => typeProvider.voidType;

  @override
  void expect(
      DartType T, DartType S, String actualResult, String expectedResult) {
    test.expect(actualResult, expectedResult);
  }

  @override
  DartType factor(DartType T, DartType S) {
    return typeSystem.factor(T, S);
  }

  void setUp() {
    var analysisContext = TestAnalysisContext();
    typeProvider = analysisContext.typeProviderNonNullableByDefault;
    typeSystem = analysisContext.typeSystemNonNullableByDefault;
  }

  @override
  String typeString(covariant TypeImpl type) {
    return type.getDisplayString(withNullability: true);
  }
}
