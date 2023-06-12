// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../parser.dart';

/// CSS polyfill emits CSS to be understood by older parsers that which do not
/// understand (var, calc, etc.).
class PolyFill {
  final Messages _messages;
  Map<String, VarDefinition> _allVarDefinitions = <String, VarDefinition>{};

  Set<StyleSheet> allStyleSheets = <StyleSheet>{};

  /// [_pseudoElements] list of known pseudo attributes found in HTML, any
  /// CSS pseudo-elements 'name::custom-element' is mapped to the manged name
  /// associated with the pseudo-element key.
  PolyFill(this._messages);

  /// Run the analyzer on every file that is a style sheet or any component that
  /// has a style tag.
  void process(StyleSheet styleSheet, {List<StyleSheet>? includes}) {
    if (includes != null) {
      processVarDefinitions(includes);
    }
    processVars(styleSheet);

    // Remove all var definitions for this style sheet.
    _RemoveVarDefinitions().visitTree(styleSheet);
  }

  /// Process all includes looking for var definitions.
  void processVarDefinitions(List<StyleSheet> includes) {
    for (var include in includes) {
      _allVarDefinitions = (_VarDefinitionsIncludes(_allVarDefinitions)
            ..visitTree(include))
          .varDefs;
    }
  }

  void processVars(StyleSheet styleSheet) {
    // Build list of all var definitions.
    var mainStyleSheetVarDefs = (_VarDefAndUsage(_messages, _allVarDefinitions)
          ..visitTree(styleSheet))
        .varDefs;

    // Resolve all definitions to a non-VarUsage (terminal expression).
    mainStyleSheetVarDefs.forEach((key, value) {
      for (var _ in (value.expression as Expressions).expressions) {
        mainStyleSheetVarDefs[key] =
            _findTerminalVarDefinition(_allVarDefinitions, value);
      }
    });
  }
}

/// Build list of all var definitions in all includes.
class _VarDefinitionsIncludes extends Visitor {
  final Map<String, VarDefinition> varDefs;

  _VarDefinitionsIncludes(this.varDefs);

  @override
  void visitTree(StyleSheet tree) {
    visitStyleSheet(tree);
  }

  @override
  void visitVarDefinition(VarDefinition node) {
    // Replace with latest variable definition.
    varDefs[node.definedName] = node;
    super.visitVarDefinition(node);
  }

  @override
  void visitVarDefinitionDirective(VarDefinitionDirective node) {
    visitVarDefinition(node.def);
  }
}

/// Find var- definitions in a style sheet.
/// [found] list of known definitions.
class _VarDefAndUsage extends Visitor {
  final Messages _messages;
  final Map<String, VarDefinition> _knownVarDefs;
  final varDefs = <String, VarDefinition>{};

  VarDefinition? currVarDefinition;
  List<Expression>? currentExpressions;

  _VarDefAndUsage(this._messages, this._knownVarDefs);

  @override
  void visitTree(StyleSheet tree) {
    visitStyleSheet(tree);
  }

  @override
  void visitVarDefinition(VarDefinition node) {
    // Replace with latest variable definition.
    currVarDefinition = node;

    _knownVarDefs[node.definedName] = node;
    varDefs[node.definedName] = node;

    super.visitVarDefinition(node);

    currVarDefinition = null;
  }

  @override
  void visitVarDefinitionDirective(VarDefinitionDirective node) {
    visitVarDefinition(node.def);
  }

  @override
  void visitExpressions(Expressions node) {
    currentExpressions = node.expressions;
    super.visitExpressions(node);
    currentExpressions = null;
  }

