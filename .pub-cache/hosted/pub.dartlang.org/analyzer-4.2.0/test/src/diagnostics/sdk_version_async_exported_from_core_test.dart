// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import 'sdk_constraint_verifier_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionAsyncExportedFromCoreTest);
  });
}

@reflectiveTest
class SdkVersionAsyncExportedFromCoreTest extends SdkConstraintVerifierTest {
  test_equals_explicitImportOfAsync() async {
    await verifyVersion('2.1.0', '''
import 'dart:async';

Future<int> zero() async => 0;
''');
  }

  test_equals_explicitImportOfCore() async {
    await verifyVersion('2.1.0', '''
import 'dart:core';

Future<int> zero() async => 0;
''');
  }

  test_equals_explicitImportOfExportingLibrary() async {
    newFile('$testPackageLibPath/exporter.dart', '''
export 'dart:async';
''');
    await verifyVersion('2.1.0', '''
import 'exporter.dart';

Future<int> zero() async => 0;
''');
  }

  test_equals_implicitImportOfCore() async {
    await verifyVersion('2.1.0', '''
Future<int> zero() async => 0;
''');
  }

  test_equals_implicitImportOfCore_inPart() async {
    writeTestPackagePubspecYamlFile(
      PubspecYamlFileConfig(
        sdkVersion: '>=2.1.0',
      ),
    );

    final lib = newFile('$testPackageLibPath/lib.dart', '''
library lib;

part 'a.dart';
''');

    final a = newFile('$testPackageLibPath/a.dart', r'''
part of lib;

Future<int> zero() async => 0;
''');

    final analysisSession = contextFor(lib.path).currentSession;
    final resolvedLibrary = await analysisSession.getResolvedLibrary(lib.path);
    resolvedLibrary as ResolvedLibraryResult;

    final resolvedPart = resolvedLibrary.units.last;
    expect(resolvedPart.path, a.path);
    assertErrorsInList(resolvedPart.errors, []);
  }

  test_lessThan_explicitImportOfAsync() async {
    await verifyVersion('2.0.0', '''
import 'dart:async';

Future<int> zero() async => 0;
''');
  }

  test_lessThan_explicitImportOfCore() async {
    await verifyVersion('2.0.0', '''
import 'dart:core' show Future, int;

Future<int> zero() async => 0;
''', expectedErrors: [
      error(HintCode.SDK_VERSION_ASYNC_EXPORTED_FROM_CORE, 38, 6),
    ]);
  }

  test_lessThan_explicitImportOfExportingLibrary() async {
    newFile('$testPackageLibPath/exporter.dart', '''
export 'dart:async';
''');
    await verifyVersion('2.0.0', '''
import 'exporter.dart';

Future<int> zero() async => 0;
''');
  }

  test_lessThan_implicitImportOfCore() async {
    await verifyVersion('2.0.0', '''
Future<int> zero() async => 0;
''', expectedErrors: [
      error(HintCode.SDK_VERSION_ASYNC_EXPORTED_FROM_CORE, 0, 6),
    ]);
  }

  test_lessThan_implicitImportOfCore_inPart() async {
    writeTestPackagePubspecYamlFile(
      PubspecYamlFileConfig(
        sdkVersion: '>=2.0.0',
      ),
    );

    final lib = newFile('$testPackageLibPath/lib.dart', '''
library lib;

part 'a.dart';
''');

    final a = newFile('$testPackageLibPath/a.dart', r'''
part of lib;

Future<int> zero() async => 0;
''');

    final analysisSession = contextFor(lib.path).currentSession;
    final resolvedLibrary = await analysisSession.getResolvedLibrary(lib.path);
    resolvedLibrary as ResolvedLibraryResult;

    final resolvedPart = resolvedLibrary.units.last;
    expect(resolvedPart.path, a.path);
    assertErrorsInList(resolvedPart.errors, [
      error(HintCode.SDK_VERSION_ASYNC_EXPORTED_FROM_CORE, 14, 6),
    ]);
  }

  test_lessThan_onlyReferencedInExport_hide() async {
    await verifyVersion('2.0.0', '''
export 'dart:async' hide Future;
''');
  }

  test_lessThan_onlyReferencedInExport_show() async {
    await verifyVersion('2.0.0', '''
export 'dart:async' show Future;
''');
  }

  test_lessThan_onlyReferencedInImport_hide() async {
    await verifyVersion('2.0.0', '''
import 'dart:core' hide Future;
''');
  }

  test_lessThan_onlyReferencedInImport_show() async {
    await verifyVersion('2.0.0', '''
import 'dart:core' show Future;
''');
  }
}
