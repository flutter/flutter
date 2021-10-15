// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Parses the Dart entrypoints defined in the given content file.
///
/// An entrypoint is either a top level main function or a function with a
/// @pragma('vm:entry-point') annotation.
///
/// Returns a map where the key is the entrypoint name and the value is the pragma
/// annotation value.
Map<String, String> getDartEntrypoints(String content) {
  final ParseStringResult parseResult = parseString(
    featureSet: FeatureSet.latestLanguageVersion(),
    content: content,
  );
  final _EntrypointVisitor<CompilationUnit> visitor = _EntrypointVisitor<CompilationUnit>(parseResult);
  visitor.visitCompilationUnit(parseResult.unit);
  return visitor.entrypoints;
}

class _EntrypointVisitor<T> extends RecursiveAstVisitor<T> {
  _EntrypointVisitor(this.parseResult) : entrypoints = <String, String>{};

  final ParseStringResult parseResult;
  /// Maps entrypoint names to the pragma annotation.
  final Map<String, String> entrypoints;

  @override
  T? visitAnnotation(Annotation node) {
    if (node.parent.parent == node.root &&
        node.name.name == 'pragma' &&
        node.arguments != null &&
        node.arguments!.arguments.first.toString().substring(1, 15) == 'vm:entry-point') {

      Token? currToken =  node.endToken.next;
      while (currToken != null) {
        final String maybeReturnExpression = currToken.toString();
        if (maybeReturnExpression != '@' && currToken.next != null && currToken.next!.isIdentifier) {
          final String entrypointName = currToken.next!.toString();
          entrypoints[entrypointName] = node.arguments!.toString();
          break;
        }
        currToken = currToken.next;
      }
    }
    return super.visitAnnotation(node);
  }

  @override
  T? visitFunctionDeclaration(FunctionDeclaration node) {
    // The main function doesn't need a vm:entry-point annotation.
    if (node.parent == node.root && node.name.name == 'main' && !entrypoints.containsKey('main')) {
      entrypoints['main'] = "('vm:entry-point')";
    }
    return super.visitFunctionDeclaration(node);
  }
}
