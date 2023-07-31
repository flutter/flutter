// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import '../chunk.dart';
import '../debug.dart' as debug;
import '../line_writer.dart';
import '../rule/rule.dart';
import 'rule_set.dart';
import 'solve_state.dart';
import 'solve_state_queue.dart';

/// To ensure the solver doesn't go totally pathological on giant code, we cap
/// it at a fixed number of attempts.
///
/// If the optimal solution isn't found after this many tries, it just uses the
/// best it found so far.
const _maxAttempts = 5000;

/// Takes a set of chunks and determines the best values for its rules in order
/// to fit it inside the page boundary.
///
/// This problem is exponential in the number of rules and a single expression
/// in Dart can be quite large, so it isn't feasible to brute force this. For
/// example:
///
///     outer(
///         fn(1 + 2, 3 + 4, 5 + 6, 7 + 8),
///         fn(1 + 2, 3 + 4, 5 + 6, 7 + 8),
///         fn(1 + 2, 3 + 4, 5 + 6, 7 + 8),
///         fn(1 + 2, 3 + 4, 5 + 6, 7 + 8));
///
/// There are 509,607,936 ways this can be split.
///
/// The problem is even harder because we may not be able to easily tell if a
/// given solution is the best one. It's possible that there is *no* solution
/// that fits in the page (due to long strings or identifiers) so the winning
/// solution may still have overflow characters. This makes it hard to know
/// when we are done and can stop looking.
///
/// There are a couple of pieces of domain knowledge we use to cope with this:
///
/// - Changing a rule from unsplit to split will never lower its cost. A
///   solution with all rules unsplit will always be the one with the lowest
///   cost (zero). Conversely, setting all of its rules to the maximum split
///   value will always have the highest cost.
///
///   (You might think there is a converse rule about overflow characters. The
///   solution with the fewest splits will have the most overflow, and the
///   solution with the most splits will have the least overflow. Alas, because
///   of indentation, that isn't always the case. Adding a split may *increase*
///   overflow in some cases.)
///
/// - If all of the chunks for a rule are inside lines that already fit in the
///   page, then splitting that rule will never improve the solution.
///
/// - If two partial solutions have the same cost and the bound rules don't
///   affect any of the remaining unbound rules, then whichever partial
///   solution is currently better will always be the winner regardless of what
///   the remaining unbound rules are bound to.
///
/// We start off with a [SolveState] where all rules are unbound (which
/// implicitly treats them as unsplit). For a given solve state, we can produce
/// a set of expanded states that takes some of the rules in the first long
/// line and binds them to split values. This always produces new solve states
/// with higher cost (but often fewer overflow characters) than the parent
/// state.
///
/// We take these expanded states and add them to a work list sorted by cost.
/// Since unsplit rules always have lower cost solutions, we know that no state
/// we enqueue later will ever have a lower cost than the ones we already have
/// enqueued.
///
/// Then we keep pulling states off the work list and expanding them and adding
/// the results back into the list. We do this until we hit a solution where
/// all characters fit in the page. The first one we find will have the lowest
/// cost and we're done.
///
/// We also keep running track of the best solution we've found so far that
/// has the fewest overflow characters and the lowest cost. If no solution fits,
/// we'll use this one.
///
/// When enqueing a solution, we can sometimes collapse it and a previously
/// queued one by preferring one or the other. If two solutions have the same
/// cost and we can prove that they won't diverge later as unbound rules are
/// set, we can pick the winner now and discard the other. This lets us avoid
/// redundantly exploring entire subtrees of the solution space.
///
/// As a final escape hatch for pathologically nasty code, after trying some
/// fixed maximum number of solve states, we just bail and return the best
/// solution found so far.
///
/// Even with the above algorithmic optimizations, complex code may still
/// require a lot of exploring to find an optimal solution. To make that fast,
/// this code is carefully profiled and optimized. If you modify this, make
/// sure to test against the benchmark to ensure you don't regress performance.
class LineSplitter {
  final LineWriter writer;

  /// The list of chunks being split.
  final List<Chunk> chunks;

  /// The set of soft rules whose values are being selected.
  final List<Rule> rules;

  /// The number of characters of additional indentation to apply to each line.
  ///
  /// This is used when formatting blocks to get the output into the right
  /// column based on where the block appears.
  final int blockIndentation;

  /// The queue of solve states to explore further.
  ///
  /// This is sorted lowest-cost first. This ensures that as soon as we find a
  /// solution that fits in the page, we know it will be the lowest cost one
  /// and can stop looking.
  final _queue = SolveStateQueue();

  /// Creates a new splitter for [_writer] that tries to fit [chunks] into the
  /// page width.
  LineSplitter(this.writer, this.chunks, this.blockIndentation)
      : // Collect the set of rules that we need to select values for.
        rules =
            chunks.map((chunk) => chunk.rule).toSet().toList(growable: false) {
    _queue.bindSplitter(this);

    // Store the rule's index in the rule so we can get from a chunk to a rule
    // index quickly.
    for (var i = 0; i < rules.length; i++) {
      rules[i].index = i;
    }

    // Now that every used rule has an index, tell the rules to discard any
    // constraints on unindexed rules.
    for (var rule in rules) {
      rule.forgetUnusedRules();
    }
  }

  /// Determine the best way to split the chunks into lines that fit in the
  /// page, if possible.
  ///
  /// Returns a [SplitSet] that defines where each split occurs and the
  /// indentation of each line.
  SplitSet apply() {
    // Start with a completely unbound, unsplit solution.
    var bestSolution = SolveState(this, RuleSet(rules.length));
    _queue.add(bestSolution);

    var attempts = 0;
    while (_queue.isNotEmpty) {
      var state = _queue.removeFirst();

      if (state.isBetterThan(bestSolution)) {
        bestSolution = state;

        // Since we sort solutions by cost the first solution we find that
        // fits is the winner.
        if (bestSolution.overflowChars == 0) break;
      }

      if (debug.traceSplitter) {
        var best = state == bestSolution ? ' (best)' : '';
        debug.log('$state$best');
        debug.dumpLines(chunks, state.splits);
        debug.log();
      }

      if (attempts++ > _maxAttempts) break;

      // Try bumping the rule values for rules whose chunks are on long lines.
      state.expand();
    }

    if (debug.traceSplitter) {
      debug.log('$bestSolution (winner)');
      debug.dumpLines(chunks, bestSolution.splits);
      debug.log();
    }

    return bestSolution.splits;
  }

  void enqueue(SolveState state) {
    _queue.add(state);
  }
}
