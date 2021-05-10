// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:frontend_server/frontend_server.dart' as frontend
    show ProgramTransformer, ToStringTransformer, ToStringVisitor;
import 'package:kernel/kernel.dart';
import 'package:path/path.dart' as path;

import 'utils.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln('The first argument must be the path to the forntend server dill.');
    stderr.writeln('The second argument must be the path to the flutter_patched_sdk');
    exit(-1);
  }

  const Set<String> uiAndFlutter = <String>{
    'dart:ui',
    'package:flutter',
  };

  test('No packages', () {
    final frontend.ToStringTransformer transformer = frontend.ToStringTransformer(null, <String>{});
    final FakeComponent component = FakeComponent();
    transformer.transform(component);

    expect(
      !component.visitChildrenCalled,
      'Expected component.visitChildrenCalled to be false',
    );
  });

  test('dart:ui package', () {
    final frontend.ToStringTransformer transformer = frontend.ToStringTransformer(null, uiAndFlutter);
    final FakeComponent component = FakeComponent();
    transformer.transform(component);

    expect(
      component.visitChildrenCalled,
      'Expected component.visitChildrenCalled to be true',
    );
  });

  test('Child transformer', () {
    final FakeTransformer childTransformer = FakeTransformer();
    final frontend.ToStringTransformer transformer = frontend.ToStringTransformer(childTransformer, <String>{});
    final FakeComponent component = FakeComponent();
    transformer.transform(component);

    expect(
      !component.visitChildrenCalled,
      'Expected component.visitChildrenCalled to be false',
    );
    expect(
      childTransformer.transformCalled,
      'Expected childTransformer.transformCalled to be true',
    );
  });

  test('ToStringVisitor ignores non-toString procedures', () {
    final frontend.ToStringVisitor visitor = frontend.ToStringVisitor(uiAndFlutter);
    final FakeProcedure procedure = FakeProcedure(
      name: Name('name'),
      annotations: const <Expression>[],
    );
    visitor.visitProcedure(procedure);

    expect(
      !procedure.enclosingLibraryCalled,
      'Expected procedure.enclosingLibraryCalled to be false',
    );
  });

  test('ToStringVisitor ignores top level toString', () {
    // i.e. a `toString` method specified at the top of a library, like:
    //
    // void main() {}
    // String toString() => 'why?';
    final frontend.ToStringVisitor visitor = frontend.ToStringVisitor(uiAndFlutter);
    final Uri uri = Uri.parse('package:some_package/src/blah.dart');
    final Library library = Library(uri, fileUri: uri);
    final FakeStatement statement = FakeStatement();
    final FakeFunctionNode function = FakeFunctionNode(
      body: statement,
    );
    final FakeProcedure procedure = FakeProcedure(
      name: Name('tostring'),
      function: function,
      annotations: const <Expression>[],
      enclosingLibrary: library,
      isAbstract: false,
      isStatic: false,
    );
    visitor.visitProcedure(procedure);

    expect(
      !statement.replaceWithCalled,
      'Expected statement.replaceWithCalled to be false',
    );
  });

  test('ToStringVisitor ignores abstract toString', () {
    final frontend.ToStringVisitor visitor = frontend.ToStringVisitor(uiAndFlutter);
    final FakeStatement statement = FakeStatement();
    final FakeFunctionNode function = FakeFunctionNode(
      body: statement,
    );
    final Uri uri = Uri.parse('package:some_package/src/blah.dart');
    final Library library = Library(uri, fileUri: uri);
    final FakeProcedure procedure = FakeProcedure(
      name: Name('toString'),
      function: function,
      annotations: const <Expression>[],
      enclosingLibrary: library,
      enclosingClass: Class(name: 'foo', fileUri: uri),
      isAbstract: true,
      isStatic: false,
    );
    visitor.visitProcedure(procedure);

    expect(
      !statement.replaceWithCalled,
      'Expected statement.replaceWithCalled to be false',
    );
  });

  test('ToStringVisitor ignores static toString', () {
    final frontend.ToStringVisitor visitor = frontend.ToStringVisitor(uiAndFlutter);
    final Uri uri = Uri.parse('package:some_package/src/blah.dart');
    final FakeStatement statement = FakeStatement();
    final FakeFunctionNode function = FakeFunctionNode(
      body: statement,
    );
    final Library library = Library(uri, fileUri: uri);
    final FakeProcedure procedure = FakeProcedure(
      name: Name('toString'),
      function: function,
      annotations: const <Expression>[],
      enclosingLibrary: library,
      enclosingClass: Class(name: 'foo', fileUri: uri),
      isAbstract: false,
      isStatic: true,
    );
    visitor.visitProcedure(procedure);

    expect(
      !statement.replaceWithCalled,
      'Expected statement.replaceWithCalled jto be false',
    );
  });

  test('ToStringVisitor ignores enum toString', () {
    final frontend.ToStringVisitor visitor = frontend.ToStringVisitor(uiAndFlutter);
    final Uri uri = Uri.parse('package:some_package/src/blah.dart');
    final Library library = Library(uri, fileUri: uri);
    final FakeStatement statement = FakeStatement();
    final FakeFunctionNode function = FakeFunctionNode(
      body: statement,
    );
    final FakeProcedure procedure = FakeProcedure(
      name: Name('toString'),
      function: function,
      annotations: const <Expression>[],
      enclosingLibrary: library,
      enclosingClass: Class(name: 'foo', fileUri: uri)..isEnum = true,
      isAbstract: false,
      isStatic: false,
    );
    visitor.visitProcedure(procedure);

    expect(
      !statement.replaceWithCalled,
      'Expected statement.replaceWithCalled to be false',
    );
  });

  test('ToStringVisitor ignores non-specified libraries', () {
    final frontend.ToStringVisitor visitor = frontend.ToStringVisitor(uiAndFlutter);
    final Uri uri = Uri.parse('package:some_package/src/blah.dart');
    final Library library = Library(uri, fileUri: uri);
    final FakeStatement statement = FakeStatement();
    final FakeFunctionNode function = FakeFunctionNode(
      body: statement,
    );
    final FakeProcedure procedure = FakeProcedure(
      name: Name('toString'),
      function: function,
      annotations: const <Expression>[],
      enclosingLibrary: library,
      enclosingClass: Class(name: 'foo', fileUri: uri),
      isAbstract: false,
      isStatic: false,
    );
    visitor.visitProcedure(procedure);

    expect(
      !statement.replaceWithCalled,
      'Expected statement.replaceWithCalled to be false',
    );
  });

  test('ToStringVisitor ignores @keepToString', () {
    final frontend.ToStringVisitor visitor = frontend.ToStringVisitor(uiAndFlutter);
    final Uri uri = Uri.parse('dart:ui');
    final Library library = Library(uri, fileUri: uri);
    final Name name = Name('toString');
    final Class annotation = Class(name: '_KeepToString', fileUri: uri)..parent = library;
    final FakeStatement statement = FakeStatement();
    final FakeFunctionNode function = FakeFunctionNode(
      body: statement,
    );
    final FakeProcedure procedure = FakeProcedure(
      name: name,
      function: function,
      annotations: <Expression>[ConstantExpression(
        InstanceConstant(
          Reference()..node = annotation,
          <DartType>[],
          <Reference, Constant>{},
        ),
      )],
      enclosingLibrary: library,
      enclosingClass: Class(name: 'foo', fileUri: uri),
      isAbstract: false,
      isStatic: false,
    );
    visitor.visitProcedure(procedure);

    expect(
      !statement.replaceWithCalled,
      'Expected statement.replaceWithCalled to be false',
    );
  });

  void _validateReplacement(FakeStatement body) {
    final ReturnStatement replacement = body.replacement as ReturnStatement;
    expect(
      replacement.expression is SuperMethodInvocation,
      'Expected replacement.expression to be a SuperMethodInvocation',
    );
    final SuperMethodInvocation superMethodInvocation = replacement.expression as SuperMethodInvocation;
    expect(
      superMethodInvocation.name.text == 'toString',
      'Expected superMethodInvocation.name.text to be "toString"',
    );
  }

  test('ToStringVisitor replaces toString in specified libraries (dart:ui)', () {
    final frontend.ToStringVisitor visitor = frontend.ToStringVisitor(uiAndFlutter);
    final Uri uri = Uri.parse('dart:ui');
    final Library library = Library(uri, fileUri: uri);
    final Name name = Name('toString');
    final FakeStatement statement = FakeStatement();
    final FakeFunctionNode function = FakeFunctionNode(
      body: statement,
    );
    final FakeProcedure procedure = FakeProcedure(
      name: name,
      function: function,
      annotations: const <Expression>[],
      enclosingLibrary: library,
      enclosingClass: Class(name: 'foo', fileUri: uri),
      isAbstract: false,
      isStatic: false,
    );
    visitor.visitProcedure(procedure);

    _validateReplacement(statement);
  });

  test('ToStringVisitor replaces toString in specified libraries (package:flutter)', () {
    final frontend.ToStringVisitor visitor = frontend.ToStringVisitor(uiAndFlutter);
    final Uri uri = Uri.parse('package:flutter/src/foundation.dart');
    final Library library = Library(uri, fileUri: uri);
    final Name name = Name('toString');
    final FakeStatement statement = FakeStatement();
    final FakeFunctionNode function = FakeFunctionNode(
      body: statement,
    );
    final FakeProcedure procedure = FakeProcedure(
      name: name,
      function: function,
      annotations: const <Expression>[],
      enclosingLibrary: library,
      enclosingClass: Class(name: 'foo', fileUri: uri),
      isAbstract: false,
      isStatic: false,
    );
    visitor.visitProcedure(procedure);

    _validateReplacement(statement);
  });

  group('Integration tests',  () {
    final String dart = Platform.resolvedExecutable;
    final String frontendServer = args[0];
    final String sdkRoot = args[1];
    final String basePath = path.canonicalize(path.join(path.dirname(Platform.script.path), '..'));
    final String fixtures = path.join(basePath, 'test', 'fixtures');
    final String mainDart = path.join(fixtures, 'lib', 'main.dart');
    final String packageConfig = path.join(fixtures, '.dart_tool', 'package_config.json');
    final String regularDill = path.join(fixtures, 'toString.dill');
    final String transformedDill = path.join(fixtures, 'toStringTransformed.dill');


    void _checkProcessResult(ProcessResult result) {
      if (result.exitCode != 0) {
        stdout.writeln(result.stdout);
        stderr.writeln(result.stderr);
      }
      expect(result.exitCode == 0, 'Expected result.exitCode to be 0');
    }

    test('Without flag', () {
      _checkProcessResult(Process.runSync(dart, <String>[
        frontendServer,
        '--sdk-root=$sdkRoot',
        '--target=flutter',
        '--packages=$packageConfig',
        '--output-dill=$regularDill',
        mainDart,
      ]));
      final ProcessResult runResult = Process.runSync(dart, <String>[regularDill]);
      _checkProcessResult(runResult);
      String paintString = '"Paint.toString":"Paint(Color(0xffffffff))"';
      if (const bool.fromEnvironment('dart.vm.product', defaultValue: false)) {
        paintString = '"Paint.toString":"Instance of \'Paint\'"';
      }

      final String expectedStdout = '{$paintString,'
        '"Brightness.toString":"Brightness.dark",'
        '"Foo.toString":"I am a Foo",'
        '"Keep.toString":"I am a Keep"}';
      final String actualStdout = runResult.stdout.trim() as String;
      expect(
        actualStdout == expectedStdout,
        'Expected "$expectedStdout" but got "$actualStdout"',
      );
    });

    test('With flag', () {
      _checkProcessResult(Process.runSync(dart, <String>[
        frontendServer,
        '--sdk-root=$sdkRoot',
        '--target=flutter',
        '--packages=$packageConfig',
        '--output-dill=$transformedDill',
        '--delete-tostring-package-uri', 'dart:ui',
        '--delete-tostring-package-uri', 'package:flutter_frontend_fixtures',
        mainDart,
      ]));
      final ProcessResult runResult = Process.runSync(dart, <String>[transformedDill]);
      _checkProcessResult(runResult);

      const String expectedStdout = '{"Paint.toString":"Instance of \'Paint\'",'
        '"Brightness.toString":"Brightness.dark",'
        '"Foo.toString":"Instance of \'Foo\'",'
        '"Keep.toString":"I am a Keep"}';
      final String actualStdout = runResult.stdout.trim() as String;
      expect(
        actualStdout == expectedStdout,
        'Expected "$expectedStdout" but got "$actualStdout"',
      );
    });
  });

  if (TestFailure.testFailures == 0) {
    print('All tests passed!');
    exit(0);
  } else {
    print('${TestFailure.testFailures} test expectations failed');
    exit(1);
  }
}

