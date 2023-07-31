// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';

import 'elements_types_mixin.dart';
import 'test_analysis_context.dart';

abstract class AbstractTypeSystemTest with ElementsTypesMixin {
  late TestAnalysisContext analysisContext;

  @override
  late LibraryElementImpl testLibrary;

  @override
  late TypeProviderImpl typeProvider;

  late TypeSystemImpl typeSystem;

  void setUp() {
    analysisContext = TestAnalysisContext();
    typeProvider = analysisContext.typeProviderNonNullableByDefault;
    typeSystem = analysisContext.typeSystemNonNullableByDefault;

    testLibrary = library_(
      uriStr: 'package:test/test.dart',
      analysisContext: analysisContext,
      analysisSession: analysisContext.analysisSession,
      typeSystem: typeSystem,
    );
  }
}

abstract class AbstractTypeSystemWithoutNullSafetyTest with ElementsTypesMixin {
  late TestAnalysisContext analysisContext;

  @override
  late LibraryElementImpl testLibrary;

  @override
  late TypeProvider typeProvider;

  late TypeSystemImpl typeSystem;

  void setUp() {
    analysisContext = TestAnalysisContext();
    typeProvider = analysisContext.typeProviderLegacy;
    typeSystem = analysisContext.typeSystemLegacy;

    testLibrary = library_(
      uriStr: 'package:test/test.dart',
      analysisContext: analysisContext,
      analysisSession: analysisContext.analysisSession,
      typeSystem: typeSystem,
    );
  }
}
