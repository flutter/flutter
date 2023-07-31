// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../chunk.dart';
import '../constants.dart';
import '../fast_hash.dart';

/// A constraint that determines the different ways a related set of chunks may
/// be split.
class Rule extends FastHash {
  /// The rule used for dummy chunks.
  static final Rule dummy = Rule.hard();

  /// Rule value that splits no chunks.
  ///
  /// Every rule is required to treat this value as fully unsplit.
  static const unsplit = 0;

  /// Rule constraint value that means "any value as long as something splits".
  ///
  /// It disallows [unsplit] but allows any other value.
  static const mustSplit = -1;

  /// Rule constraint that means the rule must split to its fully split value.
  ///
  /// This is used instead of the actual full split value because at the point
  /// that the constraint is added, the Rule may not have all of the chunks it
  /// needs to correctly calculate [numValues].
  static const _fullSplitConstraint = -2;

  /// The number of different states this rule can be in.
  ///
  /// Each state determines which set of chunks using this rule are split and
  /// which aren't. Values range from zero to one minus this. Value zero
  /// always means "no chunks are split" and increasing values by convention
  /// mean increasingly undesirable splits.
  ///
  /// By default, a rule has two values: fully unsplit and fully split.
  int get numValues => 2;

  /// The rule value that forces this rule into its maximally split state.
  ///
  /// By convention, this is the highest of the range of allowed values.
  int get fullySplitValue => numValues - 1;

  int get cost => _cost;
  final int _cost;

  /// During line splitting [LineSplitter] sets this to the index of this
  /// rule in its list of rules.
  int? index;

  /// If `true`, the rule has been "hardened" meaning it's been placed into a
  /// permanent "must fully split" state.
  bool get isHardened => _isHardened;
  bool _isHardened = false;

  /// The constraints that this rule implies about other rule values.
  ///
  /// In many cases, if a split occurs inside an expression, surrounding rules
  /// also want to split too. For example, a split in the middle of an argument
  /// forces the entire argument list to also split.
  ///
  /// Also, there are sometimes more bespoke constraints between rules. For
  /// example, positional and named arguments in an argument list each have
  /// their own rules, but the way the positional arguments split restricts the
  /// way the named rules are allowed to split.
  ///
  /// This tracks those relationships. Each key is a rule whose values can be
  /// constrained by this rule. The entry values are a list of [_Constraint]
  /// objects. Each specifies that when this rule has a value within a certain
  /// range, the constrained rule's value must be a certain given value.
  final Map<Rule, List<_Constraint>> _constraints = {};

  /// Whether this rule cares about rules that it contains.
  ///
  /// If `true` then inner rules will constrain this one and force it to split
  /// when they split. Otherwise, it can split independently of any contained
  /// rules.
  bool get splitsOnInnerRules => true;

  Rule([this._cost = Cost.normal]);

  /// Creates a new rule that is already fully split.
  Rule.hard() : _cost = 0 {
    // Set the cost to zero since it will always be applied, so there's no
    // point in penalizing it.
    //
    // Also, this avoids doubled counting in literal blocks where there is both
    // a split in the outer chunk containing the block and the inner hard split
    // between the elements or statements.
    harden();
  }

  /// Fixes this rule into a "fully split" state.
  void harden() {
    _isHardened = true;
  }

  /// Returns `true` if [chunk] should split when this rule has [value].
  bool isSplit(int value, Chunk chunk) {
    if (_isHardened) return true;

    if (value == Rule.unsplit) return false;

    // Let the subclass decide.
    return isSplitAtValue(value, chunk);
  }

  /// Subclasses can override this to determine which values split which chunks.
  ///
  /// By default, this assumes every chunk splits.
  bool isSplitAtValue(int value, Chunk chunk) => true;

