// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import '../chunk.dart';
import '../constants.dart';
import '../debug.dart' as debug;
import '../nesting_level.dart';
import '../rule/rule.dart';
import 'line_splitter.dart';
import 'rule_set.dart';

/// A possibly incomplete solution in the line splitting search space.
///
/// A single [SolveState] binds some subset of the rules to values while
/// leaving the rest unbound. If every rule is bound, the solve state describes
/// a complete solution to the line splitting problem. Even if rules are
/// unbound, a state can also usually be used as a solution by treating all
/// unbound rules as unsplit. (The usually is because a state that constrains
/// an unbound rule to split can't be used with that rule unsplit.)
///
/// From a given solve state, we can explore the search tree to more refined
/// solve states by producing new ones that add more bound rules to the current
/// state.
class SolveState {
  final LineSplitter _splitter;
  final RuleSet _ruleValues;

  /// The set of [Rule]s that are bound by [_ruleValues].
  ///
  /// Cached by [_ensureConstraints] for use by [_ensureUnboundConstraints].
  late Set<Rule> _boundRules;

  /// The set of [Rule]s that are not bound by [_ruleValues].
  ///
  /// Cached by [_ensureConstraints] for use by [_ensureUnboundConstraints].
  late Set<Rule> _unboundRules;

  /// The unbound rules in this state that can be bound to produce new more
  /// refined states.
  ///
  /// Keeping this set small is the key to make the entire line splitter
  /// perform well. If we consider too many rules at each state, our
  /// exploration of the solution space is too branchy and we waste time on
  /// dead end solutions.
  ///
  /// Here is the key insight. The line splitter treats any unbound rule as
  /// being unsplit. This means refining a solution always means taking a rule
  /// that is unsplit and making it split. That monotonically increases the
  /// cost, but may help fit the solution inside the page.
  ///
  /// We want to keep the cost low, so the only reason to consider making a
  /// rule split is if it reduces an overflowing line. It's also the case that
  /// splitting an earlier rule will often reshuffle the rest of the line.
  ///
  /// Taking that into account, the only rules we consider binding to extend a
  /// solve state are *unbound rules inside the first line that is overflowing*.
  /// Even if a line has dozens of rules, this generally keeps the branching
  /// down to a few. It also means rules inside lines that already fit are
  /// never touched.
  ///
  /// There is one other set of rules that go in here. Sometimes a bound rule
  /// in the solve state constrains some other unbound rule to split. In that
  /// case, we also consider that active so we know to not leave it at zero.
  final _liveRules = <Rule>{};

  /// The set of splits chosen for this state.
  SplitSet get splits => _splits;
  late final SplitSet _splits;

  /// The number of characters that do not fit inside the page with this set of
  /// splits.
  int get overflowChars => _overflowChars;
  int _overflowChars = 0;

  /// Whether we can treat this state as a complete solution by leaving its
  /// unbound rules unsplit.
  ///
  /// This is generally true but will be false if the state contains any
  /// unbound rules that are constrained to not be zero by other bound rules.
  /// This avoids picking a solution that leaves those rules at zero when they
  /// aren't allowed to be.
  bool _isComplete = true;

  /// The constraints the bound rules in this state have on the remaining
  /// unbound rules.
  late final Map<Rule, int> _constraints = _initConstraints();

  /// The unbound rule values that are disallowed because they would place
  /// invalid constraints on the currently bound values.
  ///
  /// For example, say rule A is bound to 1 and B is unbound. If B has value
  /// 1, it constrains A to be 1. Likewise, if B is 2, it constrains A to be
  /// 2 as well. Since we already know A is 1, that means we know B cannot be
  /// bound to value 2. This means B is more limited in this state than it
  /// might be in another state that binds A to a different value.
  ///
  /// It's important to track this, because we can't allow to states to overlap
  /// if one permits more values for some unbound rule than the other does.
  late final Map<Rule, Set<int>> _unboundConstraints =
      _initUnboundConstraints();

  /// The bound rules that appear inside lines also containing unbound rules.
  ///
  /// By appearing in the same line, it means these bound rules may affect the
  /// results of binding those unbound rules. This is used to tell if two
  /// states may diverge by binding unbound rules or not.
  late final Set<Rule> _boundRulesInUnboundLines =
      _initBoundRulesInUnboundLines();

  SolveState(this._splitter, this._ruleValues) {
    _calculateSplits();
    _calculateCost();
  }

  /// Gets the value to use for [rule], either the bound value or
  /// [Rule.unsplit] if it isn't bound.
  int getValue(Rule rule) => _ruleValues.getValue(rule);

