// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';
import '../util/element_type_matchers.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotationElementResolverTest);
    defineReflectiveTests(ElementResolverTest);
  });
}

@reflectiveTest
class AnnotationElementResolverTest extends PubPackageResolutionTest {
  test_class_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named();
}
''');
    await _validateAnnotation('', '@A.named()',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isClassElement);
      expect(name1.staticElement!.displayName, 'A');
      expect(name2!.staticElement, isConstructorElement);
      expect(name2.staticElement!.displayName, 'A.named');
      expect(name3, isNull);
      if (annotationElement is ConstructorElement) {
        expect(annotationElement, same(name2.staticElement));
        expect(annotationElement.enclosingElement, name1.staticElement);
        expect(annotationElement.displayName, 'A.named');
        expect(annotationElement.parameters, isEmpty);
      } else {
        fail('Expected "annotationElement" is ConstructorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_class_prefixed_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named();
}
''');
    await _validateAnnotation('as p', '@p.A.named()',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isPrefixElement);
      expect(name1.staticElement!.displayName, 'p');
      expect(name2!.staticElement, isClassElement);
      expect(name2.staticElement!.displayName, 'A');
      expect(name3!.staticElement, isConstructorElement);
      expect(name3.staticElement!.displayName, 'A.named');
      if (annotationElement is ConstructorElement) {
        expect(annotationElement, same(name3.staticElement));
        expect(annotationElement.enclosingElement, name2.staticElement);
        expect(annotationElement.displayName, 'A.named');
        expect(annotationElement.parameters, isEmpty);
      } else {
        fail('Expected "annotationElement" is ConstructorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_class_prefixed_staticConstField() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const V = 0;
}
''');
    await _validateAnnotation('as p', '@p.A.V',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isPrefixElement);
      expect(name1.staticElement!.displayName, 'p');
      expect(name2!.staticElement, isClassElement);
      expect(name2.staticElement!.displayName, 'A');
      expect(name3!.staticElement, isPropertyAccessorElement);
      expect(name3.staticElement!.displayName, 'V');
      if (annotationElement is PropertyAccessorElement) {
        expect(annotationElement, same(name3.staticElement));
        expect(annotationElement.enclosingElement, name2.staticElement);
        expect(annotationElement.displayName, 'V');
      } else {
        fail('Expected "annotationElement" is PropertyAccessorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_class_prefixed_unnamedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');
    await _validateAnnotation('as p', '@p.A',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isPrefixElement);
      expect(name1.staticElement!.displayName, 'p');
      expect(name2!.staticElement, isClassElement);
      expect(name2.staticElement!.displayName, 'A');
      expect(name3, isNull);
      if (annotationElement is ConstructorElement) {
        expect(annotationElement.enclosingElement, name2.staticElement);
        expect(annotationElement.displayName, 'A');
        expect(annotationElement.parameters, isEmpty);
      } else {
        fail('Expected "annotationElement" is ConstructorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_class_staticConstField() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const V = 0;
}
''');
    await _validateAnnotation('', '@A.V',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isClassElement);
      expect(name1.staticElement!.displayName, 'A');
      expect(name2!.staticElement, isPropertyAccessorElement);
      expect(name2.staticElement!.displayName, 'V');
      expect(name3, isNull);
      if (annotationElement is PropertyAccessorElement) {
        expect(annotationElement, same(name2.staticElement));
        expect(annotationElement.enclosingElement, name1.staticElement);
        expect(annotationElement.displayName, 'V');
      } else {
        fail('Expected "annotationElement" is PropertyAccessorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_class_unnamedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');
    await _validateAnnotation('', '@A',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isClassElement);
      expect(name1.staticElement!.displayName, 'A');
      expect(name2, isNull);
      expect(name3, isNull);
      if (annotationElement is ConstructorElement) {
        expect(annotationElement.enclosingElement, name1.staticElement);
        expect(annotationElement.displayName, 'A');
        expect(annotationElement.parameters, isEmpty);
      } else {
        fail('Expected "annotationElement" is ConstructorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_topLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
const V = 0;
''');
    await _validateAnnotation('', '@V',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isPropertyAccessorElement);
      expect(name1.staticElement!.displayName, 'V');
      expect(name2, isNull);
      expect(name3, isNull);
      if (annotationElement is PropertyAccessorElement) {
        expect(annotationElement, same(name1.staticElement));
        expect(annotationElement.enclosingElement, isCompilationUnitElement);
        expect(annotationElement.displayName, 'V');
      } else {
        fail('Expected "annotationElement" is PropertyAccessorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_topLevelVariable_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
const V = 0;
''');
    await _validateAnnotation('as p', '@p.V',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isPrefixElement);
      expect(name1.staticElement!.displayName, 'p');
      expect(name2!.staticElement, isPropertyAccessorElement);
      expect(name2.staticElement!.displayName, 'V');
      expect(name3, isNull);
      if (annotationElement is PropertyAccessorElement) {
        expect(annotationElement, same(name2.staticElement));
        expect(annotationElement.enclosingElement, isCompilationUnitElement);
        expect(annotationElement.displayName, 'V');
      } else {
        fail('Expected "annotationElement" is PropertyAccessorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  Future<void> _validateAnnotation(
      String annotationPrefix,
      String annotationText,
      Function(SimpleIdentifier? name, SimpleIdentifier? name2,
              SimpleIdentifier? name3, Element annotationElement)
          validator) async {
    await resolveTestCode('''
import 'a.dart' $annotationPrefix;
$annotationText
class C {}
''');
    var clazz = findNode.classDeclaration('C');
    Annotation annotation = clazz.metadata.single;
    Identifier name = annotation.name;
    Element annotationElement = annotation.element!;
    if (name is SimpleIdentifier) {
      validator(name, null, annotation.constructorName, annotationElement);
    } else if (name is PrefixedIdentifier) {
      validator(name.prefix, name.identifier, annotation.constructorName,
          annotationElement);
    } else {
      fail('Unknown "name": ${name.runtimeType} $name');
    }
  }
}

@reflectiveTest
class ElementResolverTest extends PubPackageResolutionTest {
  test_visitBreakStatement_withLabel() async {
    await assertNoErrorsInCode('''
test() {
  loop: while (true) {
    break loop;
  }
}
''');
    var breakStatement = findNode.breakStatement('break loop');
    expect(breakStatement.label!.staticElement, findElement.label('loop'));
    expect(breakStatement.target, findNode.whileStatement('while (true)'));
  }

  test_visitBreakStatement_withoutLabel() async {
    await assertNoErrorsInCode('''
test() {
  while (true) {
    break;
  }
}
''');
    var breakStatement = findNode.breakStatement('break');
    expect(breakStatement.target, findNode.whileStatement('while (true)'));
  }

  test_visitCommentReference_prefixedIdentifier_class_getter() async {
    await assertNoErrorsInCode('''
class A {
  int get p => 0;
  set p(int value) {}
}

/// [A.p]
test() {}
''');
    var prefixed = findNode.prefixed('A.p');
    expect(prefixed.prefix.staticElement, findElement.class_('A'));
    expect(prefixed.identifier.staticElement, findElement.getter('p'));
  }

  test_visitCommentReference_prefixedIdentifier_class_method() async {
    await assertNoErrorsInCode('''
class A {
  m() {}
}

/// [A.m]
test() {}
''');
    var prefixed = findNode.prefixed('A.m');
    expect(prefixed.prefix.staticElement, findElement.class_('A'));
    expect(prefixed.identifier.staticElement, findElement.method('m'));
  }

  test_visitCommentReference_prefixedIdentifier_class_operator() async {
    await assertNoErrorsInCode('''
class A {
  operator ==(other) => true;
}

/// [A.==]
test() {}
''');
    var prefixed = findNode.prefixed('A.==');
    expect(prefixed.prefix.staticElement, findElement.class_('A'));
    expect(prefixed.identifier.staticElement, findElement.method('=='));
  }

  test_visitConstructorName_named() async {
    await assertNoErrorsInCode('''
class A implements B {
  A.a();
}
class B {
  factory B() = A.a/*reference*/;
}
''');
    expect(findNode.constructorName('A.a/*reference*/').staticElement,
        same(findElement.constructor('a')));
  }

  test_visitConstructorName_unnamed() async {
    await assertNoErrorsInCode('''
class A implements B {
  A();
}
class B {
  factory B() = A/*reference*/;
}
''');
    expect(findNode.constructorName('A/*reference*/').staticElement,
        same(findElement.unnamedConstructor('A')));
  }

  test_visitContinueStatement_withLabel() async {
    await assertNoErrorsInCode('''
test() {
  loop: while (true) {
    continue loop;
  }
}
''');
    var continueStatement = findNode.continueStatement('continue loop');
    expect(continueStatement.label!.staticElement, findElement.label('loop'));
    expect(continueStatement.target, findNode.whileStatement('while (true)'));
  }

  test_visitContinueStatement_withoutLabel() async {
    await assertNoErrorsInCode('''
test() {
  while (true) {
    continue;
  }
}
''');
    var continueStatement = findNode.continueStatement('continue');
    expect(continueStatement.target, findNode.whileStatement('while (true)'));
  }

  test_visitExportDirective_combinators() async {
    await assertNoErrorsInCode('''
export 'dart:math' hide pi;
''');
    var pi = findElement
        .export('dart:math')
        .exportedLibrary!
        .exportNamespace
        .get('pi') as PropertyAccessorElement;
    expect(findNode.simple('pi').staticElement, pi.variable);
  }

  test_visitExportDirective_noCombinators() async {
    await assertNoErrorsInCode('''
export 'dart:math';
''');
    expect(findNode.export('dart:math').element!.exportedLibrary!.name,
        'dart.math');
  }

  test_visitFieldFormalParameter() async {
    await assertNoErrorsInCode('''
class A {
  int f;
  A(this.f);
}
''');
    expect(
        findNode.fieldFormalParameter('this.f').declaredElement!.type, intType);
  }

  test_visitImportDirective_combinators_noPrefix() async {
    await assertErrorsInCode('''
import 'dart:math' show pi;
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
    ]);
    var pi = findElement
        .import('dart:math')
        .importedLibrary!
        .exportNamespace
        .get('pi') as PropertyAccessorElement;
    expect(findNode.simple('pi').staticElement, pi.variable);
  }

  test_visitImportDirective_combinators_prefix() async {
    await assertErrorsInCode('''
import 'dart:math' as p show pi hide ln10;
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
    ]);
    var mathNamespace =
        findElement.import('dart:math').importedLibrary!.exportNamespace;
    var pi = mathNamespace.get('pi') as PropertyAccessorElement;
    expect(findNode.simple('pi').staticElement, pi.variable);
    var ln10 = mathNamespace.get('ln10') as PropertyAccessorElement;
    expect(findNode.simple('ln10').staticElement, ln10.variable);
  }

  test_visitImportDirective_noCombinators_noPrefix() async {
    await assertErrorsInCode('''
import 'dart:math';
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
    ]);
    expect(findNode.import('dart:math').element!.importedLibrary!.name,
        'dart.math');
  }

  test_visitImportDirective_noCombinators_prefix() async {
    await assertErrorsInCode('''
import 'dart:math' as p;
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
    ]);
    expect(findNode.import('dart:math').element!.importedLibrary!.name,
        'dart.math');
  }

  test_visitImportDirective_withCombinators() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
int v1 = 0;
final int v2 = 0;
''');
    await assertErrorsInCode('''
import 'lib1.dart' show v1, v2;
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
    ]);
    var importedVariables = findNode
        .import('lib1.dart')
        .element!
        .importedLibrary!
        .definingCompilationUnit
        .topLevelVariables;
    var v1 = importedVariables.where((v) => v.name == 'v1').single;
    var v2 = importedVariables.where((v) => v.name == 'v2').single;
    expect(findNode.simple('v1').staticElement, same(v1));
    expect(findNode.simple('v2').staticElement, same(v2));
  }

  test_visitInstanceCreationExpression_named() async {
    await assertNoErrorsInCode('''
class A {
  A.a();
}
test() => new A.a();
''');
    expect(findNode.instanceCreation('new A.a').constructorName.staticElement,
        findElement.constructor('a'));
  }

  test_visitInstanceCreationExpression_named_namedParameter() async {
    await assertNoErrorsInCode('''
class A {
  A.named({int a = 0});
}
test() => new A.named(a: 0);
''');
    expect(
        findNode.simple('a:').staticElement, same(findElement.parameter('a')));
  }

  test_visitInstanceCreationExpression_unnamed() async {
    await assertNoErrorsInCode('''
class A {}
test() => new A();
''');
    expect(findNode.instanceCreation('new A').constructorName.staticElement,
        findElement.unnamedConstructor('A'));
  }

  test_visitMethodInvocation() async {
    await assertNoErrorsInCode('''
num get i => 0;
test() => i.abs();
''');
    expect(
        findNode
            .methodInvocation('i.abs()')
            .methodName
            .staticElement!
            .declaration,
        same(typeProvider.numType.getMethod('abs')));
  }

  test_visitPrefixedIdentifier_dynamic() async {
    await assertNoErrorsInCode('''
test(dynamic a) => a.b;
''');
    var identifier = findNode.prefixed('a.b');
    expect(identifier.staticElement, isNull);
    expect(identifier.identifier.staticElement, isNull);
  }

  test_visitRedirectingConstructorInvocation_named() async {
    await assertNoErrorsInCode('''
class C {
  C(int x) : this.named(x /*usage*/);
  C.named(int y);
}
''');
    var invocation = findNode.redirectingConstructorInvocation('this');
    var namedConstructor = findElement.constructor('named', of: 'C');
    expect(invocation.staticElement, namedConstructor);
    expect(invocation.constructorName!.staticElement, namedConstructor);
    expect(findNode.simple('x /*usage*/').staticParameterElement,
        findElement.parameter('y'));
  }

  test_visitRedirectingConstructorInvocation_unnamed() async {
    await assertNoErrorsInCode('''
class C {
  C.named(int x) : this(x /*usage*/);
  C(int y);
}
''');
    expect(findNode.redirectingConstructorInvocation('this').staticElement,
        findElement.unnamedConstructor('C'));
    expect(findNode.simple('x /*usage*/').staticParameterElement,
        findElement.parameter('y'));
  }

  test_visitSuperConstructorInvocation() async {
    await assertNoErrorsInCode('''
class A {}
class B extends A {
  B() : super();
}
''');
    expect(findNode.superConstructorInvocation('super').staticElement,
        findElement.unnamedConstructor('A'));
  }

  test_visitSuperConstructorInvocation_namedParameter() async {
    await assertNoErrorsInCode('''
class A {
  A({dynamic p});
}
class B extends A {
  B() : super(p: 0);
}
''');
    expect(findNode.superConstructorInvocation('super').staticElement,
        findElement.unnamedConstructor('A'));
    expect(
        findNode.simple('p:').staticElement, same(findElement.parameter('p')));
  }
}