  /// Given that this rule has [value], determine if [other]'s value should be
  /// constrained.
  ///
  /// Allows relationships between rules like "if I split, then this should
  /// split too". Returns a non-negative value to force [other] to take that
  /// value. Returns -1 to allow [other] to take any non-zero value. Returns
  /// `null` to not constrain other.
  int? constrain(int value, Rule other) {
    // By default, any containing rule will be fully split if this one is split.
    if (value == Rule.unsplit) return null;

    var constrained = _constraints[other];
    if (constrained == null) return null;

    for (var constraint in constrained) {
      if (value >= constraint.min && value <= constraint.max) {
        if (constraint.otherValue == _fullSplitConstraint) {
          return other.fullySplitValue;
        }

        return constraint.otherValue;
      }
    }

    return null;
  }

  /// When this rule has [value], constrains [other] to [otherValue].
  void addConstraint(int value, Rule other, int otherValue) {
    addRangeConstraint(value, value, other, otherValue);
  }

  /// When this rule's value is between [min] and [max] (inclusive), constrains
  /// [other] to [otherValue].
  void addRangeConstraint(int min, int max, Rule other, int otherValue) {
    _constraints
        .putIfAbsent(other, () => [])
        .add(_Constraint(min, max, otherValue));
  }

  /// Constrains [other] to its fully split value when this rule is split in
  /// any way.
  void constrainWhenSplit(Rule other) {
    // We want the constraint to apply to any non-zero value, so use an
    // arbitrary but sufficiently large number.
    addRangeConstraint(1, 100000, other, _fullSplitConstraint);
  }

  /// Constrains [other] to its fully split value when this rule is fully split.
  void constrainWhenFullySplit(Rule other) {
    addConstraint(fullySplitValue, other, _fullSplitConstraint);
  }

  /// Discards constraints on any rule that doesn't have an index.
  ///
  /// This is called by [LineSplitter] after it has indexed all of the in-use
  /// rules. A rule may end up with a constraint on a rule that's no longer
  /// used by any chunk. This can happen if the rule gets hardened, or if it
  /// simply never got used by a chunk. For example, a rule for splitting an
  /// empty list of metadata annotations.
  ///
  /// This removes all of those.
  void forgetUnusedRules() {
    _constraints.removeWhere((rule, _) => rule.index == null);

    // Clear the cached ones too.
    _allConstrainedRules = null;
  }

  /// The other [Rule]s that this rule places immediate constraints on.
  Iterable<Rule> get constrainedRules => _constraints.keys;

  /// The transitive closure of all of the rules this rule places constraints
  /// on, directly or indirectly, including itself.
  Set<Rule> get allConstrainedRules {
    var rules = _allConstrainedRules;
    if (rules != null) return rules;

    rules = {};
    _traverseConstraints(rules, this);
    _allConstrainedRules = rules;
    return rules;
  }

  /// Traverses the constraint graph of [rule] adding everything to [rules].
  void _traverseConstraints(Set<Rule> rules, Rule rule) {
    if (rules.contains(rule)) return;

    rules.add(rule);
    for (var rule in rule.constrainedRules) {
      _traverseConstraints(rules, rule);
    }
  }

  Set<Rule>? _allConstrainedRules;

  @override
  String toString() => '$id';
}

/// Describes a value constraint that one [Rule] places on another rule's
/// values.
///
/// If the first rule's selected value is within [min], [max] (inclusive), then
/// the other rule's value is forced to be [otherValue].
class _Constraint {
  /// The minimum of the range of values that rule can have to enable the
  /// constraint.
  final int min;

  /// The maximum of the range of values that rule can have to enable the
  /// constraint.
  final int max;

  /// When this constraint applies, then this is the value the other rule must
  /// have.
  ///
  /// If this is [_fullSplitConstraint], then forces the other rule to its
  /// fully split value. We don't just eagerly store the fully split value in
  /// here because some rules incrementally build the list of Chunks that are
  /// used to determine the the number of values the rule can take and thus its
  /// fully split value isn't known when the rule is created and its
  /// constraints are wired up. In particular, when using [TypeArgumentRule]
  /// for the elements in a collection literal with comments used to control
  /// splitting, it's not easy to eagerly calculate the number of values each
  /// rule will end up having.
  final int otherValue;

  _Constraint(this.min, this.max, this.otherValue);
}
