// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dwds/dwds.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/build_runner/devfs_web.dart';
import 'package:matcher/matcher.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  Testbed testbed;

  setUp(() {
    testbed = Testbed();
  });

  test('WebExpressionCompiler handles successful expression compilation', () => testbed.run(() async {
    globals.fs.file('compilerOutput').writeAsStringSync('a');
    
    final ResidentCompiler residentCompiler = MockResidentCompiler();
    when(residentCompiler.compileExpressionToJs(
      any, any, any, any, any, any, any
    )).thenAnswer((Invocation invocation) async {
      return const CompilerOutput('compilerOutput', 0, <Uri>[]);
    });

    final ExpressionCompiler expressionCompiler = 
      WebExpressionCompiler(residentCompiler);

    final ExpressionCompilationResult result = 
      await expressionCompiler.compileExpressionToJs(
        null, null, 1, 1, null, null, null, null);

    expect(result,
      const TypeMatcher<ExpressionCompilationResult>()
        .having(
          (ExpressionCompilationResult instance) => instance.isError,
          'isError',
          false)
        .having(
          (ExpressionCompilationResult instance) => instance.result,
          'result',
          'a'));
  }));

  test('WebExpressionCompiler handles compilation error', () => testbed.run(() async {
    globals.fs.file('compilerOutput').writeAsStringSync('Error: a');

    final ResidentCompiler residentCompiler = MockResidentCompiler();
    when(residentCompiler.compileExpressionToJs(
      any, any, any, any, any, any, any
    )).thenAnswer((Invocation invocation) async {
      return const CompilerOutput('compilerOutput', 1, <Uri>[]);
    });

    final ExpressionCompiler expressionCompiler = 
      WebExpressionCompiler(residentCompiler);

    final ExpressionCompilationResult result = 
      await expressionCompiler.compileExpressionToJs(
        null, null, 1, 1, null, null, null, null);

    expect(result,
      const TypeMatcher<ExpressionCompilationResult>()
        .having(
          (ExpressionCompilationResult instance) => instance.isError,
          'isError',
          true)
        .having(
          (ExpressionCompilationResult instance) => instance.result,
          'result',
          'Error: a'));
  }));

  test('WebExpressionCompiler handles internal error', () => testbed.run(() async {
    final ResidentCompiler residentCompiler = MockResidentCompiler();
    when(residentCompiler.compileExpressionToJs(
      any, any, any, any, any, any, any
    )).thenAnswer((Invocation invocation) async {
      return null;
    });

    final ExpressionCompiler expressionCompiler = 
      WebExpressionCompiler(residentCompiler);

    final ExpressionCompilationResult result = 
      await expressionCompiler.compileExpressionToJs(
        null, null, 1, 1, null, null, null, 'a');

    expect(result,
      const TypeMatcher<ExpressionCompilationResult>()
        .having(
          (ExpressionCompilationResult instance) => instance.isError,
          'isError',
          true)
        .having(
          (ExpressionCompilationResult instance) => instance.result,
          'result',
          'InternalError: frontend server failed to compile \'a\''));
  }));
}

class MockResidentCompiler extends Mock implements ResidentCompiler {}