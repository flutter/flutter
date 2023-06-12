// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "characters_impl.dart";

/// The characters of a string.
///
/// A character is a Unicode Grapheme cluster represented
/// by a substring of the original string.
/// The `Characters` class is an [Iterable] of those strings.
/// However, unlike most iterables, many of the operations are
/// *eager*. Since the underlying string is known in its entirety,
/// and is known not to change, operations which select a subset of
/// the elements can be computed eagerly, and in that case the
/// operation returns a new `Characters` object.
///
/// The [iterator] provided by [Characters] is a [CharacterRange]
/// which allows iterating the independent characters in both directions,
/// but which also provides ways to select other ranges of characters
/// in different ways.
abstract class Characters implements Iterable<String> {
  /// An empty [Characters] containing no characters.
  static const Characters empty = StringCharacters("");

  /// Creates a [Characters] allowing iteration of
  /// the characters of [string].
  ///
  /// Returns [empty] if [string] is empty.
  factory Characters(String string) =>
      string.isEmpty ? empty : StringCharacters(string);

  /// The string to iterate over.
  String get string;

  /// Iterator over the characters of this string.
  ///
  /// Returns [CharacterRange] positioned before the first character
  /// of this [Characters].
  ///
  /// Allows iterating the characters of [string] as a plain iterator,
  /// using [CharacterRange.moveNext],
  /// as well as controlling the iteration in more detail.
  @override
  CharacterRange get iterator;

  /// Iterator over the characters of this string.
  ///
  /// Returns [CharacterRange] positioned after the last character
  /// of this [Characters].
  ///
  /// Allows iterating the characters of [string] backwards
  /// using [CharacterRange.movePrevious],
  /// as well as controlling the iteration in more detail.
  CharacterRange get iteratorAtEnd;

  /// Whether [singleCharacterString] occurs in this
  /// sequence of characters.
  ///
  /// Returns true only if [singleCharacterString] is
  /// a string containing a *single* character
  /// and that character is one of the characters
  /// in this character sequence, and false otherwise.
  /// This behavior is inherited from `Iterable<String>`,
  /// which is why it is not [Character] based.
  /// Use [containsAll] for a method which acts like
  /// [String.contains] for characters.
  @override
  bool contains(covariant String singleCharacterString);

  /// Whether this sequence of characters contains [other]
  /// as a subsequence.
  bool containsAll(Characters other);

  /// Whether this string starts with the characters of [other].
  ///
  /// Returns `true` if [other] the characters of [other]
  /// are also the first characters of this string,
  /// and `false` otherwise.
  bool startsWith(Characters other);

  /// Whether this string ends with the characters of [other].
  ///
  /// Returns `true` if [other] the characters of [other]
  /// are also the last characters of this string,
  /// and `false` otherwise.
  bool endsWith(Characters other);

  /// Finds the first occurrence of [characters] in this string.
  ///
  /// Returns a [CharacterRange] containing the first occurrence of
  /// [characters] in this string.
  /// Returns `null` if there is no such occurrence.
  CharacterRange? findFirst(Characters characters);

  /// Finds the last occurrence of [characters].
  ///
  /// Returns a [CharacterRange] containing the last occurrence of
  /// [characters].
  /// Returns `null` if there is no such occurrence,
  CharacterRange? findLast(Characters characters);

  /// Eagerly selects a subset of the characters.
  ///
  /// Tests each character against [test], and returns the
  /// characters of the concatenation of those character strings.
  @override
  Characters where(bool Function(String) test);

  /// Eagerly selects all but the first [count] characters.
  ///
  /// If [count] is greater than [length], the count of character
  /// available, then the empty sequence of characters
  /// is returned.
  @override
  Characters skip(int count);

  /// Eagerly selects the first [count] characters.
  ///
  /// If [count] is greater than [length], the count of character
  /// available, then the entire sequence of characters
  /// is returned.
  @override
  Characters take(int count);

