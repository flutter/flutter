// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NodeCoveringTest);
  });
}

@reflectiveTest
class NodeCoveringTest extends PubPackageResolutionTest {
  Future<AstNode> coveringNode(String sourceCode) async {
    var range = await _range(sourceCode);
    var node =
        result.unit.nodeCovering(offset: range.offset, length: range.length);
    return node!;
  }

  void test_after_EOF() async {
    await resolveTestCode('''
library myLib;
''');
    var node = result.unit.nodeCovering(offset: 100, length: 20);
    expect(node, null);
  }

  Future<void> test_after_lastNonEOF() async {
    var node = await coveringNode('''
library myLib;

^
''');
    node as CompilationUnit;
  }

  Future<void> test_before_firstNonEOF() async {
    var node = await coveringNode('''
^

library myLib;
''');
    node as CompilationUnit;
  }

  Future<void> test_between_classMembers() async {
    var node = await coveringNode('''
class C {
  void a() {}
^
  void b() {}
}
''');
    node as ClassDeclaration;
  }

  Future<void> test_between_commaAndIdentifier_arguments() async {
    var node = await coveringNode('''
void f(int a, int b) {
  f(a,^b);
}
''');
    node as ArgumentList;
  }

  Future<void> test_between_commaAndIdentifier_parameters() async {
    var node = await coveringNode('''
class C {
  void m(int a,^int b) {}
}
''');
    node as FormalParameterList;
  }

  Future<void> test_between_commaAndIdentifier_typeArguments() async {
    var node = await coveringNode('''
var m = Map<int,^int>();
''');
    node as TypeArgumentList;
  }

  Future<void> test_between_commaAndIdentifier_typeParameters() async {
    var node = await coveringNode('''
class C<S,^T> {}
''');
    node as TypeParameterList;
  }

  Future<void> test_between_declarations() async {
    var node = await coveringNode('''
class A {}
^
class B {}
''');
    node as CompilationUnit;
  }

  Future<void> test_between_directives() async {
    var node = await coveringNode('''
library myLib;
^
import 'dart:core';
''');
    node as CompilationUnit;
  }

  Future<void> test_between_identifierAndComma_arguments() async {
    var node = await coveringNode('''
void f(int a, int b) {
  f(a^, b);
}
''');
    node as ArgumentList;
  }

  Future<void> test_between_identifierAndComma_parameters() async {
    var node = await coveringNode('''
class C {
  void m(int a^, int b) {}
}
''');
    node as FormalParameterList;
  }

  Future<void> test_between_identifierAndComma_typeArguments() async {
    var node = await coveringNode('''
var m = Map<int^, int>();
''');
    node as TypeArgumentList;
  }

  Future<void> test_between_identifierAndComma_typeParameters() async {
    var node = await coveringNode('''
class C<S^, T> {}
''');
    node as TypeParameterList;
  }

  Future<void> test_between_identifierAndPeriod() async {
    var node = await coveringNode('''
var x = o^.m();
''');
    node as MethodInvocation;
  }

  Future<void> test_between_modifierAndFunctionBody() async {
    var node = await coveringNode('''
void f() async^{}
''');
    node as BlockFunctionBody;
  }

  Future<void> test_between_nameAndParameters_function() async {
    var node = await coveringNode('''
void f^() {}
''');
    node as FunctionDeclaration;
  }

  Future<void> test_between_nameAndParameters_method() async {
    var node = await coveringNode('''
class C {
  void m^() {}
}
''');
    node as MethodDeclaration;
  }

  Future<void> test_between_periodAndIdentifier() async {
    var node = await coveringNode('''
var x = o.^m();
''');
    node as MethodInvocation;
  }

  Future<void> test_between_statements() async {
    var node = await coveringNode('''
void f() {
  var x = 0;
^
  print(x);
}
''');
    node as Block;
  }

  Future<void> test_inComment_beginning() async {
    var node = await coveringNode('''
/// A [^B].
class C {}
''');
    node as SimpleIdentifier;
  }

  Future<void> test_inComment_beginning_qualified() async {
    var node = await coveringNode('''
/// A [B.^b].
class C {}
''');
    node as PrefixedIdentifier;
  }

  Future<void> test_inComment_end() async {
    var node = await coveringNode('''
/// A [B.b^].
class C {}
''');
    node as SimpleIdentifier;
  }

  Future<void> test_inComment_middle() async {
    var node = await coveringNode('''
/// A [B.b^b].
class C {}
''');
    node as SimpleIdentifier;
  }

  Future<void> test_inName_class() async {
    var node = await coveringNode('''
class A^B {}
''');
    node as ClassDeclaration;
  }

  Future<void> test_inName_function() async {
    var node = await coveringNode('''
void f^f() {}
''');
    node as FunctionDeclaration;
  }

  Future<void> test_inName_method() async {
    var node = await coveringNode('''
class C {
  void m^m() {}
}
''');
    node as MethodDeclaration;
  }

  Future<void> test_inOperator_assignment() async {
    var node = await coveringNode('''
void f(int x) {
  x +^= 3;
}
''');
    node as AssignmentExpression;
  }

  Future<void> test_inOperator_nullAwareAccess() async {
    var node = await coveringNode('''
var x = o?^.m();
''');
    node as MethodInvocation;
  }

  Future<void> test_inOperator_postfix() async {
    var node = await coveringNode('''
var x = y+^+;
''');
    node as PostfixExpression;
  }

  Future<void> test_libraryKeyword() async {
    var node = await coveringNode('''
libr^ary myLib;
''');
    node as LibraryDirective;
  }

  Future<void> test_parentAndChildWithSameRange_blockFunctionBody() async {
    var node = await coveringNode('''
void f() { ^ }
''');
    node as Block;
    var parent = node.parent;
    parent as BlockFunctionBody;
    expect(parent.offset, node.offset);
    expect(parent.length, node.length);
  }

  Future<void> test_parentAndChildWithSameRange_implicitCall() async {
    var node = await coveringNode('''
class C { void call() {} }  Function f = C^();
''');
    node as InstanceCreationExpression;
    var parent = node.parent;
    parent as ImplicitCallReference;
    expect(parent.offset, node.offset);
    expect(parent.length, node.length);
  }

  Future<SourceRange> _range(String sourceCode) async {
    // TODO(brianwilkerson) Move TestCode to the analyzer package and make use
    //  of it here.
    var offset = sourceCode.indexOf('^');
    if (offset < 0 || sourceCode.contains('^', offset + 1)) {
      fail('Tests must contain a single selection range');
    }
    var testCode =
        sourceCode.substring(0, offset) + sourceCode.substring(offset + 1);
    await resolveTestCode(testCode);
    return SourceRange(offset, 0);
  }
}
