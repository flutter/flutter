// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'argument.dart';
import 'rule.dart';

/// Rule for handling splits between parameter metadata annotations and the
/// following parameter.
///
/// Metadata annotations for parameters (and type parameters) get some special
/// handling. We use a single rule for all annotations in the parameter list.
/// If any of the annotations split, they all do.
///
/// Also, if the annotations split, we force the entire parameter list to fully
/// split, both named and positional.
class MetadataRule extends Rule {
  Rule? _positionalRule;
  Rule? _namedRule;

  /// Remembers that [rule] is the [PositionalRule] used by the argument list
  /// containing the parameter metadata using this rule.
  void bindPositionalRule(PositionalRule rule) {
    _positionalRule = rule;
  }

  /// Remembers that [rule] is the [NamedRule] used by the argument list
  /// containing the parameter metadata using this rule.
  void bindNamedRule(NamedRule rule) {
    _namedRule = rule;
  }

  /// Constrains the surrounding argument list rules to fully split if the
  /// metadata does.
  @override
  int? constrain(int value, Rule other) {
    var constrained = super.constrain(value, other);
    if (constrained != null) return constrained;

    // If the metadata doesn't split, we don't care what the arguments do.
    if (value == Rule.unsplit) return null;

    // Otherwise, they have to split.
    if (other == _positionalRule) return _positionalRule!.fullySplitValue;
    if (other == _namedRule) return _namedRule!.fullySplitValue;

    return null;
  }

  @override
  void addConstrainedRules(Set<Rule> rules) {
    if (_positionalRule != null) rules.add(_positionalRule!);
    if (_namedRule != null) rules.add(_namedRule!);
  }

  @override
  void forgetUnusedRules() {
    super.forgetUnusedRules();
    if (_positionalRule?.index == null) _positionalRule = null;
    if (_namedRule?.index == null) _namedRule = null;
  }
}