  /// Eagerly selects the range of characters from [start] to [end].
  ///
  /// The [start] value must be non-negative,
  /// and [end], if supplied, must be greater than or equal to [start].
  ///
  /// A `characters.getRange(start, end)` is equivalent to
  /// ```dart
  ///  (end != null ? characters.take(end) : characters).skip(start)
  /// ```
  /// if [end] is omitted, the call is equivalent to `characters.skip(start)`.
  ///
  /// If [start] is greater than or equal to [length]
  /// the returned characters is empty.
  /// Otherwise, if [end] is greater than [length], or omitted,
  /// [end] is equivalent to [length].
  Characters getRange(int start, [int? end]);

  /// Returns the single-character sequence of the [position]th character.
  ///
  /// The [position] must be non-negative and less than [length].
  ///
  /// This operation must iterate characters up to [position] to find
  /// the result, just like [elementAt].
  /// It is not an efficient way to iterate over the individual characters
  /// of a `Characters`.
  ///
  /// An call to `chars.characterAt(n)`
  /// is equivalent to `chars.elementAt(n).characters`,
  /// or to `chars.getRange(n, n + 1)`
  /// (except that [getRange] allows `n` to be larger than [length]).
  Characters characterAt(int position);

  /// Eagerly selects all but the last [count] characters.
  ///
  /// If [count] is greater than [length], the count of character
  /// available, then the empty sequence of characters
  /// is returned.
  Characters skipLast(int count);

  /// Eagerly selects the last [count] characters.
  ///
  /// If [count] is greater than [length], the count of character
  /// available, then the entire sequence of characters
  /// is returned.
  Characters takeLast(int count);

  /// Eagerly selects a trailing sequence of characters.
  ///
  /// Checks each character, from first to last, against [test],
  /// until one is found where [test] returns `false`.
  /// The characters starting with the first one
  /// where [test] returns `false`, are included in the result.
  ///
  /// If no characters test `false`, the result is an empty sequence
  /// of characters.
  @override
  Characters skipWhile(bool Function(String) test);

  /// Eagerly selects a leading sequence of characters.
  ///
  /// Checks each character, from first to last, against [test],
  /// until one is found where [test] returns `false`.
  /// The characters up to, but not including, the first one
  /// where [test] returns `false` are included in the result.
  ///
  /// If no characters test `false`, the entire sequence of character
  /// is returned.
  @override
  Characters takeWhile(bool Function(String) test);

  /// Eagerly selects a leading sequence of characters.
  ///
  /// Checks each character, from last to first, against [test],
  /// until one is found where [test] returns `false`.
  /// The characters up to and including the one with the latest index
  /// where [test] returns `false` are included in the result.
  ///
  /// If no characters test `false`, the empty sequence of character
  /// is returned.
  Characters skipLastWhile(bool Function(String) test);

  /// Eagerly selects a trailing sequence of characters.
  ///
  /// Checks each character, from last to first, against [test],
  /// until one is found where [test] returns `false`.
  /// The characters after the one with the latest index where
  /// [test] returns `false` are included in the result.
  ///
  /// If no characters test `false`, the entire sequence of character
  /// is returned.
  Characters takeLastWhile(bool Function(String) test);

  /// The characters of the concatenation of this and [other].
  ///
  /// This is the characters of the concatenation of the underlying
  /// strings. If there is no character break at the concatenation
  /// point in the resulting string, then the result is not the concatenation
  /// of the two character sequences.
  ///
  /// This differs from [followedBy] which provides the lazy concatenation
  /// of this sequence of strings with any other sequence of strings.
  Characters operator +(Characters other);

  /// Replaces [pattern] with [replacement].
  ///
  /// Returns a new [Characters] sequence where all occurrences of the
  /// [pattern] characters are replaced by [replacement],
  /// unless the occurrence overlaps a prior
  /// replaced occurrence of [pattern].
  ///
  /// Returns the current characters if there is no occurrence of [pattern].
  Characters replaceAll(Characters pattern, Characters replacement);

  /// Splits this sequence of characters at each occurrence of [pattern].
  ///
  /// Returns a lazy iterable of characters that were separated by [pattern].
  /// The iterable has *at most* [maxParts] elements if a positive [maxParts]
  /// is supplied.
  ///
  /// Finds each occurrence of [pattern], which does not overlap with
  /// a previously found occurrence, then the non-matched characters
  /// before, after, and between the matches are provided in first-to-last
  /// position order.

