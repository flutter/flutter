// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'type_analyzer.dart';

/// Data structure for tracking declared pattern variables.
///
/// To analyze a single `case pattern when guard`:
/// 1. Invoke [casePatternStart].
/// 2. Invoke zero or more [add].
/// 3. Invoke [casePatternFinish], get the set of variables `VS`.
/// 4. Use `VS` to analyze the guard.
///
/// To analyze a group of `case` members of a `switch` statement, sharing
/// the same body, and so having the shared set of pattern variables:
/// 1. Invoke [switchStatementSharedCaseScopeStart].
/// 2. Analyze individual `case pattern when guard` clauses.
/// 3. Invoke [switchStatementSharedCaseScopeEmpty] if there are labels,
///    or a `default` member.
/// 4. Invoke [switchStatementSharedCaseScopeFinish] to get the set of
///    variables `VS`, and use it to analyze the shared body.
abstract class VariableBinder<Node extends Object, Variable extends Object> {
  /// The interface for reporting error conditions up to the client.
  final VariableBinderErrors<Node, Variable>? errors;

  /// The stack of variable sets, starting with an empty one on
  /// [casePatternStart], or [logicalOrPatternStart].
  List<Map<String, Variable>> _variables = [];

  /// The stack of variable sets for potentially nested (e.g. `switch` in
  /// a closure in a `when` clause) groups of `case` members of a `switch`
  /// statement.
  List<_SharedCaseScope<Variable>> _sharedCaseScopes = [];

  VariableBinder({
    required this.errors,
  });

  /// Updates the set of bindings to account for the presence of a variable
  /// pattern.  [name] is the name of the variable, [variable] is the object
  /// that represents it in the client.
  bool add(String name, Variable variable) {
    Variable? existing = _variables.last[name];
    if (existing == null) {
      _variables.last[name] = variable;
      return true;
    } else {
      errors?.duplicateVariablePattern(
        name: name,
        original: existing,
        duplicate: variable,
      );
      return false;
    }
  }

  /// Should be invoked after visiting a `case pattern` structure.  Returns
  /// all the accumulated variables (individual and joined).
  ///
  /// If [sharedCaseScopeKey] is provided, it expected to be the same as
  /// the key of the last shared case scope, and the resulting set will be
  /// joined with the current shared case scope.
  Map<String, Variable> casePatternFinish({
    Object? sharedCaseScopeKey,
  }) {
    Map<String, Variable> variables = _variables.removeLast();

    if (sharedCaseScopeKey != null) {
      _SharedCaseScope<Variable> sharedScope = _sharedCaseScopes.last;
      assert(sharedScope.key == sharedCaseScopeKey);
      sharedScope.addAll(variables);
    }

    return variables;
  }

  /// Notifies that are new `case pattern` structure is about to be visited.
  void casePatternStart() {
    _variables.add({});
  }

  /// Notifies that this instance is about to be discarded.
  void finish() {
    assert(_variables.isEmpty);
    assert(_sharedCaseScopes.isEmpty);
  }

  /// Returns a new variable that is a join of [components].
  Variable joinPatternVariables({
    required Object key,
    required List<Variable> components,
    required bool isConsistent,
  });

  /// Updates the binder after visiting a logical-or pattern, joins variables
  /// from them.  If some variables are in one side of the pattern, but not
  /// in another, they are still joined, but marked as not consistent.
  void logicalOrPatternFinish(Node node) {
    Map<String, Variable> right = _variables.removeLast();
    Map<String, Variable> left = _variables.removeLast();
    for (MapEntry<String, Variable> leftEntry in left.entries) {
      String name = leftEntry.key;
      Variable leftVariable = leftEntry.value;
      Variable? rightVariable = right.remove(name);
      if (rightVariable != null) {
        add(
          name,
          joinPatternVariables(
            key: node,
            components: [leftVariable, rightVariable],
            isConsistent: true,
          ),
        );
      } else {
        errors?.logicalOrPatternBranchMissingVariable(
          node: node,
          hasInLeft: true,
          name: name,
          variable: leftVariable,
        );
        add(
          name,
          joinPatternVariables(
            key: node,
            components: [leftVariable],
            isConsistent: false,
          ),
        );
      }
    }
    for (MapEntry<String, Variable> rightEntry in right.entries) {
      String name = rightEntry.key;
      Variable rightVariable = rightEntry.value;
      errors?.logicalOrPatternBranchMissingVariable(
        node: node,
        hasInLeft: false,
        name: name,
        variable: rightVariable,
      );
      add(
        name,
        joinPatternVariables(
          key: node,
          components: [rightVariable],
          isConsistent: false,
        ),
      );
    }
  }

