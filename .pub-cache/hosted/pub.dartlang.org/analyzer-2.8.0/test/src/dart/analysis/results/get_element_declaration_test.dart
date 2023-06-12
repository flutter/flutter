// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetElementDeclarationParsedTest);
    defineReflectiveTests(GetElementDeclarationResolvedTest);
  });
}

mixin GetElementDeclarationMixin implements PubPackageResolutionTest {
  Future<ElementDeclarationResult?> getElementDeclaration(Element element);

  test_class() async {
    await resolveTestCode(r'''
class A {}
''');
    var element = findNode.classDeclaration('A').declaredElement!;
    var result = await getElementDeclaration(element);
    var node = result!.node as ClassDeclaration;
    expect(node.name.name, 'A');
  }

  test_class_duplicate() async {
    await resolveTestCode(r'''
class A {} // 1
class A {} // 2
''');
    {
      var element = findNode.classDeclaration('A {} // 1').declaredElement!;
      var result = await getElementDeclaration(element);
      var node = result!.node as ClassDeclaration;
      expect(node.name.name, 'A');
      expect(
        node.name.offset,
        this.result.content.indexOf('A {} // 1'),
      );
    }

    {
      var element = findNode.classDeclaration('A {} // 2').declaredElement!;
      var result = await getElementDeclaration(element);
      var node = result!.node as ClassDeclaration;
      expect(node.name.name, 'A');
      expect(
        node.name.offset,
        this.result.content.indexOf('A {} // 2'),
      );
    }
  }

  test_class_inPart() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
part of 'test.dart';
class A {}
''');
    await resolveTestCode(r'''
part 'a.dart';
''');
    var library = this.result.unit.declaredElement!.library;
    var element = library.getType('A')!;
    var result = await getElementDeclaration(element);
    var node = result!.node as ClassDeclaration;
    expect(node.name.name, 'A');
  }

  test_class_missingName() async {
    await resolveTestCode('''
class {}
''');
    var element = findNode.classDeclaration('class {}').declaredElement!;
    var result = await getElementDeclaration(element);
    var node = result!.node as ClassDeclaration;
    expect(node.name.name, '');
    expect(node.name.offset, 6);
  }

  test_classTypeAlias() async {
    await resolveTestCode(r'''
mixin M {}
class A {}
class B = A with M;
''');
    var element = findElement.class_('B');
    var result = await getElementDeclaration(element);
    var node = result!.node as ClassTypeAlias;
    expect(node.name.name, 'B');
  }

  test_compilationUnit() async {
    await resolveTestCode('');
    var element = findElement.unitElement;
    var result = await getElementDeclaration(element);
    expect(result, isNull);
  }

  test_constructor() async {
    await resolveTestCode(r'''
class A {
  A();
  A.named();
}
''');
    {
      var unnamed = findNode.constructor('A();').declaredElement!;
      var result = await getElementDeclaration(unnamed);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name, isNull);
    }

    {
      var named = findNode.constructor('A.named();').declaredElement!;
      var result = await getElementDeclaration(named);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name!.name, 'named');
    }
  }

  test_constructor_duplicate_named() async {
    await resolveTestCode(r'''
class A {
  A.named(); // 1
  A.named(); // 2
}
''');
    {
      var element = findNode.constructor('A.named(); // 1').declaredElement!;
      var result = await getElementDeclaration(element);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name!.name, 'named');
      expect(
        node.name!.offset,
        this.result.content.indexOf('named(); // 1'),
      );
    }

    {
      var element = findNode.constructor('A.named(); // 2').declaredElement!;
      var result = await getElementDeclaration(element);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name!.name, 'named');
      expect(
        node.name!.offset,
        this.result.content.indexOf('named(); // 2'),
      );
    }
  }

  test_constructor_duplicate_unnamed() async {
    await resolveTestCode(r'''
class A {
  A(); // 1
  A(); // 2
}
''');
    {
      var element = findNode.constructor('A(); // 1').declaredElement!;
      var result = await getElementDeclaration(element);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name, isNull);
      expect(
        node.returnType.offset,
        this.result.content.indexOf('A(); // 1'),
      );
    }

    {
      var element = findNode.constructor('A(); // 2').declaredElement!;
      var result = await getElementDeclaration(element);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name, isNull);
      expect(
        node.returnType.offset,
        this.result.content.indexOf('A(); // 2'),
      );
    }
  }

  test_constructor_synthetic() async {
    await resolveTestCode(r'''
class A {}
''');
    var element = findElement.class_('A').unnamedConstructor!;
    expect(element.isSynthetic, isTrue);

    var result = await getElementDeclaration(element);
    expect(result, isNull);
  }

  test_enum() async {
    await resolveTestCode(r'''
enum MyEnum {a, b, c}
''');
    var element = findElement.enum_('MyEnum');
    var result = await getElementDeclaration(element);
    var node = result!.node as EnumDeclaration;
    expect(node.name.name, 'MyEnum');
  }

  test_enum_constant() async {
    await resolveTestCode(r'''
enum MyEnum {a, b, c}
''');
    var element = findElement.field('a');
    var result = await getElementDeclaration(element);
    var node = result!.node as EnumConstantDeclaration;
    expect(node.name.name, 'a');
  }

  test_extension() async {
    await resolveTestCode(r'''
extension E on int {}
''');
    var element = findNode.extensionDeclaration('E').declaredElement!;
    var result = await getElementDeclaration(element);
    var node = result!.node as ExtensionDeclaration;
    expect(node.name!.name, 'E');
  }

  test_field() async {
    await resolveTestCode(r'''
class C {
  int foo;
}
''');
    var element = findElement.field('foo');

    var result = await getElementDeclaration(element);
    var node = result!.node as VariableDeclaration;
    expect(node.name.name, 'foo');
  }

  test_functionDeclaration_local() async {
    await resolveTestCode(r'''
main() {
  void foo() {}
}
''');
    var element = findElement.localFunction('foo');

    var result = await getElementDeclaration(element);
    var node = result!.node as FunctionDeclaration;
    expect(node.name.name, 'foo');
  }

  test_functionDeclaration_top() async {
    await resolveTestCode(r'''
void foo() {}
''');
    var element = findElement.topFunction('foo');

    var result = await getElementDeclaration(element);
    var node = result!.node as FunctionDeclaration;
    expect(node.name.name, 'foo');
  }

  test_genericFunctionTypeElement() async {
    await resolveTestCode(r'''
typedef F = void Function();
''');
    var element = findElement.typeAlias('F').aliasedElement!;
    var result = await getElementDeclaration(element);
    expect(result, isNull);
  }

  test_getter_class() async {
    await resolveTestCode(r'''
class A {
  int get x => 0;
}
''');
    var element = findElement.getter('x');
    var result = await getElementDeclaration(element);
    var node = result!.node as MethodDeclaration;
    expect(node.name.name, 'x');
    expect(node.isGetter, isTrue);
  }

  test_getter_top() async {
    await resolveTestCode(r'''
int get x => 0;
''');
    var element = findElement.topGet('x');
    var result = await getElementDeclaration(element);
    var node = result!.node as FunctionDeclaration;
    expect(node.name.name, 'x');
    expect(node.isGetter, isTrue);
  }

  test_library() async {
    await resolveTestCode(r'''
library foo;
''');
    var element = findElement.unitElement.enclosingElement;
    var result = await getElementDeclaration(element);
    expect(result, isNull);
  }

  test_localVariable() async {
    await resolveTestCode(r'''
main() {
  int foo;
}
''');
    var element = findElement.localVar('foo');

    var result = await getElementDeclaration(element);
    var node = result!.node as VariableDeclaration;
    expect(node.name.name, 'foo');
  }

  test_method() async {
    await resolveTestCode(r'''
class C {
  void foo() {}
}
''');
    var element = findElement.method('foo');

    var result = await getElementDeclaration(element);
    var node = result!.node as MethodDeclaration;
    expect(node.name.name, 'foo');
  }

  test_mixin() async {
    await resolveTestCode(r'''
mixin M {}
''');
    var element = findElement.mixin('M');
    var result = await getElementDeclaration(element);
    var node = result!.node as MixinDeclaration;
    expect(node.name.name, 'M');
  }

  test_parameter() async {
    await resolveTestCode(r'''
void f(int a) {}
''');
    var element = findElement.parameter('a');

    var result = await getElementDeclaration(element);
    var node = result!.node as SimpleFormalParameter;
    expect(node.identifier!.name, 'a');
  }

  test_parameter_missingName_named() async {
    await resolveTestCode(r'''
void f({@a}) {}
''');
    var f = findElement.topFunction('f');
    var element = f.parameters.single;
    expect(element.name, '');
    expect(element.isNamed, isTrue);

    var result = await getElementDeclaration(element);
    var node = result!.node as DefaultFormalParameter;
    expect(node.identifier!.name, '');
  }

  test_parameter_missingName_required() async {
    await resolveTestCode(r'''
void f(@a) {}
''');
    var f = findElement.topFunction('f');
    var element = f.parameters.single;
    expect(element.name, '');
    expect(element.isPositional, isTrue);

    var result = await getElementDeclaration(element);
    var node = result!.node as SimpleFormalParameter;
    expect(node.identifier!.name, '');
  }

  test_setter_class() async {
    await resolveTestCode(r'''
class A {
  set x(_) {}
}
''');
    var element = findElement.setter('x');
    var result = await getElementDeclaration(element);
    var node = result!.node as MethodDeclaration;
    expect(node.name.name, 'x');
    expect(node.isSetter, isTrue);
  }

  test_setter_top() async {
    await resolveTestCode(r'''
set x(_) {}
''');
    var element = findElement.topSet('x');
    var result = await getElementDeclaration(element);
    var node = result!.node as FunctionDeclaration;
    expect(node.name.name, 'x');
    expect(node.isSetter, isTrue);
  }

  test_topLevelVariable() async {
    await resolveTestCode(r'''
int foo;
''');
    var element = findElement.topVar('foo');

    var result = await getElementDeclaration(element);
    var node = result!.node as VariableDeclaration;
    expect(node.name.name, 'foo');
  }

  test_topLevelVariable_synthetic() async {
    await resolveTestCode(r'''
int get foo => 0;
''');
    var element = findElement.topVar('foo');

    var result = await getElementDeclaration(element);
    expect(result, isNull);
  }
}

@reflectiveTest
class GetElementDeclarationParsedTest extends PubPackageResolutionTest
    with GetElementDeclarationMixin {
  @override
  Future<ElementDeclarationResult?> getElementDeclaration(
      Element element) async {
    var libraryPath = element.library!.source.fullName;
    var library = _getParsedLibrary(libraryPath);
    return library.getElementDeclaration(element);
  }

  ParsedLibraryResult _getParsedLibrary(String path) {
    var session = contextFor(path).currentSession;
    return session.getParsedLibrary(path) as ParsedLibraryResult;
  }
}

@reflectiveTest
class GetElementDeclarationResolvedTest extends PubPackageResolutionTest
    with GetElementDeclarationMixin {
  @override
  Future<ElementDeclarationResult?> getElementDeclaration(
      Element element) async {
    var libraryPath = element.library!.source.fullName;
    var library = await _getResolvedLibrary(libraryPath);
    return library.getElementDeclaration(element);
  }

  Future<ResolvedLibraryResult> _getResolvedLibrary(String path) async {
    var session = contextFor(path).currentSession;
    return await session.getResolvedLibrary(path) as ResolvedLibraryResult;
  }
}