  /// If [pattern] is empty, the character sequence is split into separate
  /// characters, and no leading or trailing empty ranges are provided
  /// unless the range itself is empty,
  /// in which case a single empty range is the only result range.
  /// Otherwise a range starting or ending with [pattern] will cause
  /// an empty character sequence to be emitted at the start or end.
  ///
  /// If [maxParts] is provided and greater than zero,
  /// only the first `maxParts - 1` occurrences of [pattern] are found
  /// and split at.
  /// Any further occurrences will be included in the last part.
  /// Example:
  /// ```dart
  /// var c = "abracadabra".characters;
  /// var parts = c.split("a".characters, 4).toList();
  /// print(parts); // Prints is ["", "br", "c", "dabra"]
  /// ```
  /// If there are fewer than `maxParts - 1` occurrences of [pattern],
  /// then the characters are split at all occurrences.
  /// If [maxParts] is zero or negative, it is ignored and the result
  /// is split at all occurrences of [pattern].
  Iterable<Characters> split(Characters pattern, [int maxParts = 0]);

  /// Replaces the first occurrence of [pattern] with [replacement].
  ///
  /// Returns a new [Characters] where the first occurence of the
  /// [pattern] character sequence, if any, is replaced by [replacement].
  ///
  /// Returns the current characters if there is no occurrence of [pattern].
  Characters replaceFirst(Characters pattern, Characters replacement);

  /// The characters of the lower-case version of [string].
  Characters toLowerCase();

  /// The characters of the upper-case version of [string].
  Characters toUpperCase();

  /// The hash code of [string].
  @override
  int get hashCode;

  /// Whether [other] to another [Characters] with the same [string].
  @override
  bool operator ==(Object other);

  /// The [string] content of these characters.
  @override
  String toString();
}

/// A range of characters of a [Characters].
///
/// A range of consecutive characters in [source],
/// corresponding to a start and end position in the source sequence.
/// The range may even be empty, but that will still correspond to a position
/// where both start and end happen to be the same position.
///
/// The source sequence can be separated into the *preceeding* characters,
/// those before the range, the range itself, and the *following* characters,
/// those after the range.
///
/// Some operations inspect or act on the characters of the current range,
/// and other operations modify the range by moving the start and/or end
/// position.
///
/// In general, an operation with a name starting with `move` will move
/// both start and end positions, selecting an entirely new range
/// which does not overlap the current range.
/// Operations starting with `collapse` reduces the current range to
/// a sub-range of itself.
/// Operations starting with `expand` increase the current range
/// by moving/ the end postion to a later position
/// or the start position to an earlier position,
/// and operations starting with `drop` reduce the current range
/// by moving the start to a later position or the end to an earlier position,
/// therebyt dropping characters from one or both ends from the current range.
///
///
/// The character range implements [Iterator]
/// The [moveNext] operation, when called with no argument,
/// iterates the *next* single characters of the [source] sequence.
abstract class CharacterRange implements Iterator<String> {
  /// Creates a new character iterator iterating the character
  /// of [string].
  factory CharacterRange(String string) = StringCharacterRange;

  /// Creates a new character iterator on [string].
  ///
  /// The iterator starts with a current range containing the
  /// substring from [startIndex] to [endIndex] of [string].
  /// If [startIndex] is not a character boundary,
  /// the range starts at the beginning of the character
  /// that [startIndex] is pointing into.
  /// If [endIndex] is not a character boundary,
  /// the range end at then end of the character
  /// that [endIndex] is pointing into.
  /// If [endIndex] is not provided,
  /// it defaults to the same index as [startIndex].
  ///
  /// So, if no [endIndex] is provided,
  /// and [startIndex] is at a character boundary,
  /// the resulting iterator's current range is empty.
  /// Otherwise, the range will contain the characters
  /// of the substring from [startIndex] to [endIndex],
  /// extended so that it contains entire characters of the original [string].
  factory CharacterRange.at(String string, int startIndex, [int? endIndex]) =
      StringCharacterRange.at;

  /// The character sequence that this range is a sub-sequence of.
  Characters get source;

