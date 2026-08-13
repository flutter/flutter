// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:path/path.dart' as path;

/// Checks for bad imports in `package:flutter`.
///
/// Restricts `package:meta/meta.dart` imports within `lib/src/` (excluding
/// `src/foundation/`), prevents recursive self-imports, validates that only
/// valid exports are imported, and enforces Flutter's architectural layer
/// dependency hierarchy.
class NoBadImportsInFlutter extends AnalysisRule {
  NoBadImportsInFlutter()
    : super(name: code.name, description: 'Checks for bad imports in flutter package.');

  static const LintCode code = LintCode(
    'no_bad_imports_in_flutter',
    'Bad import in flutter package.',
    correctionMessage:
        'Use relative imports or valid exported packages conforming to the layer hierarchy. Do not import package:meta/meta.dart outside of foundation.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  static const Set<String> _knownLayers = <String>{
    'animation',
    'cupertino',
    'foundation',
    'gestures',
    'material',
    'painting',
    'physics',
    'rendering',
    'scheduler',
    'semantics',
    'services',
    'widget_previews',
    'widgets',
  };

  static const Map<String, Set<String>> _allowedLayerDependencies = <String, Set<String>>{
    'foundation': <String>{},
    'physics': <String>{'foundation'},
    'scheduler': <String>{'foundation'},
    'animation': <String>{'foundation', 'physics', 'scheduler'},
    'gestures': <String>{'foundation', 'scheduler'},
    'services': <String>{'foundation', 'scheduler', 'gestures'},
    'painting': <String>{'foundation', 'animation', 'gestures', 'services'},
    'semantics': <String>{'foundation', 'gestures', 'painting', 'services'},
    'rendering': <String>{
      'animation',
      'foundation',
      'gestures',
      'painting',
      'physics',
      'scheduler',
      'semantics',
      'services',
    },
    'widgets': <String>{
      'animation',
      'foundation',
      'gestures',
      'painting',
      'physics',
      'rendering',
      'scheduler',
      'semantics',
      'services',
    },
    'cupertino': <String>{
      'animation',
      'foundation',
      'gestures',
      'painting',
      'physics',
      'rendering',
      'scheduler',
      'semantics',
      'services',
      'widgets',
    },
    'material': <String>{
      'animation',
      'cupertino',
      'foundation',
      'gestures',
      'painting',
      'physics',
      'rendering',
      'scheduler',
      'semantics',
      'services',
      'widgets',
    },
    'widget_previews': <String>{
      'animation',
      'cupertino',
      'foundation',
      'gestures',
      'material',
      'painting',
      'physics',
      'rendering',
      'scheduler',
      'semantics',
      'services',
      'widgets',
    },
  };

  @override
  void visitImportDirective(ImportDirective node) {
    if (node.uri.stringValue case final String uriStr) {
      final String? absolutePath = context.currentUnit?.unit.declaredFragment?.source.fullName;
      if (absolutePath == null) {
        return;
      }

      final bool isFlutterSrc =
          absolutePath.contains('packages/flutter/lib/src/') ||
          absolutePath.contains(r'packages\flutter\lib\src\');
      if (!isFlutterSrc) {
        return;
      }

      if (uriStr == 'package:meta/meta.dart') {
        final bool isFoundation =
            absolutePath.contains('src/foundation/') || absolutePath.contains(r'src\foundation\');
        if (!isFoundation) {
          rule.reportAtNode(node.uri);
        }
        return;
      }

      final List<String> pathParts = path.split(absolutePath);
      final int srcIndex = pathParts.lastIndexOf('src');
      if (srcIndex != -1 && srcIndex + 1 < pathParts.length) {
        final String currentLayer = pathParts[srcIndex + 1];

        if (uriStr == 'package:flutter/$currentLayer.dart') {
          rule.reportAtNode(node.uri);
          return;
        }

        if (uriStr.startsWith('package:flutter/')) {
          final String importSubPath = uriStr.substring('package:flutter/'.length);
          if (importSubPath.endsWith('.dart') && !importSubPath.contains('/')) {
            final String importedLayer = importSubPath.substring(
              0,
              importSubPath.length - '.dart'.length,
            );
            if (!_knownLayers.contains(importedLayer)) {
              rule.reportAtNode(node.uri);
              return;
            }

            final Set<String>? allowed = _allowedLayerDependencies[currentLayer];
            if (allowed != null && !allowed.contains(importedLayer)) {
              rule.reportAtNode(node.uri);
              return;
            }
          }
        }
      }
    }
  }
}
