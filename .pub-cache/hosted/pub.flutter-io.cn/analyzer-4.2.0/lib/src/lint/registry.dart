// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/linter.dart';

/// Registry of lint rules.
class Registry with IterableMixin<LintRule> {
  /// The default registry to be used by clients.
  static final Registry ruleRegistry = Registry();

  /// A table mapping rule names to rules.
  final Map<String, LintRule> _ruleMap = {};

  /// A table mapping unique names to lint codes.
  final Map<String, LintCode> _codeMap = {};

  @override
  Iterator<LintRule> get iterator => _ruleMap.values.iterator;

  /// Return a list of the rules that are defined.
  Iterable<LintRule> get rules => _ruleMap.values;

  /// Return the lint rule with the given [name].
  LintRule? operator [](String name) => _ruleMap[name];

  /// Return the lint code that has the given [uniqueName].
  LintCode? codeForUniqueName(String uniqueName) => _codeMap[uniqueName];

  /// Return a list of the lint rules explicitly enabled by the given [config].
  ///
  /// For example:
  ///     my_rule: true
  ///
  /// enables `my_rule`.
  ///
  /// Unspecified rules are treated as disabled by default.
  Iterable<LintRule> enabled(LintConfig config) => rules
      .where((rule) => config.ruleConfigs.any((rc) => rc.enables(rule.name)));

  /// Return the lint rule with the given [name].
  LintRule? getRule(String name) => _ruleMap[name];

  /// Add the given lint [rule] to this registry.
  void register(LintRule rule) {
    _ruleMap[rule.name] = rule;
    for (var lintCode in rule.lintCodes) {
      _codeMap[lintCode.uniqueName] = lintCode;
    }
  }
}