  /// The code units of the current character range.
  Iterable<int> get utf16CodeUnits;

  /// The code points of the current character range.
  Runes get runes;

  /// The characters of this range.
  Characters get currentCharacters;

  /// The characters before the current range.
  Characters get charactersBefore;

  /// The characters after the current range.
  Characters get charactersAfter;

  /// The string of the characters before the current range.
  String get stringBefore;

  /// The length, in code units, of [stringBefore].
  int get stringBeforeLength;

  /// The string of the characters after the current range.
  String get stringAfter;

  /// The length, in code units, of [stringAfter].
  int get stringAfterLength;

  /// Creates a copy of this [CharacterRange].
  ///
  /// The copy is in the exact same state as this iterator.
  /// Can be used to iterate the following characters more than once
  /// at the same time. To simply rewind an iterator, remember the
  /// [start] or [end] position and use [reset] to reset the iterator
  /// to that position.
  CharacterRange copy();

  /// Whether the current range is empty.
  ///
  /// An empty range has no characters, but still has a position as
  /// a sub-sequence of the source character sequence.
  bool get isEmpty;

  /// Whether the current range is not empty.
  ///
  /// A non-empty range contains at least one character.
  bool get isNotEmpty;

  /// Moves the range to be the next [count] characters after the current range.
  ///
  /// The new range starts and the end of the current range and includes
  /// the next [count] characters, or as many as available if there
  /// are fewer than [count] characters following the current range.
  ///
  /// The [count] must not be negative.
  /// If it is zero, the call has the same effect as [collapseToEnd].
  ///
  /// Returns `true` if there were [count] following characters
  /// and `false` if not.
  @override
  bool moveNext([int count = 1]);

  /// Moves the range to be everything after the current range.
  void moveNextAll();

  /// Moves the range to the next occurrence of [target]
  /// after the current range.
  ///
  /// If there is an occurrence of [target] in the characters following
  /// the current range,
  /// then the new range contains exactly the first such occurrence of [target].
  ///
  /// If there is no occurrence of [target] after the current range,
  /// the range is not modified.
  ///
  /// Returns `true` if the range is modified and `false` if not.
  bool moveTo(Characters target);

  /// Moves to the range until the next occurrence of [target].
  ///
  /// If there is an occurrence of [target] in the characters following
  /// the current range,
  /// then the new range contains the characters from the end
  /// of the current range until, but no including the first such
  /// occurrence of [target].
  ///
  /// If there is no occurrence of [target] after the current range,
  /// the new range contains all the characters following the current range,
  /// from the end of the current range until the end of the string.
  ///
  /// Returns `true` if there was an occurrence of [target].
  bool moveUntil(Characters target);

  /// Moves the range to be the last [count] characters before the current
  /// range.
  ///
  /// The new range ends at the start of the current range and includes
  /// the previous [count] characters, or as many as available if there
  /// are fewer than [count] characters preceding the current range.
  ///
  /// The [count] must not be negative.
  /// If it is zero, the call has the same effect as [collapseToStart].
  ///
  /// Returns `true` if there were [count] preceding characters
  /// and `false` if not.
  bool moveBack([int count = 1]);

  /// Moves the range to be everything before the current range.
  void moveBackAll();

  /// Moves the range to the last occurrence of [target]
  /// before the current range.
  ///
  /// If there is an occurrence of [target] in the characters preceding
  /// the current range,
  /// then the new range contains exactly the last such occurrence of [target].
  ///
  /// If there is no occurrence of [target] after the current range,
  /// the range is not modified.
  ///
  /// Returns `true` if the range is modified and `false` if not.
  bool moveBackTo(Characters target);

  /// Moves to the range after the previous occurence of [target].
  ///
  /// If there is an occurrence of [target] in the characters preceding
  /// the current range,
  /// then the new range contains the characters after
  /// the last such occurrence, and up to the start of the current range.
  ///
  /// If there is no occurrence of [target] after the current range,
  /// the new range contains all the characters preceding the current range,
  /// from the start of the string to the start of the current range.
  ///
  /// Returns `true` if there was an occurrence of [target].
  bool moveBackUntil(Characters target);

