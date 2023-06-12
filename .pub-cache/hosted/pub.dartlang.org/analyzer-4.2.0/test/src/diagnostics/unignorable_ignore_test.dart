// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnignorableIgnoreTest);
  });
}

@reflectiveTest
class UnignorableIgnoreTest extends PubPackageResolutionTest {
  test_file_lowerCase() async {
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(unignorableNames: ['undefined_annotation']),
    );
    await assertErrorsInCode(r'''
// ignore_for_file: undefined_annotation
@x int a = 0;
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 41, 2),
    ]);
  }

  test_file_upperCase() async {
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(unignorableNames: ['UNDEFINED_ANNOTATION']),
    );
    await assertErrorsInCode(r'''
// ignore_for_file: UNDEFINED_ANNOTATION
@x int a = 0;
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 41, 2),
    ]);
  }

  test_line() async {
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(unignorableNames: ['undefined_annotation']),
    );
    await assertErrorsInCode(r'''
// ignore: undefined_annotation
@x int a = 0;
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 32, 2),
    ]);
  }

  test_lint() async {
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
          unignorableNames: ['avoid_int'], lints: ['avoid_int']),
    );
    var avoidIntRule = _AvoidIntRule();
    Registry.ruleRegistry.register(avoidIntRule);
    await assertErrorsInCode(r'''
// ignore: avoid_int
int a = 0;
''', [
      error(avoidIntRule.lintCode, 21, 3),
    ]);
  }
}

class _AvoidIntRule extends LintRule {
  _AvoidIntRule()
      : super(
          name: 'avoid_int',
          description: '',
          details: '',
          group: Group.errors,
        );

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _AvoidIntVisitor(this);
    registry.addNamedType(this, visitor);
  }
}

class _AvoidIntVisitor extends SimpleAstVisitor {
  final LintRule rule;

  _AvoidIntVisitor(this.rule);

  @override
  void visitNamedType(NamedType node) {
    if (node.name.name == 'int') {
      rule.reportLint(node.name);
    }
  }
}