abstract class Fake {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(invocation.memberName.toString().split('"')[1]);
  }
}

class FakeComponent extends Fake implements Component {
  bool visitChildrenCalled = false;

  @override
  void visitChildren(Visitor<void> v) {
    visitChildrenCalled = true;
  }
}

class FakeTransformer extends Fake implements frontend.ProgramTransformer {
  bool transformCalled = false;

  @override
  void transform(Component component) {
    transformCalled = true;
  }
}

class FakeProcedure extends Fake implements Procedure {
  FakeProcedure({
    this.name,
    this.function,
    this.annotations,
    Library enclosingLibrary,
    this.enclosingClass,
    this.isAbstract,
    this.isStatic,
  }) : _enclosingLibrary = enclosingLibrary;

  @override
  final Name name;

  @override
  final FunctionNode function;

  @override
  final List<Expression> annotations;

  @override
  final bool isAbstract;

  @override
  final bool isStatic;

  @override
  final Class enclosingClass;

  final Library _enclosingLibrary;

  bool enclosingLibraryCalled = false;

  @override
  Library get enclosingLibrary {
    enclosingLibraryCalled = true;
    return _enclosingLibrary;
  }
}

class FakeFunctionNode extends Fake implements FunctionNode {
  FakeFunctionNode({
    this.body,
  });

  @override
  final Statement body;
}

class FakeStatement extends Fake implements Statement {
  bool replaceWithCalled = false;

  TreeNode replacement;

  @override
  void replaceWith(TreeNode r) {
    replaceWithCalled = true;
    replacement = r;
  }
}