  /// Expands the current range with the next [count] characters.
  ///
  /// Expands the current range to include the first [count] characters
  /// following the current range, or as many as are available if
  /// there are fewer than [count] characters following the current range.
  ///
  /// The [count] must not be negative.
  /// If it is zero, the range does not change.
  ///
  /// Returns `true` if there are at least [count] characters following
  /// the current range, and `false` if not.
  bool expandNext([int count = 1]);

  /// Expands the range to include the next occurence of [target].
  ///
  /// If there is an occurrence of [target] in the characters following
  /// the current range, the end of the the range is moved to just after
  /// the first such occurrence.
  ///
  /// If there is no such occurrence of [target], the range is not modified.
  ///
  /// Returns `true` if there is an occurrence of [target] and `false` if not.
  /// Notice that if [target] is empty,
  /// the result is `true` even though the range is not modified.
  bool expandTo(Characters target);

  /// Expands the range to include characters until the next [target].
  ///
  /// If there is an occurrence of [target] in the characters following
  /// the current range, the end of the the range is moved to just before
  /// the first such occurrence.
  ///
  /// If there is no such occurrence of [target], the end of the range is
  /// moved to the end of [source].
  ///
  /// Returns `true` if there is an occurrence of [target] and `false` if not.
  bool expandUntil(Characters target);

  /// Expands the range with the following characters satisfying [test].
  ///
  /// Iterates through the characters following the current range
  /// and includes them into the range until finding a character that
  /// [test] returns `false` for.
  void expandWhile(bool Function(String) test);

  /// Expands the range to the end of [source].
  void expandAll();

  /// Expands the current range with the preceding [count] characters.
  ///
  /// Expands the current range to include the last [count] characters
  /// preceding the current range, or as many as are available if
  /// there are fewer than [count] characters preceding the current range.
  ///
  /// The [count] must not be negative.
  /// If it is zero, the range does not change.
  ///
  /// Returns `true` if there are at least [count] characters preceding
  /// the current range, and `false` if not.
  bool expandBack([int count = 1]);

  /// Expands the range to include the previous occurence of [target].
  ///
  /// If there is an occurrence of [target] in the characters preceding
  /// the current range, the stat of the the range is moved to just before
  /// the last such occurrence.
  ///
  /// If there is no such occurrence of [target], the range is not modified.
  ///
  /// Returns `true` if there is an occurrence of [target] and `false` if not.
  /// Notice that if [target] is empty,
  /// the result is `true` even though the range is not modified.
  bool expandBackTo(Characters target);

  /// Expands the range to include characters back until the previous [target].
  ///
  /// If there is an occurrence of [target] in the characters preceding
  /// the current range, the start of the the range is moved to just after
  /// the last such occurrence.
  ///
  /// If there is no such occurrence of [target], the end of the range is
  /// moved to the end of [source].
  ///
  /// Returns `true` if there is an occurrence of [target] and `false` if not.
  bool expandBackUntil(Characters target);

  /// Expands the range with the preceding characters satisffying [test].
  ///
  /// Iterates back through the characters preceding the current range
  /// and includes them into the range until finding a character that
  /// [test] returns `false` for.
  void expandBackWhile(bool Function(String) test);

  /// Expands the range back to the start of [source].
  void expandBackAll();

  /// Collapses the range to its start.
  ///
  /// Sets the end of the range to be the same position as the start.
  /// The new range is empty and positioned at the start of the current range.
  void collapseToStart();

  /// Collapses to the first occurrence of [target] in the current range.
  ///
  /// If there is an occurrence of [target] in the characters of the current
  /// range, then the new range contains exactly the characters of the
  /// first such occurrence.
  ///
  /// If there is no such occurrence, the range is not changed.
  ///
  /// Returns `true` if there is an occurrence of [target] and `false` if not.
  bool collapseToFirst(Characters target);

  /// Collapses to the last occurrence of [target] in the current range.
  ///
  /// If there is an occurrence of [target] in the characters of the current
  /// range, then the new range contains exactly the characters of the
  /// last such occurrence.
  ///
  /// If there is no such occurrence, the range is not changed.
  ///
  /// Returns `true` if there is an occurrence of [target] and `false` if not.
  bool collapseToLast(Characters target);

