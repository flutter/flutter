// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionalConstDriverResolutionTest);
  });
}

@reflectiveTest
class OptionalConstDriverResolutionTest extends PubPackageResolutionTest {
  Map<String, LibraryElement> libraries = {};

  LibraryElement get libraryA => libraries['package:test/a.dart']!;

  test_instantiateToBounds_notPrefixed_named() async {
    var creation = await _resolveImplicitConst('B.named()');
    assertInstanceCreation(
      creation,
      libraryA.getType('B')!,
      'B<num>',
      constructorName: 'named',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'num'},
    );
  }

  test_instantiateToBounds_notPrefixed_unnamed() async {
    var creation = await _resolveImplicitConst('B()');
    assertInstanceCreation(
      creation,
      libraryA.getType('B')!,
      'B<num>',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'num'},
    );
  }

  test_instantiateToBounds_prefixed_named() async {
    var creation = await _resolveImplicitConst('p.B.named()', prefix: 'p');
    assertInstanceCreation(
      creation,
      libraryA.getType('B')!,
      'B<num>',
      constructorName: 'named',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'num'},
      expectedPrefix: _importOfA().prefix,
    );
  }

  test_instantiateToBounds_prefixed_unnamed() async {
    var creation = await _resolveImplicitConst('p.B()', prefix: 'p');
    assertInstanceCreation(
      creation,
      libraryA.getType('B')!,
      'B<num>',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'num'},
      expectedPrefix: _importOfA().prefix,
    );
  }

  test_notPrefixed_named() async {
    var creation = await _resolveImplicitConst('A.named()');
    assertInstanceCreation(
      creation,
      libraryA.getType('A')!,
      'A',
      constructorName: 'named',
    );
  }

  test_notPrefixed_unnamed() async {
    var creation = await _resolveImplicitConst('A()');
    assertInstanceCreation(
      creation,
      libraryA.getType('A')!,
      'A',
    );
  }

  test_prefixed_named() async {
    var creation = await _resolveImplicitConst('p.A.named()', prefix: 'p');
    // Note, that we don't resynthesize the import prefix.
    assertInstanceCreation(
      creation,
      libraryA.getType('A')!,
      'A',
      constructorName: 'named',
      expectedPrefix: _importOfA().prefix,
    );
  }

  test_prefixed_unnamed() async {
    var creation = await _resolveImplicitConst('p.A()', prefix: 'p');
    // Note, that we don't resynthesize the import prefix.
    assertInstanceCreation(
      creation,
      libraryA.getType('A')!,
      'A',
      expectedPrefix: _importOfA().prefix,
    );
  }

  test_prefixed_unnamed_generic() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class C<T> {
  const C();
}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as p;

const x = p.C<int>();
''');
    _fillLibraries();

    var element_C = libraryA.getType('C');
    var element_p = findElement.prefix('p');

    var creation = findNode.instanceCreation('p.C<int>()');
    assertType(creation, 'C<int>');

    var constructorName = creation.constructorName;

    var typeName = constructorName.type2;
    assertType(typeName, 'C<int>');

    var pC = typeName.name as PrefixedIdentifier;
    assertElement(pC, element_C);
    // TODO(scheglov) enforce
//    assertTypeNull(pC);

    var ref_p = pC.prefix;
    assertElement(ref_p, element_p);
    assertTypeNull(ref_p);

    var ref_C = pC.identifier;
    assertElement(ref_C, element_C);
    assertTypeNull(ref_C);

    assertType(typeName.typeArguments!.arguments[0], 'int');
  }

  void _fillLibraries([LibraryElement? library]) {
    library ??= result.unit.declaredElement!.library;
    var uriStr = library.source.uri.toString();
    if (!libraries.containsKey(uriStr)) {
      libraries[uriStr] = library;
      library.importedLibraries.forEach(_fillLibraries);
    }
  }

  ImportElement _importOfA() {
    var importOfB = findElement.import('package:test/b.dart');
    return importOfB.importedLibrary!.imports[0];
  }

  Future<InstanceCreationExpression> _resolveImplicitConst(String expr,
      {String? prefix}) async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  const A();
  const A.named();
}
class B<T extends num> {
  const B();
  const B.named();
}
''');

    if (prefix != null) {
      newFile('$testPackageLibPath/b.dart', content: '''
import 'a.dart' as $prefix;
const a = $expr;
''');
    } else {
      newFile('$testPackageLibPath/b.dart', content: '''
import 'a.dart';
const a = $expr;
''');
    }

    await resolveTestCode(r'''
import 'b.dart';
var v = a;
''');
    _fillLibraries();

    var vg = findNode.simple('a;').staticElement as PropertyAccessorElement;
    var v = vg.variable as ConstVariableElement;

    var creation = v.constantInitializer as InstanceCreationExpression;
    return creation;
  }
}
