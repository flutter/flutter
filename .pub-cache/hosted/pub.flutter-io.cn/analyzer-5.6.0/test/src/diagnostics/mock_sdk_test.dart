// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MockSdkTest);
  });
}

@reflectiveTest
class MockSdkTest extends PubPackageResolutionTest {
  test_dart_async() async {
    await _assertOnlyHintsInLibraryUri('dart:async');
  }

  test_dart_convert() async {
    await _assertOnlyHintsInLibraryUri('dart:convert');
  }

  test_dart_core() async {
    await _assertOnlyHintsInLibraryUri('dart:core');
  }

  test_dart_math() async {
    await _assertOnlyHintsInLibraryUri('dart:math');
  }

  void _assertOnlyHintsInLibrary(ResolvedLibraryResult coreResolvedResult) {
    for (var resolvedUnit in coreResolvedResult.units) {
      _assertOnlyHintsInUnit(resolvedUnit);
    }
  }

  Future<void> _assertOnlyHintsInLibraryUri(String uriStr) async {
    var coreResolvedResult = await _resolvedLibraryByUri(uriStr);
    _assertOnlyHintsInLibrary(coreResolvedResult);
  }

  void _assertOnlyHintsInUnit(ResolvedUnitResult resolvedUnit) {
    var notHints = resolvedUnit.errors
        .where((element) => element.errorCode.type != ErrorType.HINT)
        .toList();
    assertErrorsInList(notHints, []);
  }

  Future<ResolvedLibraryResult> _resolvedLibraryByUri(String uriStr) async {
    var analysisSession = contextFor(testFile).currentSession;
    var coreElementResult =
        await analysisSession.getLibraryByUri(uriStr) as LibraryElementResult;
    return await analysisSession.getResolvedLibraryByElement(
        coreElementResult.element) as ResolvedLibraryResult;
  }
}