  /// Returns `true` if this state is a better solution to use as the final
  /// result than [other].
  bool isBetterThan(SolveState other) {
    // If this state contains an unbound rule that we know can't be left
    // unsplit, we can't pick this as a solution.
    if (!_isComplete) return false;

    // Prefer the solution that fits the most in the page.
    if (overflowChars != other.overflowChars) {
      return overflowChars < other.overflowChars;
    }

    // Otherwise, prefer the best cost.
    return splits.cost < other.splits.cost;
  }

  /// Determines if this state "overlaps" [other].
  ///
  /// Two states overlap if they currently have the same score and we can tell
  /// for certain that they won't diverge as their unbound rules are bound. If
  /// that's the case, then whichever state is better now (based on their
  /// currently bound rule values) is the one that will always win, regardless
  /// of how they get expanded.
  ///
  /// In other words, their entire expanded solution trees also overlap. In
  /// that case, there's no point in expanding both, so we can just pick the
  /// winner now and discard the other.
  ///
  /// For this to be true, we need to prove that binding an unbound rule won't
  /// affect one state differently from the other. We have to show that they
  /// are parallel.
  ///
  /// Two things could cause this *not* to be the case.
  ///
  /// 1. If one state's bound rules place different constraints on the unbound
  ///    rules than the other.
  ///
  /// 2. If one state's different bound rules are in the same line as an
  ///    unbound rule. That affects the indentation and length of the line,
  ///    which affects the context where the unbound rule is being chosen.
  ///
  /// If neither of these is the case, the states overlap. Returns `<0` if this
  /// state is better, or `>0` if [other] wins. If the states do not overlap,
  /// returns `0`.
  int compareOverlap(SolveState other) {
    if (!_isOverlapping(other)) return 0;

    // They do overlap, so see which one wins.
    for (var rule in _splitter.rules) {
      var value = _ruleValues.getValue(rule);
      var otherValue = other._ruleValues.getValue(rule);

      if (value != otherValue) return value.compareTo(otherValue);
    }

    // The way SolveStates are expanded should guarantee that we never generate
    // the exact same state twice. Getting here implies that that failed.
    throw 'unreachable';
  }

  /// Enqueues more solve states to consider based on this one.
  ///
  /// For each unbound rule in this state that occurred in the first long line,
  /// enqueue solve states that bind that rule to each value it can have and
  /// bind all previous rules to zero. (In other words, try all subsolutions
  /// where that rule becomes the first new rule to split at.)
  void expand() {
    var unsplitRules = _ruleValues.clone();

    // Walk down the rules looking for unbound ones to try.
    var triedRules = 0;
    for (var rule in _splitter.rules) {
      if (_liveRules.contains(rule)) {
        // We found one worth trying, so try all of its values.
        for (var value = 1; value < rule.numValues; value++) {
          var boundRules = unsplitRules.clone();

          List<Rule>? mustSplitRules;
          var valid = boundRules.tryBind(_splitter.rules, rule, value, (rule) {
            mustSplitRules ??= [];
            mustSplitRules!.add(rule);
          });

          // Make sure we don't violate the constraints of the bound rules.
          if (!valid) continue;

          var state = SolveState(_splitter, boundRules);

          // If some unbound rules are constrained to split, remember that.
          if (mustSplitRules != null) {
            state._isComplete = false;
            state._liveRules.addAll(mustSplitRules!);
          }

          _splitter.enqueue(state);
        }

        // Stop once we've tried all of the ones we can.
        if (++triedRules == _liveRules.length) break;
      }

      // Fill in previous unbound rules with zero.
      if (!_ruleValues.contains(rule)) {
        // Pass a dummy callback because zero will never fail. (If it would
        // have, that rule would already be bound to some other value.)
        if (!unsplitRules.tryBind(_splitter.rules, rule, 0, (_) {})) {
          break;
        }
      }
    }
  }

  /// Returns `true` if [other] overlaps this state.
  bool _isOverlapping(SolveState other) {
    // Lines that contain both bound and unbound rules must have the same
    // bound values.
    if (_boundRulesInUnboundLines.length !=
        other._boundRulesInUnboundLines.length) {
      return false;
    }

    for (var rule in _boundRulesInUnboundLines) {
      if (!other._boundRulesInUnboundLines.contains(rule)) return false;
      if (_ruleValues.getValue(rule) != other._ruleValues.getValue(rule)) {
        return false;
      }
    }

    if (_constraints.length != other._constraints.length) return false;

    for (var rule in _constraints.keys) {
      if (_constraints[rule] != other._constraints[rule]) return false;
    }

    if (_unboundConstraints.length != other._unboundConstraints.length) {
      return false;
    }

    for (var rule in _unboundConstraints.keys) {
      var disallowed = _unboundConstraints[rule]!;
      var otherDisallowed = other._unboundConstraints[rule]!;

      if (disallowed.length != otherDisallowed.length) return false;
      for (var value in disallowed) {
        if (!otherDisallowed.contains(value)) return false;
      }
    }

    return true;
  }

