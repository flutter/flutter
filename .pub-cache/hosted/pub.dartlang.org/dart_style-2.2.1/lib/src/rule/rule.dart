// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../chunk.dart';
import '../fast_hash.dart';

/// A constraint that determines the different ways a related set of chunks may
/// be split.
class Rule extends FastHash {
  /// Rule value that splits no chunks.
  ///
  /// Every rule is required to treat this value as fully unsplit.
  static const unsplit = 0;

  /// Rule constraint value that means "any value as long as something splits".
  ///
  /// It disallows [unsplit] but allows any other value.
  static const mustSplit = -1;

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

  /// The other [Rule]s that are implied this one.
  ///
  /// In many cases, if a split occurs inside an expression, surrounding rules
  /// also want to split too. For example, a split in the middle of an argument
  /// forces the entire argument list to also split.
  ///
  /// This tracks those relationships. If this rule splits, (sets its value to
  /// [fullySplitValue]) then all of the surrounding implied rules are also set
  /// to their fully split value.
  ///
  /// This contains all direct as well as transitive relationships. If A
  /// contains B which contains C, C's outerRules contains both B and A.
  final Set<Rule> _implied = <Rule>{};

  /// Marks [other] as implied by this one.
  ///
  /// That means that if this rule splits, then [other] is force to split too.
  void imply(Rule other) {
    _implied.add(other);
  }

  /// Whether this rule cares about rules that it contains.
  ///
  /// If `true` then inner rules will constrain this one and force it to split
  /// when they split. Otherwise, it can split independently of any contained
  /// rules.
  bool get splitsOnInnerRules => true;

  Rule([int? cost]) : _cost = cost ?? Cost.normal;

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
    if (_implied.contains(other)) return other.fullySplitValue;

    return null;
  }

  /// A protected method for subclasses to add the rules that they constrain
  /// to [rules].
  ///
  /// Called by [Rule] the first time [constrainedRules] is accessed.
  void addConstrainedRules(Set<Rule> rules) {}

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
    _implied.retainWhere((rule) => rule.index != null);

    // Clear the cached ones too.
    _constrainedRules = null;
    _allConstrainedRules = null;
  }

  /// The other [Rule]s that this rule places immediate constraints on.
  Set<Rule> get constrainedRules {
    // Lazy initialize this on first use. Note: Assumes this is only called
    // after the chunks have been written and any constraints have been wired
    // up.
    var rules = _constrainedRules;
    if (rules != null) return rules;

    rules = _implied.toSet();
    addConstrainedRules(rules);
    _constrainedRules = rules;
    return rules;
  }

  Set<Rule>? _constrainedRules;

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
