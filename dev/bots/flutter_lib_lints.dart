// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import 'utils.dart';

Future<void> parseFlutterLibAndAnalyze(String workingDirectory) async {
  final String flutterLibPath = '$workingDirectory/packages/flutter/lib';
  final AnalysisContextCollection collection = AnalysisContextCollection(
    includedPaths: <String>[flutterLibPath],
    excludedPaths: <String>['$flutterLibPath/fix_data'],
  );

  final List<String> errors = <String>[];

  for (final AnalysisContext context in collection.contexts) {
    // Normalized paths to all analyzed files.
    final Iterable<String> analyzedFilePaths = context.contextRoot.analyzedFiles();
    final AnalysisSession session = context.currentSession;

    for (final String path in analyzedFilePaths) {
      //final SomeResolvedUnitResult x = await session.getResolvedUnit(path);
      switch (await session.getResolvedUnit(path)) {
        case ResolvedUnitResult(:final unit, :final lineInfo, :final content):
          final _DoubleClampVisitor2 visitor = _DoubleClampVisitor2();
          unit.visitChildren(visitor);
      }

      if (x is ResolvedUnitResult) {
        x.unit.visitChildren(visitor);
        for (final MethodInvocation node in visitor.clampInvocationNode) {
          final LineInfo lineInfo = x.lineInfo;
          final int lineNumber = lineInfo.getLocation(node.function.offset).lineNumber;
          final String lineContent = x.content.substring(
            lineInfo.getOffsetOfLine(lineNumber - 1),
            lineInfo.getOffsetOfLine(lineNumber) - 1,
          );
          if (lineContent.contains('// ignore_clamp_double_lint')) {
            continue;
          }
          errors.add('$path:$lineNumber: `Double.clamp` method used instead of `clampDouble`.');
        }
      } else {
        foundError(<String>['analyzer error: file $x could not be resolved.']);
      }
    }
  }
  if (errors.isNotEmpty) {
    foundError(<String>[
      ...errors,
      '\n${bold}For performance reasons, we use a custom `clampDouble` function instead of using `Double.clamp`.$reset',
      '\n${bold}For non-double uses of `clamp`, use `// ignore_clamp_double_lint` on the line to silence this message.$reset',
    ]);
  }
}

abstract class ResolvedASTVerifier {
}

class _DoubleClampVisitor extends RecursiveAstVisitor<CompilationUnit> {
  _DoubleClampVisitor();

  final List<MethodInvocation> clampInvocationNode = <MethodInvocation>[];

  @override
  CompilationUnit? visitMethodInvocation(MethodInvocation node) {
    final bool isNumClampInvocation = node.methodName.name == 'clamp'
                                   && (node.target?.staticType?.isDartCoreDouble ?? false);

    if (isNumClampInvocation) {
      clampInvocationNode.add(node);
    }
    node.visitChildren(this);
    return null;
  }
}