  /// Calculates the [SplitSet] for this solve state, assuming any unbound
  /// rules are set to zero.
  void _calculateSplits() {
    // Figure out which expression nesting levels got split and need to be
    // assigned columns.
    var usedNestingLevels = <NestingLevel>{};
    for (var i = 0; i < _splitter.chunks.length; i++) {
      var chunk = _splitter.chunks[i];
      if (chunk.rule.isSplit(getValue(chunk.rule), chunk)) {
        usedNestingLevels.add(chunk.nesting);
        chunk.nesting.clearTotalUsedIndent();
      }
    }

    for (var nesting in usedNestingLevels) {
      nesting.refreshTotalUsedIndent(usedNestingLevels);
    }

    _splits = SplitSet(_splitter.chunks.length);
    for (var i = 0; i < _splitter.chunks.length; i++) {
      var chunk = _splitter.chunks[i];
      if (chunk.rule.isSplit(getValue(chunk.rule), chunk)) {
        var indent = 0;
        if (!chunk.flushLeft) {
          // Add in the chunk's indent.
          indent = _splitter.blockIndentation + chunk.indent;

          // And any expression nesting.
          indent += chunk.nesting.totalUsedIndent;

          if (_splitter.chunks[i].indentBlock(getValue)) {
            indent += Indent.expression;
          }
        }

        _splits.add(i, indent);
      }
    }
  }

  /// Evaluates the cost (i.e. the relative "badness") of splitting the line
  /// into [lines] physical lines based on the current set of rules.
  void _calculateCost() {
    // Calculate the length of each line and apply the cost of any spans that
    // get split.
    var cost = 0;
    var length = 0;

    // The unbound rules in use by the current line. This will be null after
    // the first long line has completed.
    var foundOverflowRules = false;
    var start = 0;

    void endLine(int end) {
      // Track lines that went over the length. It is only rules contained in
      // long lines that we may want to split.
      if (length > _splitter.writer.pageWidth) {
        _overflowChars += length - _splitter.writer.pageWidth;

        // Only try rules that are in the first long line, since we know at
        // least one of them *will* be split.
        if (!foundOverflowRules) {
          for (var i = start; i < end; i++) {
            if (_addLiveRules(_splitter.chunks[i].rule)) {
              foundOverflowRules = true;
            }
          }
        }
      }

      start = end;
    }

    // The set of spans that contain chunks that ended up splitting. We store
    // these in a set so a span's cost doesn't get double-counted if more than
    // one split occurs in it.
    var splitSpans = <Span>{};

    // The nesting level of the chunk that ended the previous line.
    NestingLevel? previousNesting;

    for (var i = 0; i < _splitter.chunks.length; i++) {
      var chunk = _splitter.chunks[i];

      if (_splits.shouldSplitAt(i)) {
        endLine(i);

        splitSpans.addAll(chunk.spans);

        // Do not allow sequential lines to have the same indentation but for
        // different reasons. In other words, don't allow different expressions
        // to claim the same nesting level on subsequent lines.
        //
        // A contrived example would be:
        //
        //     function(inner(
        //         argument), second(
        //         another);
        //
        // For the most part, we prevent this by the constraints on splits.
        // For example, the above can't happen because the split before
        // "argument", forces the split before "second".
        //
        // But there are a couple of squirrely cases where it's hard to prevent
        // by construction. Instead, this outlaws it by penalizing it very
        // heavily if it happens to get this far.
        var totalIndent = chunk.nesting.totalUsedIndent;
        if (previousNesting != null &&
            totalIndent != 0 &&
            totalIndent == previousNesting.totalUsedIndent &&
            !identical(chunk.nesting, previousNesting)) {
          _overflowChars += 10000;
        }

        previousNesting = chunk.nesting;

        // Start the new line.
        length = _splits.getColumn(i);
      } else {
        if (chunk.spaceWhenUnsplit) length++;
      }

      if (chunk is BlockChunk) {
        if (_splits.shouldSplitAt(i)) {
          // Include the cost of the nested block.
          cost +=
              _splitter.writer.formatBlock(chunk, _splits.getColumn(i)).cost;
        } else {
          // Include the nested block inline, if any.
          length += chunk.unsplitBlockLength;
        }
      }

      length += chunk.text.length;
    }

    // Add the costs for the rules that have any splits.
    _ruleValues.forEach(_splitter.rules, (rule, value) {
      if (value != Rule.unsplit) cost += rule.cost;
    });

    // Add the costs for the spans containing splits.
    for (var span in splitSpans) {
      cost += span.cost;
    }

    // Finish the last line.
    endLine(_splitter.chunks.length);

    _splits.setCost(cost);
  }

