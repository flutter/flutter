// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/defined_names.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefinedNamesTest);
  });
}

@reflectiveTest
class DefinedNamesTest extends ParserTestCase {
  test_classMemberNames_class() {
    DefinedNames names = _computeDefinedNames('''
class A {
  int a, b;
  A();
  A.c();
  d() {}
  get e => null;
  set f(_) {}
}
class B {
  g() {}
}
''');
    expect(names.topLevelNames, unorderedEquals(['A', 'B']));
    expect(names.classMemberNames,
        unorderedEquals(['a', 'b', 'd', 'e', 'f', 'g']));
  }

  test_classMemberNames_mixin() {
    DefinedNames names = _computeDefinedNames('''
mixin A {
  int a, b;
  A();
  A.c();
  d() {}
  get e => null;
  set f(_) {}
}
mixin B {
  g() {}
}
''');
    expect(names.topLevelNames, unorderedEquals(['A', 'B']));
    expect(names.classMemberNames,
        unorderedEquals(['a', 'b', 'd', 'e', 'f', 'g']));
  }

  test_topLevelNames() {
    DefinedNames names = _computeDefinedNames('''
class A {}
class B = Object with A;
typedef C {}
D() {}
get E => null;
set F(_) {}
var G, H;
mixin M {}
''');
    expect(names.topLevelNames,
        unorderedEquals(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'M']));
    expect(names.classMemberNames, isEmpty);
  }

  DefinedNames _computeDefinedNames(String code) {
    CompilationUnit unit = parseCompilationUnit2(code);
    return computeDefinedNames(unit);
  }
}