  @override
  void visitVarUsage(VarUsage node) {
    if (currVarDefinition != null && currVarDefinition!.badUsage) return;

    // Don't process other var() inside of a varUsage.  That implies that the
    // default is a var() too.  Also, don't process any var() inside of a
    // varDefinition (they're just place holders until we've resolved all real
    // usages.
    var expressions = currentExpressions;
    var index = expressions!.indexOf(node);
    assert(index >= 0);
    var def = _knownVarDefs[node.name];
    if (def != null) {
      if (def.badUsage) {
        // Remove any expressions pointing to a bad var definition.
        expressions.removeAt(index);
        return;
      }
      _resolveVarUsage(currentExpressions!, index,
          _findTerminalVarDefinition(_knownVarDefs, def));
    } else if (node.defaultValues.any((e) => e is VarUsage)) {
      // Don't have a VarDefinition need to use default values resolve all
      // default values.
      var terminalDefaults = <Expression>[];
      for (var defaultValue in node.defaultValues) {
        terminalDefaults.addAll(resolveUsageTerminal(defaultValue as VarUsage));
      }
      expressions.replaceRange(index, index + 1, terminalDefaults);
    } else if (node.defaultValues.isNotEmpty) {
      // No VarDefinition but default value is a terminal expression; use it.
      expressions.replaceRange(index, index + 1, node.defaultValues);
    } else {
      if (currVarDefinition != null) {
        currVarDefinition!.badUsage = true;
        var mainStyleSheetDef = varDefs[node.name];
        if (mainStyleSheetDef != null) {
          varDefs.remove(currVarDefinition!.property);
        }
      }
      // Remove var usage that points at an undefined definition.
      expressions.removeAt(index);
      _messages.warning('Variable is not defined.', node.span);
    }

    var oldExpressions = currentExpressions;
    currentExpressions = node.defaultValues;
    super.visitVarUsage(node);
    currentExpressions = oldExpressions;
  }

  List<Expression> resolveUsageTerminal(VarUsage usage) {
    var result = <Expression>[];

    var varDef = _knownVarDefs[usage.name];
    List<Expression> expressions;
    if (varDef == null) {
      // VarDefinition not found try the defaultValues.
      expressions = usage.defaultValues;
    } else {
      // Use the VarDefinition found.
      expressions = (varDef.expression as Expressions).expressions;
    }

    for (var expr in expressions) {
      if (expr is VarUsage) {
        // Get terminal value.
        result.addAll(resolveUsageTerminal(expr));
      }
    }

    // We're at a terminal just return the VarDefinition expression.
    if (result.isEmpty && varDef != null) {
      result = (varDef.expression as Expressions).expressions;
    }

    return result;
  }

  void _resolveVarUsage(
      List<Expression> expressions, int index, VarDefinition def) {
    var defExpressions = (def.expression as Expressions).expressions;
    expressions.replaceRange(index, index + 1, defExpressions);
  }
}

/// Remove all var definitions.
class _RemoveVarDefinitions extends Visitor {
  @override
  void visitTree(StyleSheet tree) {
    visitStyleSheet(tree);
  }

  @override
  void visitStyleSheet(StyleSheet ss) {
    ss.topLevels.removeWhere((e) => e is VarDefinitionDirective);
    super.visitStyleSheet(ss);
  }

  @override
  void visitDeclarationGroup(DeclarationGroup node) {
    node.declarations.removeWhere((e) => e is VarDefinition);
    super.visitDeclarationGroup(node);
  }
}

/// Find terminal definition (non VarUsage implies real CSS value).
VarDefinition _findTerminalVarDefinition(
    Map<String, VarDefinition> varDefs, VarDefinition varDef) {
  var expressions = varDef.expression as Expressions;
  for (var expr in expressions.expressions) {
    if (expr is VarUsage) {
      var usageName = expr.name;
      var foundDef = varDefs[usageName];

      // If foundDef is unknown check if defaultValues; if it exist then resolve
      // to terminal value.
      if (foundDef == null) {
        // We're either a VarUsage or terminal definition if in varDefs;
        // either way replace VarUsage with it's default value because the
        // VarDefinition isn't found.
        var defaultValues = expr.defaultValues;
        var replaceExprs = expressions.expressions;
        assert(replaceExprs.length == 1);
        replaceExprs.replaceRange(0, 1, defaultValues);
        return varDef;
      }
      return _findTerminalVarDefinition(varDefs, foundDef);
    } else {
      // Return real CSS property.
      return varDef;
    }
  }

  // Didn't point to a var definition that existed.
  return varDef;
}