  /// Adds [rule] and all of the rules it constrains to the set of [_liveRules].
  ///
  /// Only does this if [rule] is a valid soft rule. Returns `true` if any new
  /// live rules were added.
  bool _addLiveRules(Rule? rule) {
    if (rule == null) return false;

    var added = false;
    for (var constrained in rule.allConstrainedRules) {
      if (_ruleValues.contains(constrained)) continue;

      _liveRules.add(constrained);
      added = true;
    }

    return added;
  }

  /// Used to lazy initialize [_boundRulesInUnboundLines], which is needed to
  /// compare two states for overlap.
  ///
  /// We do this lazily because the calculation is a bit slow, and is only
  /// needed when we have two states with the same score.
  Set<Rule> _initBoundRulesInUnboundLines() {
    var rules = <Rule>{};
    var boundInLine = <Rule>{};
    var hasUnbound = false;

    for (var i = 0; i < _splitter.chunks.length; i++) {
      if (splits.shouldSplitAt(i)) {
        if (hasUnbound) rules.addAll(boundInLine);

        boundInLine.clear();
        hasUnbound = false;
      }

      var rule = _splitter.chunks[i].rule;
      if (_ruleValues.contains(rule)) {
        boundInLine.add(rule);
      } else {
        hasUnbound = true;
      }
    }

    if (hasUnbound) rules.addAll(boundInLine);
    return rules;
  }

  /// Used to lazy initializes the [_constraints], which is needed to compare
  /// two states for overlap.
  ///
  /// We do this lazily because the calculation is a bit slow, and is only
  /// needed when we have two states with the same score.
  Map<Rule, int> _initConstraints() {
    _unboundRules = <Rule>{};
    _boundRules = <Rule>{};

    for (var rule in _splitter.rules) {
      if (_ruleValues.contains(rule)) {
        _boundRules.add(rule);
      } else {
        _unboundRules.add(rule);
      }
    }

    var constraints = <Rule, int>{};

    for (var bound in _boundRules) {
      for (var unbound in bound.constrainedRules) {
        if (!_unboundRules.contains(unbound)) continue;

        var value = _ruleValues.getValue(bound);
        var constraint = bound.constrain(value, unbound);
        if (constraint != null) {
          constraints[unbound] = constraint;
        }
      }
    }

    return constraints;
  }

  /// Used to lazy initialize the [_unboundConstraints], which is needed to
  /// compare two states for overlap.
  ///
  /// We do this lazily because the calculation is a bit slow, and is only
  /// needed when we have two states with the same score.
  Map<Rule, Set<int>> _initUnboundConstraints() {
    var unboundConstraints = <Rule, Set<int>>{};
    for (var unbound in _unboundRules) {
      // Lazily create and add the set to the constraints only if needed.
      late final disallowedValues = unboundConstraints[unbound] = {};

      for (var bound in unbound.constrainedRules) {
        if (!_boundRules.contains(bound)) continue;

        var boundValue = _ruleValues.getValue(bound);

        for (var value = 0; value < unbound.numValues; value++) {
          var constraint = unbound.constrain(value, bound);

          // If the unbound rule doesn't place any constraint on this bound
          // rule, we're fine.
          if (constraint == null) continue;

          // If the bound rule's value already meets the constraint it applies,
          // we don't need to track it. This way, two states that have the
          // same bound value, one of which has a satisfied constraint, are
          // still allowed to overlap.
          if (constraint == boundValue) continue;
          if (constraint == Rule.mustSplit && boundValue != Rule.unsplit) {
            continue;
          }

          disallowedValues.add(value);
        }
      }
    }

    return unboundConstraints;
  }

  @override
  String toString() {
    var buffer = StringBuffer();

    buffer.writeAll(_splitter.rules.map((rule) {
      var valueLength = '${rule.fullySplitValue}'.length;

      var value = '?';
      if (_ruleValues.contains(rule)) {
        value = '${_ruleValues.getValue(rule)}';
      }

      value = value.padLeft(valueLength);
      if (_liveRules.contains(rule)) {
        value = debug.bold(value);
      } else {
        value = debug.gray(value);
      }

      return value;
    }), ' ');

    buffer.write('   \$${splits.cost}');

    if (overflowChars > 0) buffer.write(' ($overflowChars over)');
    if (!_isComplete) buffer.write(' (incomplete)');

    return buffer.toString();
  }
}
