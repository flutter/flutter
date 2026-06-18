// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';

import '../src/common.dart';

void main() {
  testWithoutContext('Check that no files in flutter_tools/lib have unused catch variables', () {
    const FileSystem fileSystem = LocalFileSystem();
    final Directory libDir = fileSystem.directory('lib');
    var targetDir = libDir;
    if (!targetDir.existsSync()) {
      targetDir = fileSystem.directory('packages/flutter_tools/lib');
    }
    expect(targetDir.existsSync(), isTrue, reason: 'Could not find flutter_tools/lib directory');

    final List<File> filesToCheck = targetDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .toList();

    final featureSet = FeatureSet.latestLanguageVersion();
    final failures = <String>[];

    for (final file in filesToCheck) {
      final String content = file.readAsStringSync();
      final ParseStringResult parseResult = parseString(
        content: content,
        featureSet: featureSet,
        path: file.path,
      );

      final visitor = CatchClauseVisitor();
      parseResult.unit.accept(visitor);

      for (final String msg in visitor.simplifiedClauses) {
        failures.add('${file.path}: $msg');
      }
    }

    expect(
      failures,
      isEmpty,
      reason:
          'Unused catch variables should be simplified to wildcard catch (_):\n${failures.join('\n')}',
    );
  });
}

class CatchClauseVisitor extends RecursiveAstVisitor<void> {
  final List<String> simplifiedClauses = <String>[];

  @override
  void visitCatchClause(CatchClause node) {
    final CatchClauseParameter? exception = node.exceptionParameter;
    final CatchClauseParameter? stackTrace = node.stackTraceParameter;

    if (exception == null) {
      super.visitCatchClause(node);
      return;
    }

    final String exceptionName = exception.name.lexeme;

    // Check if exception parameter is unused or is a wildcard '_'
    final exceptionIsWildcard = exceptionName == '_';
    final bool exceptionIsUnused =
        exceptionIsWildcard || !IsVariableUsedVisitor.isUsed(node.body, exceptionName);

    var stackTraceIsUnused = true;
    var stackTraceIsWildcard = false;
    String? stackTraceName;
    if (stackTrace != null) {
      stackTraceName = stackTrace.name.lexeme;
      stackTraceIsWildcard = stackTraceName == '_';
      stackTraceIsUnused =
          stackTraceIsWildcard || !IsVariableUsedVisitor.isUsed(node.body, stackTraceName);
    }

    // We can simplify if BOTH are unused.
    if (exceptionIsUnused && stackTraceIsUnused) {
      final bool alreadySimplified =
          exceptionIsWildcard && (stackTrace == null || stackTraceIsWildcard);
      if (!alreadySimplified) {
        simplifiedClauses.add(
          'catch ($exceptionName${stackTraceName != null ? ', $stackTraceName' : ''})',
        );
      }
    }

    super.visitCatchClause(node);
  }
}

class IsVariableUsedVisitor extends RecursiveAstVisitor<void> {
  IsVariableUsedVisitor(this.variableName);

  final String variableName;
  bool hasUsage = false;

  static bool isUsed(AstNode node, String variableName) {
    final visitor = IsVariableUsedVisitor(variableName);
    node.accept(visitor);
    return visitor.hasUsage;
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == variableName) {
      if (!node.inDeclarationContext() && !_isNonUsage(node)) {
        hasUsage = true;
      }
    }
    super.visitSimpleIdentifier(node);
  }

  bool _isNonUsage(SimpleIdentifier node) {
    final AstNode? parent = node.parent;
    if (parent == null) {
      return false;
    }
    if (parent is Label) {
      return true;
    }
    if (parent is ConstructorName && node == parent.name) {
      return true;
    }
    if (parent is PropertyAccess && node == parent.propertyName) {
      return true;
    }
    if (parent is MethodInvocation && node == parent.methodName && parent.target != null) {
      return true;
    }
    if (parent is PrefixedIdentifier && node == parent.identifier) {
      return true;
    }
    if (parent is TypeAnnotation) {
      return true;
    }
    if (parent is Combinator) {
      return true;
    }
    return false;
  }
}
