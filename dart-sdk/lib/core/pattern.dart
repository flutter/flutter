// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// An interface for basic searches within strings.
abstract interface class Pattern {
  /// Matches this pattern against the string repeatedly.
  ///
  /// If [start] is provided, matching will start at that index.
  ///
  /// The returned iterable lazily finds non-overlapping matches
  /// of the pattern in the [string].
  /// If a user only requests the first match,
  /// this function should not compute all possible matches.
  ///
  /// The matches are found by repeatedly finding the first match
  /// of the pattern in the string, initially starting from [start],
  /// and then from the end of the previous match (but always
  /// at least one position later than the *start* of the previous
  /// match, in case the pattern matches an empty substring).
  /// ```dart
  /// RegExp exp = RegExp(r'(\w+)');
  /// var str = 'Dash is a bird';
  /// Iterable<Match> matches = exp.allMatches(str, 8);
  /// for (final Match m in matches) {
  ///   String match = m[0]!;
  ///   print(match);
  /// }
  /// ```
  /// The output of the example is:
  /// ```
  /// a
  /// bird
  /// ```
  Iterable<Match> allMatches(String string, [int start = 0]);

  /// Matches this pattern against the start of `string`.
  ///
  /// Returns a match if the pattern matches a substring of [string]
  /// starting at [start], and `null` if the pattern doesn't match
  /// at that point.
  ///
  /// The [start] must be non-negative and no greater than `string.length`.
  /// ```dart
  /// final string = 'Dash is a bird';
  ///
  /// var regExp = RegExp(r'bird');
  /// var match = regExp.matchAsPrefix(string, 10); // Match found.
  ///
  /// regExp = RegExp(r'bird');
  /// match = regExp.matchAsPrefix(string); // null
  /// ```
  Match? matchAsPrefix(String string, [int start = 0]);
}

/// A result from searching within a string.
///
/// A `Match` or an [Iterable] of `Match` objects is returned from
/// the [Pattern] matching methods
/// ([Pattern.allMatches] and [Pattern.matchAsPrefix]).
///
/// The following example finds all matches of a [RegExp] in a [String]
/// and iterates through the returned iterable of `Match` objects.
/// ```dart
/// final regExp = RegExp(r'(\w+)');
/// const string = 'Parse my string';
/// final matches = regExp.allMatches(string);
/// for (final m in matches) {
///   String match = m[0]!;
///   print(match);
/// }
/// ```
/// The output of the example is:
/// ```
/// Parse
/// my
/// string
/// ```
/// Some patterns, regular expressions in particular, may record substrings
/// that were part of the matching. These are called _groups_ in the `Match`
/// object. Some patterns may never have any groups, and their matches always
/// have zero [groupCount].
abstract interface class Match {
  /// The index in the string where the match starts.
  int get start;

  /// The index in the string after the last character of the match.
  int get end;

  /// The string matched by the given [group].
  ///
  /// If [group] is 0, returns the entire match of the pattern.
  ///
  /// The result may be `null` if the pattern didn't assign a value to it
  /// as part of this match.
  /// ```dart import:convert
  ///
  /// final string = '[00:13.37] This is a chat message.';
  /// final regExp = RegExp(r'^\[\s*(\d+):(\d+)\.(\d+)\]\s*(.*)$');
  /// final match = regExp.firstMatch(string)!;
  /// final message = jsonEncode(match[0]!); // '[00:13.37] This is a chat message.'
  /// final hours = jsonEncode(match[1]!); // '00'
  /// final minutes = jsonEncode(match[2]!); // '13'
  /// final seconds = jsonEncode(match[3]!); // '37'
  /// final text = jsonEncode(match[4]!); // 'This is a chat message.'
  /// ```
  String? group(int group);

  /// The string matched by the given [group].
  ///
  /// If [group] is 0, returns the match of the pattern.
  ///
  /// Short alias for [Match.group].
  String? operator [](int group);

  /// A list of the groups with the given indices.
  ///
  /// The list contains the strings returned by [group] for each index in
  /// [groupIndices].
  /// ```dart import:convert
  ///
  /// final string = '[00:13.37] This is a chat message.';
  /// final regExp = RegExp(r'^\[\s*(\d+):(\d+)\.(\d+)\]\s*(.*)$');
  /// final match = regExp.firstMatch(string)!;
  /// final message = jsonEncode(match.groups([1, 2, 3, 4]));
  /// // ['00','13','37','This is a chat message.']
  /// ```
  List<String?> groups(List<int> groupIndices);

  /// Returns the number of captured groups in the match.
  ///
  /// Some patterns may capture parts of the input that was used to
  /// compute the full match. This is the number of captured groups,
  /// which is also the maximal allowed argument to the [group] method.
  int get groupCount;

  /// The string on which this match was computed.
  String get input;

  /// The pattern used to search in [input].
  Pattern get pattern;
}
