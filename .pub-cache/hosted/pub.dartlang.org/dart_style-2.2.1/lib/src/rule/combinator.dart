// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_style.src.rule.combinator;

import '../chunk.dart';
import 'rule.dart';

/// Handles a list of "combinators".
///
/// A combinator is a keyword followed by a list of nodes used to modify some
/// declaration. It's used for actual hide and show combinators as well as
/// "with" and "implements" clauses in class declarations.
///
/// Combinators can be split in a few different ways:
///
///     // All on one line:
///     import 'animals.dart' show Ant hide Cat;
///
///     // Wrap before each keyword:
///     import 'animals.dart'
///         show Ant, Baboon
///         hide Cat;
///
///     // Wrap either or both of the name lists:
///     import 'animals.dart'
///         show
///             Ant,
///             Baboon
///         hide Cat;
///
/// These are not allowed:
///
///     // Wrap list but not keyword:
///     import 'animals.dart' show
///             Ant,
///             Baboon
///         hide Cat;
///
///     // Wrap one keyword but not both:
///     import 'animals.dart'
///         show Ant, Baboon hide Cat;
///
/// This ensures that when any wrapping occurs, the keywords are always at
/// the beginning of the line.
class CombinatorRule extends Rule {
  /// The set of chunks before the combinators.
  final _combinators = <Chunk>{};

  /// A list of sets of chunks prior to each name in a combinator.
  ///
  /// The outer list is a list of combinators (i.e. "hide", "show", etc.). Each
  /// inner set is the set of names for that combinator.
  final List<Set<Chunk>> _names = [];

  @override
  int get numValues {
    var count = 2; // No wrapping, or wrap just before each combinator.

    if (_names.length == 2) {
      count += 3; // Wrap first set of names, second, or both.
    } else {
      assert(_names.length == 1);
      count++; // Wrap the names.
    }

    return count;
  }

  /// Adds a new combinator to the list of combinators.
  ///
  /// This must be called before adding any names.
  void addCombinator(Chunk chunk) {
    _combinators.add(chunk);
    _names.add({});
  }

  /// Adds a chunk prior to a name to the current combinator.
  void addName(Chunk chunk) {
    _names.last.add(chunk);
  }

  @override
  bool isSplitAtValue(int value, Chunk chunk) {
    switch (value) {
      case 1:
        // Just split at the combinators.
        return _combinators.contains(chunk);

      case 2:
        // Split at the combinators and the first set of names.
        return _isCombinatorSplit(0, chunk);

      case 3:
        // If there is two combinators, just split at the combinators and the
        // second set of names.
        if (_names.length == 2) {
          // Two sets of combinators, so just split at the combinators and the
          // second set of names.
          return _isCombinatorSplit(1, chunk);
        }

        // Split everything.
        return true;

      default:
        return true;
    }
  }

  /// Returns `true` if [chunk] is for a combinator or a name in the
  /// combinator at index [combinator].
  bool _isCombinatorSplit(int combinator, Chunk chunk) {
    return _combinators.contains(chunk) || _names[combinator].contains(chunk);
  }

  @override
  String toString() => 'Comb${super.toString()}';
}