  /// Collapses the range to its end.
  ///
  /// Sets the start of the range to be the same as its end.
  /// The new range is an empty range positioned at the end
  /// of the current range.
  void collapseToEnd();

  /// Drop the first [count] characters from the range.
  ///
  /// Advances the start of the range to after the [count] first characters
  /// of the range, or as many as are available if
  /// there are fewer than [count] characters in the current range.
  ///
  /// The [count] must not be negative.
  /// If it is zero, the range is not changed.
  ///
  /// Returns `true` if there are [count] characters in the range,
  /// and `false` if there are fewer.
  bool dropFirst([int count = 1]);

  /// Drops the first occurrence of [target] in the range.
  ///
  /// If the range contains any occurrences of [target],
  /// then all characters before the end of the first such occurrence
  /// is removed from the range.
  /// This advances the start of the range to the end of the
  /// first occurrence of [target].
  ///
  /// If there are no occurrences of [target] in the range,
  /// the range is not changed.
  ///
  /// Returns `true` if there is an occurrence of [target] and `false` if not.
  bool dropTo(Characters target);

  /// Drops characters from the start of the range until before
  /// the first occurrence of [target].
  ///
  /// If the range contains any occurrences of [target],
  /// then all characters before the start of the first such occurrence
  /// is removed from the range.
  /// This advances the start of the range to the start of the
  /// first occurrence of [target].
  ///
  /// If there are no occurrences of [target] in the range,
  /// all characteres in the range are removed,
  /// which gives the same effect as [collapseToEnd].
  ///
  /// Returns `true` if there is an occurrence of [target] and `false` if not.
  bool dropUntil(Characters target);

  /// Drops characters from the start of the range while they satisfy [test].
  ///
  /// Iterates the characters of the current range from the start
  /// and removes all the iterated characters until one is
  /// reached for which [test] returns `false`.
  /// If on such character is found, all characters are removed,
  /// which gives the same effect as [collapseToEnd].
  void dropWhile(bool Function(String) test);

  /// Drop the last [count] characters from the range.
  ///
  /// Retracts the end of the range to before the [count] last characters
  /// of the range, or as many as are available if
  /// there are fewer than [count] characters in the current range.
  ///
  /// The [count] must not be negative.
  /// If it is zero, the range is not changed.
  ///
  /// Returns `true` if there are [count] characters in the range,
  /// and `false` if there are fewer.
  bool dropLast([int count = 1]);

  /// Drops the last occurrence of [target] in the range.
  ///
  /// If the range contains any occurrences of [target],
  /// then all characters after the start of the first such occurrence
  /// is removed from the range.
  /// This retracts the end of the range to the start of the
  /// last occurrence of [target].
  ///
  /// If there are no occurrences of [target] in the range,
  /// the range is not changed.
  ///
  /// Returns `true` if there is an occurrence of [target] and `false` if not.
  bool dropBackTo(Characters target);

  /// Drops characters from the end of the range until after
  /// the last occurrence of [target].
  ///
  /// If the range contains any occurrences of [target],
  /// then all characters after the end of the last such occurrence
  /// is removed from the range.
  /// This retracts the end of the range to the end of the
  /// last occurrence of [target].
  ///
  /// If there are no occurrences of [target] in the range,
  /// all characteres in the range are removed,
  /// which gives the same effect as [collapseToStart].
  ///
  /// Returns `true` if there is an occurrence of [target] and `false` if not.
  bool dropBackUntil(Characters target);

  /// Drops characters from the end of the range while they satisfy [test].
  ///
  /// Iterates the characters of the current range backwards from the end
  /// and removes all the iterated characters until one is
  /// reached for which [test] returns `false`.
  /// If on such character is found, all characters are removed,
  /// which gives the same effect as [collapseToStart].
  void dropBackWhile(bool Function(String) test);

