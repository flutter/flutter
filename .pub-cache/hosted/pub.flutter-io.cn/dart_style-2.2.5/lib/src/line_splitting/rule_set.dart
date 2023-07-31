// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import '../rule/rule.dart';

/// An optimized data structure for storing a set of values for some rules.
///
/// This conceptually behaves roughly like a `Map<Rule, int>`, but is much
/// faster since it avoids hashing. Instead, it assumes the line splitter has
/// provided an ordered list of [Rule]s and that each rule's [index] field has
/// been set to point to the rule in the list.
///
/// Internally, this then just stores the values in a sparse list whose indices
/// are the indices of the rules.
class RuleSet {
  List<int?> _values;

  RuleSet(int numRules) : this._(List.filled(numRules, null));

  RuleSet._(this._values);

  /// Returns `true` of [rule] is bound in this set.
  bool contains(Rule rule) {
    // Treat hardened rules as implicitly bound.
    if (rule.isHardened) return true;

    return _values[rule.index!] != null;
  }

  /// Gets the bound value for [rule] or [Rule.unsplit] if it is not bound.
  int getValue(Rule rule) {
    // Hardened rules are implicitly bound.
    if (rule.isHardened) return rule.fullySplitValue;

    var value = _values[rule.index!];
    if (value != null) return value;

    return Rule.unsplit;
  }

  /// Invokes [callback] for each rule in [rules] with the rule's value, which
  /// will be `null` if it is not bound.
  void forEach(List<Rule> rules, void Function(Rule, int) callback) {
    var i = 0;
    for (var rule in rules) {
      var value = _values[i];
      if (value != null) callback(rule, value);
      i++;
    }
  }

  /// Creates a new [RuleSet] with the same bound rule values as this one.
  RuleSet clone() => RuleSet._(_values.toList(growable: false));

  /// Binds [rule] to [value] then checks to see if that violates any
  /// constraints.
  ///
  /// Returns `true` if all constraints between the bound rules are valid. Even
  /// if not, this still modifies the [RuleSet].
  ///
  /// If an unbound rule gets constrained to `-1` (meaning it must split, but
  /// can split any way it wants), invokes [onSplitRule] with it.
  bool tryBind(
      List<Rule> rules, Rule rule, int value, void Function(Rule) onSplitRule) {
    assert(!rule.isHardened);

    _values[rule.index!] = value;

    // Test this rule against the other rules being bound.
    for (var other in rule.constrainedRules) {
      int? otherValue;
      // Hardened rules are implicitly bound.
      if (other.isHardened) {
        otherValue = other.fullySplitValue;
      } else {
        otherValue = _values[other.index!];
      }

      var constraint = rule.constrain(value, other);

      if (otherValue == null) {
        // The other rule is unbound, so see if we can constrain it eagerly to
        // a value now.
        if (constraint == Rule.mustSplit) {
          // If we know the rule has to split and there's only one way it can,
          // just bind that.
          if (other.numValues == 2) {
            if (!tryBind(rules, other, 1, onSplitRule)) return false;
          } else {
            onSplitRule(other);
          }
        } else if (constraint != null) {
          // Bind the other rule to its value and recursively propagate its
          // constraints.
          if (!tryBind(rules, other, constraint, onSplitRule)) return false;
        }
      } else {
        // It's already bound, so see if the new rule's constraint disallows
        // that value.
        if (constraint == Rule.mustSplit) {
          if (otherValue == Rule.unsplit) return false;
        } else if (constraint != null) {
          if (otherValue != constraint) return false;
        }

        // See if the other rule's constraint allows us to use this value.
        constraint = other.constrain(otherValue, rule);
        if (constraint == Rule.mustSplit) {
          if (value == Rule.unsplit) return false;
        } else if (constraint != null) {
          if (value != constraint) return false;
        }
      }
    }

    return true;
  }

  @override
  String toString() => _values.map((value) => value ?? '?').join(' ');
}

/// For each chunk, this tracks if it has been split and, if so, what the
/// chosen column is for the following line.
///
/// Internally, this uses a list where each element corresponds to the column
/// of the chunk at that index in the chunk list, or `-1` if that chunk did not
/// split. This had about a 10% perf improvement over using a [Set] of splits.
class SplitSet {
  final List<int> _columns;

  /// The cost of the solution that led to these splits.
  int get cost => _cost;
  late final int _cost;

  /// Creates a new empty split set for a line with [numChunks].
  SplitSet(int numChunks) : _columns = List.filled(numChunks, -1);

  /// Marks the chunk at [index] as starting at [column].
  void add(int index, int column) {
    _columns[index] = column;
  }

  /// Returns `true` if the chunk at [splitIndex] should be split.
  bool shouldSplitAt(int index) =>
      index < _columns.length && _columns[index] != -1;

  /// Gets the zero-based starting column for the chunk at [index].
  int getColumn(int index) => _columns[index];

  /// Sets the resulting [cost] for the splits.
  ///
  /// This can only be called once.
  void setCost(int cost) {
    _cost = cost;
  }

  @override
  String toString() {
    return [
      for (var i = 0; i < _columns.length; i++)
        if (_columns[i] != -1) '$i:${_columns[i]}'
    ].join(' ');
  }
}
