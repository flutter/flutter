// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:path/path.dart' as path;

// The comment pattern representing the "flutter_ignore" inline directive that
// indicates the line should be exempt from the stopwatch check.
final Pattern _ignoreStopwatch = RegExp(r'// flutter_ignore: .*stopwatch .*\(see analyze\.dart\)');

/// Use of Stopwatches can introduce test flakes as the logical time of a
/// stopwatch can fall out of sync with the mocked time of FakeAsync in testing.
/// The Clock object provides a safe stopwatch instead, which is paired with
/// FakeAsync as part of the test binding.
class NoStopwatches extends AnalysisRule {
  NoStopwatches() : super(name: code.name, description: ruleDescription);

  static const String ruleDescription =
      'Use of Stopwatches can introduce test flakes as the logical time of a stopwatch can fall '
      'out of sync with the mocked time of FakeAsync in testing.';

  static const LintCode code = LintCode(
    'no_stopwatches',
    ruleDescription,
    correctionMessage: 'Use clock.stopwatch() from package:clock instead.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final _Visitor visitor = _Visitor(this, context);
    registry
      ..addConstructorName(this, visitor)
      ..addSimpleIdentifier(this, visitor);
  }
}

// This visitor finds invocation sites of Stopwatch (and subclasses) constructors
// and references to "external" functions that return a Stopwatch (and subclasses),
// including constructors.
class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  final Map<ClassElement, bool> _isStopwatchClassElementCache = <ClassElement, bool>{};

  bool _checkIfImplementsStopwatchRecursively(ClassElement classElement) {
    if (classElement.library.isDartCore) {
      return classElement.name == 'Stopwatch';
    }
    return classElement.allSupertypes.any((InterfaceType interface) {
      final InterfaceElement interfaceElement = interface.element;
      return interfaceElement is ClassElement && _implementsStopwatch(interfaceElement);
    });
  }

  // The cached version, call this method instead of _checkIfImplementsStopwatchRecursively.
  bool _implementsStopwatch(ClassElement classElement) {
    return classElement.library.isDartCore
        ? classElement.name == 'Stopwatch'
        : _isStopwatchClassElementCache.putIfAbsent(
          classElement,
          () => _checkIfImplementsStopwatchRecursively(classElement),
        );
  }

  bool _isInternal(LibraryElement libraryElement) {
    return path.isWithin(
      libraryElement.session.analysisContext.contextRoot.root.path,
      libraryElement.firstFragment.source.fullName,
    );
  }

  bool _hasTrailingFlutterIgnore(AstNode node) {
    return context.currentUnit!.content
        .substring(
          node.offset + node.length,
          context.currentUnit!.unit.lineInfo.getOffsetOfLineAfter(node.offset + node.length),
        )
        .contains(_ignoreStopwatch);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    final ConstructorElement element = node.element!;
    final bool isAllowed = switch (element.returnType) {
      InterfaceType(element: final ClassElement classElement) =>
        !_implementsStopwatch(classElement),
      InterfaceType(element: InterfaceElement()) => true,
    };
    if (isAllowed || _hasTrailingFlutterIgnore(node)) {
      return;
    }
    rule.reportAtNode(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final bool isAllowed = switch (node.element) {
      ExecutableElement(
        returnType: DartType(element: final ClassElement classElement),
        library: final LibraryElement libraryElement,
      )
          // Don't double report constructors and factories.
          when node.element is! ConstructorElement =>
        _isInternal(libraryElement) || !_implementsStopwatch(classElement),
      Element() || null => true,
    };
    if (isAllowed || _hasTrailingFlutterIgnore(node)) {
      return;
    }
    rule.reportAtNode(node);
  }
}