  /// Replaces the current range with [replacement] and returns the result.
  ///
  /// Replaces the current range in [source] with [replacement]
  /// and returns a range of the resulting characters
  /// which contains the replacement characters.
  ///
  /// The inserted characters may combine with
  /// the preceding or following code points,
  /// so that the start and end of the original range
  /// are no longer grapheme cluster boundaries.
  /// In that case, the returned range may extend into into the code points
  /// before and after the original range.
  CharacterRange replaceRange(Characters replacement);

  /// Replaces [pattern] in the current range with [replacement].
  ///
  /// Replaces all occurrences of [pattern] in the current range with
  /// [replacement], unless they overlap with an earlier occurrence of
  /// [pattern] which was replaced.
  /// Then returns a range on the resulting characters
  /// which contains all inserted replacement characters
  /// and any remaining characters of the original range.
  ///
  /// The inserted characters may combine with
  /// the preceding or following code points,
  /// so that the start and end of the original range
  /// are no longer grapheme cluster boundaries.
  /// In that case, the returned range may extend into into the code points
  /// before and after the original range.
  ///
  /// Returns `null` if there are no occurrences of [pattern]
  /// in the current range.
  CharacterRange? replaceAll(Characters pattern, Characters replacement);

  /// Splits the current range of characters at each occurrence of [pattern].
  ///
  /// Returns a lazy iterable of character ranges that were separated by
  /// [pattern].
  /// Each provided character range object is new
  /// and unrelated to this character range
  /// The iterable has *at most* [maxParts] elements if a positive [maxParts]
  /// is supplied.
  ///
  /// Finds each occurrence of [pattern] in the range, which does not overlap
  /// with a previously found occurrence, then the non-matched characters
  /// of the range before, after and between the matches are provided
  /// in first-to-last position order.
  ///
  /// If [pattern] is empty, the range is split into separate characters,
  /// and no leading or trailing empty ranges are provided unless the
  /// range itself is empty, in which case a single empty range is the
  /// only result range.
  /// Otherwise a range starting or ending with [pattern] will cause
  /// an empty range to be emitted at the start or end.
  ///
  /// If [maxParts] is provided and greater than zero,
  /// only the first `maxParts - 1` occurrences of [pattern] are found
  /// and split at.
  /// Any further occurrences will be included in the last part.
  ///
  /// Example:
  /// ```dart
  /// var c = "abracadabra".characters.dropFirst().dropLast();
  /// // c is "bracadabr".
  /// var parts = c.split("a".characters, 3).toList();
  /// print(parts); // [br, c, dabr]
  /// ```
  /// If there are fewer than `maxParts - 1` occurrences of [pattern],
  /// then the characters are split at all occurrences.
  /// If [maxParts] is zero or negative, it is ignored and the result
  /// is split at all occurrences of [pattern].
  Iterable<CharacterRange> split(Characters pattern, [int maxParts = 0]);

  /// Replaces the first occurrence of [pattern] with [replacement].
  ///
  /// Finds the first occurrence of [pattern] in the current range,
  /// then replaces that occurrence with [replacement].
  /// Then returns a range on the resulting characters
  /// which contains the inserted replacement characters
  /// and any remaining characters of the original range.
  ///
  /// The inserted characters may combine with
  /// the preceding or following code points,
  /// so that the start and end of the original range
  /// are no longer grapheme cluster boundaries.
  /// In that case, the returned range may extend into into the code points
  /// before and after the original range.
  ///
  /// Returns `null` if there are no occurrences of [pattern]
  /// in the current range.
  CharacterRange? replaceFirst(Characters pattern, Characters replacement);

  /// Whether the current range starts with [characters].
  ///
  /// Returns `true` if the characters of the current range starts with
  /// [characters], `false` if not.
  bool startsWith(Characters characters);

  /// Whether the current range ends with [characters].
  ///
  /// Returns `true` if the characters of the current range ends with
  /// [characters], `false` if not.
  bool endsWith(Characters characters);

  /// Whether the current range is preceded by [characters].
  ///
  /// Returns `true` if the characters immediately preceding the current
  /// range are [characters], and `false` if not.
  bool isPrecededBy(Characters characters);

  /// Whether the current range is followed by [characters].
  ///
  /// Returns `true` if the characters immediately following the current
  /// range are [characters], and `false` if not.
  bool isFollowedBy(Characters characters);
}
