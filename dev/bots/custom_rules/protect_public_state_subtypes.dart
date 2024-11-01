import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../utils.dart';
import 'analyze.dart';

final AnalyzeRule protectPublicStateSubtypes = _ProtectPublicStateSubtypes();

typedef _AstList = List<(AstNode, String)>;

class _ProtectPublicStateSubtypes implements AnalyzeRule {
  final Map<ResolvedUnitResult, _AstList> _errors = <ResolvedUnitResult, _AstList>{};

  @override
  void applyTo(ResolvedUnitResult unit) {
    final _StateSubclassVisitor visitor = _StateSubclassVisitor();
    unit.unit.visitChildren(visitor);
    final _AstList violationsInUnit = visitor.violationNodes;
    if (violationsInUnit.isNotEmpty) {
      _errors.putIfAbsent(unit, () => <(AstNode, String)>[]).addAll(violationsInUnit);
    }
  }

  @override
  void reportViolations(String workingDirectory) {
    if (_errors.isEmpty) {
      return;
    }

    foundError(
      <String>[
        for (final MapEntry<ResolvedUnitResult, _AstList> entry in _errors.entries)
          for (final (AstNode node, String suggestion) in entry.value)
            '${locationInFile(entry.key, node, workingDirectory)}: $node - $suggestion.',
        '\nPublic State subtypes should add @protected when overriding methods,',
        'to avoid exposing internal logic to developers.',
      ],
    );
  }

  @override
  String toString() => 'Add "@protected" to public State subtypes';
}

class _StateSubclassVisitor extends SimpleAstVisitor<void> {
  final _AstList violationNodes = <(AstNode, String)>[];

  static final Map<InterfaceElement, bool> isStateResultCache = <InterfaceElement, bool>{};

  static bool isState(InterfaceElement element) {
    return element.allSupertypes.any((InterfaceType interface) => _isState(interface.element));
  }

  static bool _isState(InterfaceElement interfaceElement) {
    // Framework naming convention: each State subclass has "State" in its name.
    if (!interfaceElement.name.contains('State')) {
      return false;
    }
    return interfaceElement.name == 'State'
        || isStateResultCache.putIfAbsent(interfaceElement, () => isState(interfaceElement));
  }


  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final ClassElement? classElement = node.declaredElement;
    if (classElement == null) {
      violationNodes.add((node, '[internal error] class element could not be found'));
    } else if (classElement.isPublic && isState(classElement)) {
      node.visitChildren(this);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    switch (node.name.lexeme) {
      case 'initState':
      case 'didUpdateWidget':
      case 'didChangeDependencies':
      case 'reassemble':
      case 'deactivate':
      case 'activate':
      case 'dispose':
      case 'build':
      case 'debugFillProperties':
        switch (node.declaredElement?.hasProtected) {
          case true:
            break;
          case false:
            violationNodes.add((node, 'missing "@protected" annotation'));
          case null:
            violationNodes.add((node, '[internal error] method element could not be found'));
        }
    }
  }
}