  /// Notifies that the LHS of a logical-or pattern was visited, and the RHS
  /// is about to be visited.
  void logicalOrPatternFinishLeft() {
    _variables.add({});
  }

  /// Notifies that we are about to start visiting a logical-or pattern.
  void logicalOrPatternStart() {
    _variables.add({});
  }

  /// Notifies that the `default` case head, or a label, was found, so that
  /// all the variables of the current shared case scope are not consistent.
  void switchStatementSharedCaseScopeEmpty(Object key) {
    _SharedCaseScope<Variable> sharedScope = _sharedCaseScopes.last;
    assert(sharedScope.key == key);
    sharedScope.addAll({});
  }

  /// Notifies that computing of the shared case scope was finished, returns
  /// the joined set of variables.  The variables have not been checked to
  /// have the same types (because we have not done inference, so we don't
  /// know types for many of them), so some of them might become not
  /// consistent later.
  Map<String, Variable> switchStatementSharedCaseScopeFinish(Object key) {
    assert(_variables.isEmpty);
    _SharedCaseScope<Variable> sharedScope = _sharedCaseScopes.removeLast();
    assert(sharedScope.key == key);

    Map<String, Variable> result = {};
    for (MapEntry<String, _SharedCaseScopeVariable<Variable>> entry
        in sharedScope.variables.entries) {
      _SharedCaseScopeVariable<Variable> sharedVariable = entry.value;
      List<Variable> variables = sharedVariable.variables;
      if (sharedVariable.isConsistent && variables.length == 1) {
        result[entry.key] = variables[0];
      } else {
        result[entry.key] = joinPatternVariables(
          key: key,
          components: variables,
          isConsistent: sharedVariable.isConsistent,
        );
      }
    }
    return result;
  }

  /// Notifies that computing new shared case scope should be started.
  void switchStatementSharedCaseScopeStart(Object key) {
    assert(_variables.isEmpty);
    _sharedCaseScopes.add(
      new _SharedCaseScope(key),
    );
  }
}

/// Interface used by the [VariableBinder] logic to report error conditions
/// up to the client during the "pre-visit" phase of type analysis.
abstract class VariableBinderErrors<Node extends Object,
    Variable extends Object> extends TypeAnalyzerErrorsBase {
  /// Called when a pattern attempts to declare the variable [duplicate] that
  /// has the same [name] as the [original] variable.
  void duplicateVariablePattern({
    required String name,
    required Variable original,
    required Variable duplicate,
  });

  /// Called when one of the branches has the [variable] with the [name], but
  /// the other branch does not.
  void logicalOrPatternBranchMissingVariable({
    required Node node,
    required bool hasInLeft,
    required String name,
    required Variable variable,
  });
}

class _SharedCaseScope<Variable extends Object> {
  final Object key;
  bool isEmpty = true;
  Map<String, _SharedCaseScopeVariable<Variable>> variables = {};

  _SharedCaseScope(this.key);

  /// Adds [newVariables] to [variables], marking absent variables as not
  /// consistent. If [isEmpty], just sets given variables as the starting set.
  void addAll(Map<String, Variable> newVariables) {
    if (isEmpty) {
      isEmpty = false;
      for (MapEntry<String, Variable> entry in newVariables.entries) {
        String name = entry.key;
        Variable variable = entry.value;
        _getVariable(name).variables.add(variable);
      }
    } else {
      for (MapEntry<String, _SharedCaseScopeVariable<Variable>> entry
          in variables.entries) {
        String name = entry.key;
        _SharedCaseScopeVariable<Variable> variable = entry.value;
        Variable? newVariable = newVariables[name];
        if (newVariable != null) {
          variable.variables.add(newVariable);
        } else {
          variable.isConsistent = false;
        }
      }
      for (MapEntry<String, Variable> newEntry in newVariables.entries) {
        String name = newEntry.key;
        Variable newVariable = newEntry.value;
        if (!variables.containsKey(name)) {
          _getVariable(name)
            ..isConsistent = false
            ..variables.add(newVariable);
        }
      }
    }
  }

  _SharedCaseScopeVariable _getVariable(String name) {
    return variables[name] ??= new _SharedCaseScopeVariable();
  }
}

class _SharedCaseScopeVariable<Variable extends Object> {
  bool isConsistent = true;
  final List<Variable> variables = [];
}
