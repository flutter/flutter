// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixElementTest);
  });
}

@reflectiveTest
class PrefixElementTest extends PubPackageResolutionTest {
  test_scope_lookup() async {
    newFile('$testPackageLibPath/a.dart', r'''
var foo = 0;
''');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'a.dart' as prefix;
''');

    var scope = findElement.prefix('prefix').scope;
    var importFind = findElement.importFind('package:test/a.dart');

    assertElement(
      scope.lookup('foo').getter,
      importFind.topGet('foo'),
    );

    assertElement(
      scope.lookup('foo').setter,
      importFind.topSet('foo'),
    );
  }

  test_scope_lookup_ambiguous_notSdk_both() async {
    newFile('$testPackageLibPath/a.dart', r'''
var foo = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
var foo = 1.2;
''');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'a.dart' as prefix;

// ignore:unused_import
import 'b.dart' as prefix;
''');

    var scope = findElement.prefix('prefix').scope;

    var aImport = findElement.importFind('package:test/a.dart');
    var bImport = findElement.importFind('package:test/b.dart');

    expect(
      scope.lookup('foo').getter,
      multiplyDefinedElementMatcher([
        aImport.topGet('foo'),
        bImport.topGet('foo'),
      ]),
    );

    expect(
      scope.lookup('foo').setter,
      multiplyDefinedElementMatcher([
        aImport.topSet('foo'),
        bImport.topSet('foo'),
      ]),
    );
  }

  test_scope_lookup_ambiguous_notSdk_first() async {
    newFile('$testPackageLibPath/a.dart', r'''
var pi = 4;
''');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'a.dart' as prefix;

// ignore:unused_import
import 'dart:math' as prefix;
''');

    var scope = findElement.prefix('prefix').scope;
    var aImport = findElement.importFind('package:test/a.dart');

    assertElement(
      scope.lookup('pi').getter,
      aImport.topGet('pi'),
    );
  }

  test_scope_lookup_ambiguous_notSdk_second() async {
    newFile('$testPackageLibPath/a.dart', r'''
var pi = 4;
''');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as prefix;

// ignore:unused_import
import 'a.dart' as prefix;
''');

    var scope = findElement.prefix('prefix').scope;
    var aImport = findElement.importFind('package:test/a.dart');

    assertElement(
      scope.lookup('pi').getter,
      aImport.topGet('pi'),
    );
  }

  test_scope_lookup_ambiguous_same() async {
    newFile('$testPackageLibPath/a.dart', r'''
var foo = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'a.dart' as prefix;

// ignore:unused_import
import 'b.dart' as prefix;
''');

    var scope = findElement.prefix('prefix').scope;
    var importFind = findElement.importFind('package:test/a.dart');

    assertElement(
      scope.lookup('foo').getter,
      importFind.topGet('foo'),
    );

    assertElement(
      scope.lookup('foo').setter,
      importFind.topSet('foo'),
    );
  }

  test_scope_lookup_differentPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
var foo = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
var bar = 0;
''');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'a.dart' as prefix;

// ignore:unused_import
import 'b.dart' as prefix2;
''');

    var scope = findElement.prefix('prefix').scope;
    var importFind = findElement.importFind('package:test/a.dart');

    assertElement(
      scope.lookup('foo').getter,
      importFind.topGet('foo'),
    );
    assertElement(
      scope.lookup('foo').setter,
      importFind.topSet('foo'),
    );

    assertElementNull(
      scope.lookup('bar').getter,
    );
    assertElementNull(
      scope.lookup('bar').setter,
    );
  }

  test_scope_lookup_notFound() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as math;
''');

    var scope = findElement.prefix('math').scope;

    assertElementNull(
      scope.lookup('noSuchGetter').getter,
    );

    assertElementNull(
      scope.lookup('noSuchSetter').setter,
    );
  }

  test_scope_lookup_respectsCombinator_hide() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as math hide sin;
''');

    var scope = findElement.prefix('math').scope;
    var mathFind = findElement.importFind('dart:math');

    assertElementNull(
      scope.lookup('sin').getter,
    );

    assertElement(
      scope.lookup('cos').getter,
      mathFind.topFunction('cos'),
    );
    assertElement(
      scope.lookup('tan').getter,
      mathFind.topFunction('tan'),
    );
  }

  test_scope_lookup_respectsCombinator_show() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as math show sin;
''');

    var scope = findElement.prefix('math').scope;
    var mathFind = findElement.importFind('dart:math');

    assertElement(
      scope.lookup('sin').getter,
      mathFind.topFunction('sin'),
    );

    assertElementNull(
      scope.lookup('cos').getter,
    );
  }
}
