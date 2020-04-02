// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_frontend_server/server.dart';
import 'package:frontend_server/frontend_server.dart' as frontend show ProgramTransformer;
import 'package:kernel/kernel.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;

import 'package:test/test.dart';

void main(List<String> args) async {
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
    final ToStringTransformer transformer = ToStringTransformer(null, <String>{});

    final MockComponent component = MockComponent();
    transformer.transform(component);
    verifyNever(component.visitChildren(any));
  });

  test('dart:ui package', () {
    final ToStringTransformer transformer = ToStringTransformer(null, uiAndFlutter);

    final MockComponent component = MockComponent();
    transformer.transform(component);
    verify(component.visitChildren(any)).called(1);
  });

  test('Child transformer', () {
    final MockTransformer childTransformer = MockTransformer();
    final ToStringTransformer transformer = ToStringTransformer(childTransformer, <String>{});

    final MockComponent component = MockComponent();
    transformer.transform(component);
    verifyNever(component.visitChildren(any));
    verify(childTransformer.transform(component)).called(1);
  });

  test('ToStringVisitor ignores non-toString procedures', () {
    final ToStringVisitor visitor = ToStringVisitor(uiAndFlutter);
    final MockProcedure procedure = MockProcedure();
    when(procedure.name).thenReturn(Name('main'));
    when(procedure.annotations).thenReturn(const <Expression>[]);

    visitor.visitProcedure(procedure);
    verifyNever(procedure.enclosingLibrary);
  });

  test('ToStringVisitor ignores top level toString', () {
    // i.e. a `toString` method specified at the top of a library, like:
    //
    // void main() {}
    // String toString() => 'why?';
    final ToStringVisitor visitor = ToStringVisitor(uiAndFlutter);
    final MockProcedure procedure = MockProcedure();
    final MockFunctionNode function = MockFunctionNode();
    final MockStatement statement = MockStatement();
    final Library library = Library(Uri.parse('package:some_package/src/blah.dart'));
    when(procedure.function).thenReturn(function);
    when(procedure.name).thenReturn(Name('toString'));
    when(procedure.annotations).thenReturn(const <Expression>[]);
    when(procedure.enclosingLibrary).thenReturn(library);
    when(procedure.enclosingClass).thenReturn(null);
    when(procedure.isAbstract).thenReturn(false);
    when(procedure.isStatic).thenReturn(false);
    when(function.body).thenReturn(statement);

    visitor.visitProcedure(procedure);
    verifyNever(statement.replaceWith(any));
  });

  test('ToStringVisitor ignores abstract toString', () {
    final ToStringVisitor visitor = ToStringVisitor(uiAndFlutter);
    final MockProcedure procedure = MockProcedure();
    final MockFunctionNode function = MockFunctionNode();
    final MockStatement statement = MockStatement();
    final Library library = Library(Uri.parse('package:some_package/src/blah.dart'));
    when(procedure.function).thenReturn(function);
    when(procedure.name).thenReturn(Name('toString'));
    when(procedure.annotations).thenReturn(const <Expression>[]);
    when(procedure.enclosingLibrary).thenReturn(library);
    when(procedure.enclosingClass).thenReturn(Class());
    when(procedure.isAbstract).thenReturn(true);
    when(procedure.isStatic).thenReturn(false);
    when(function.body).thenReturn(statement);

    visitor.visitProcedure(procedure);
    verifyNever(statement.replaceWith(any));
  });

  test('ToStringVisitor ignores static toString', () {
    final ToStringVisitor visitor = ToStringVisitor(uiAndFlutter);
    final MockProcedure procedure = MockProcedure();
    final MockFunctionNode function = MockFunctionNode();
    final MockStatement statement = MockStatement();
    final Library library = Library(Uri.parse('package:some_package/src/blah.dart'));
    when(procedure.function).thenReturn(function);
    when(procedure.name).thenReturn(Name('toString'));
    when(procedure.annotations).thenReturn(const <Expression>[]);
    when(procedure.enclosingLibrary).thenReturn(library);
    when(procedure.enclosingClass).thenReturn(Class());
    when(procedure.isAbstract).thenReturn(false);
    when(procedure.isStatic).thenReturn(true);
    when(function.body).thenReturn(statement);

    visitor.visitProcedure(procedure);
    verifyNever(statement.replaceWith(any));
  });

  test('ToStringVisitor ignores enum toString', () {
    final ToStringVisitor visitor = ToStringVisitor(uiAndFlutter);
    final MockProcedure procedure = MockProcedure();
    final MockFunctionNode function = MockFunctionNode();
    final MockStatement statement = MockStatement();
    final Library library = Library(Uri.parse('package:some_package/src/blah.dart'));
    when(procedure.function).thenReturn(function);
    when(procedure.name).thenReturn(Name('toString'));
    when(procedure.annotations).thenReturn(const <Expression>[]);
    when(procedure.enclosingLibrary).thenReturn(library);
    when(procedure.enclosingClass).thenReturn(Class()..isEnum = true);
    when(procedure.isAbstract).thenReturn(false);
    when(procedure.isStatic).thenReturn(false);
    when(function.body).thenReturn(statement);

    visitor.visitProcedure(procedure);
    verifyNever(statement.replaceWith(any));
  });

  test('ToStringVisitor ignores non-specified libraries', () {
    final ToStringVisitor visitor = ToStringVisitor(uiAndFlutter);
    final MockProcedure procedure = MockProcedure();
    final MockFunctionNode function = MockFunctionNode();
    final MockStatement statement = MockStatement();
    final Library library = Library(Uri.parse('package:some_package/src/blah.dart'));
    when(procedure.function).thenReturn(function);
    when(procedure.name).thenReturn(Name('toString'));
    when(procedure.annotations).thenReturn(const <Expression>[]);
    when(procedure.enclosingLibrary).thenReturn(library);
    when(procedure.enclosingClass).thenReturn(Class());
    when(procedure.isAbstract).thenReturn(false);
    when(procedure.isStatic).thenReturn(false);
    when(function.body).thenReturn(statement);

    visitor.visitProcedure(procedure);
    verifyNever(statement.replaceWith(any));
  });

  test('ToStringVisitor ignores @keepToString', () {
    final ToStringVisitor visitor = ToStringVisitor(uiAndFlutter);
    final MockProcedure procedure = MockProcedure();
    final MockFunctionNode function = MockFunctionNode();
    final MockStatement statement = MockStatement();
    final Library library = Library(Uri.parse('dart:ui'));
    final Name name = Name('toString');
    final Class annotation = Class(name: '_KeepToString')..parent = Library(Uri.parse('dart:ui'));

    when(procedure.function).thenReturn(function);
    when(procedure.name).thenReturn(name);
    when(procedure.annotations).thenReturn(<Expression>[
      ConstantExpression(
        InstanceConstant(
          Reference()..node = annotation,
          <DartType>[],
          <Reference, Constant>{},
        ),
      ),
    ]);

    when(procedure.enclosingLibrary).thenReturn(library);
    when(procedure.enclosingClass).thenReturn(Class());
    when(procedure.isAbstract).thenReturn(false);
    when(procedure.isStatic).thenReturn(false);
    when(function.body).thenReturn(statement);

    visitor.visitProcedure(procedure);
    verifyNever(statement.replaceWith(any));
  });

  void _validateReplacement(MockStatement body) {
    final ReturnStatement replacement = verify(body.replaceWith(captureAny)).captured.single as ReturnStatement;
    expect(replacement.expression, isA<SuperMethodInvocation>());
    final SuperMethodInvocation superMethodInvocation = replacement.expression as SuperMethodInvocation;
    expect(superMethodInvocation.name.name, 'toString');
  }

  test('ToStringVisitor replaces toString in specified libraries (dart:ui)', () {
    final ToStringVisitor visitor = ToStringVisitor(uiAndFlutter);
    final MockProcedure procedure = MockProcedure();
    final MockFunctionNode function = MockFunctionNode();
    final MockStatement statement = MockStatement();
    final Library library = Library(Uri.parse('dart:ui'));
    final Name name = Name('toString');

    when(procedure.function).thenReturn(function);
    when(procedure.name).thenReturn(name);
    when(procedure.annotations).thenReturn(const <Expression>[]);
    when(procedure.enclosingLibrary).thenReturn(library);
    when(procedure.enclosingClass).thenReturn(Class());
    when(procedure.isAbstract).thenReturn(false);
    when(procedure.isStatic).thenReturn(false);
    when(function.body).thenReturn(statement);

    visitor.visitProcedure(procedure);
    _validateReplacement(statement);
  });

  test('ToStringVisitor replaces toString in specified libraries (package:flutter)', () {
    final ToStringVisitor visitor = ToStringVisitor(uiAndFlutter);
    final MockProcedure procedure = MockProcedure();
    final MockFunctionNode function = MockFunctionNode();
    final MockStatement statement = MockStatement();
    final Library library = Library(Uri.parse('package:flutter/src/foundation.dart'));
    final Name name = Name('toString');

    when(procedure.function).thenReturn(function);
    when(procedure.name).thenReturn(name);
    when(procedure.annotations).thenReturn(const <Expression>[]);
    when(procedure.enclosingLibrary).thenReturn(library);
    when(procedure.enclosingClass).thenReturn(Class());
    when(procedure.isAbstract).thenReturn(false);
    when(procedure.isStatic).thenReturn(false);
    when(function.body).thenReturn(statement);

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
    final String dotPackages = path.join(fixtures, '.packages');
    final String regularDill = path.join(fixtures, 'toString.dill');
    final String transformedDill = path.join(fixtures, 'toStringTransformed.dill');


    void _checkProcessResult(ProcessResult result) {
      if (result.exitCode != 0) {
        stdout.writeln(result.stdout);
        stderr.writeln(result.stderr);
      }
      expect(result.exitCode, 0);
    }

    test('Without flag', () async {
      _checkProcessResult(Process.runSync(dart, <String>[
        frontendServer,
        '--sdk-root=$sdkRoot',
        '--target=flutter',
        '--packages=$dotPackages',
        '--output-dill=$regularDill',
        mainDart,
      ]));
      final ProcessResult runResult = Process.runSync(dart, <String>[regularDill]);
      _checkProcessResult(runResult);
      String paintString = '"Paint.toString":"Paint(Color(0xffffffff))"';
      if (const bool.fromEnvironment('dart.vm.product', defaultValue: false)) {
        paintString = '"Paint.toString":"Instance of \'Paint\'"';
      }
      expect(
        runResult.stdout.trim(),
        '{$paintString,'
         '"Brightness.toString":"Brightness.dark",'
         '"Foo.toString":"I am a Foo",'
         '"Keep.toString":"I am a Keep"}',
      );
    });

    test('With flag', () async {
      _checkProcessResult(Process.runSync(dart, <String>[
        frontendServer,
        '--sdk-root=$sdkRoot',
        '--target=flutter',
        '--packages=$dotPackages',
        '--output-dill=$transformedDill',
        '--delete-tostring-package-uri', 'dart:ui',
        '--delete-tostring-package-uri', 'package:flutter_frontend_fixtures',
        mainDart,
      ]));
      final ProcessResult runResult = Process.runSync(dart, <String>[transformedDill]);
      _checkProcessResult(runResult);
      expect(
        runResult.stdout.trim(),
        '{"Paint.toString":"Instance of \'Paint\'",'
         '"Brightness.toString":"Brightness.dark",'
         '"Foo.toString":"Instance of \'Foo\'",'
         '"Keep.toString":"I am a Keep"}',
      );
    });
  });
}

class MockComponent extends Mock implements Component {}
class MockTransformer extends Mock implements frontend.ProgramTransformer {}
class MockProcedure extends Mock implements Procedure {}
class MockFunctionNode extends Mock implements FunctionNode {}
class MockStatement extends Mock implements Statement {}
