// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// A sequence of UTF-16 code units.
///
/// Strings are mainly used to represent text. A character may be represented by
/// multiple code points, each code point consisting of one or two code
/// units. For example, the Papua New Guinea flag character requires four code
/// units to represent two code points, but should be treated like a single
/// character: "🇵🇬". Platforms that do not support the flag character may show
/// the letters "PG" instead. If the code points are swapped, it instead becomes
/// the Guadeloupe flag "🇬🇵" ("GP").
///
/// A string can be either single or multiline. Single line strings are
/// written using matching single or double quotes, and multiline strings are
/// written using triple quotes. The following are all valid Dart strings:
/// ```dart
/// 'Single quotes';
/// "Double quotes";
/// 'Double quotes in "single" quotes';
/// "Single quotes in 'double' quotes";
///
/// '''A
/// multiline
/// string''';
///
/// """
/// Another
/// multiline
/// string""";
/// ```
/// Strings are immutable. Although you cannot change a string, you can perform
/// an operation on a string which creates a new string:
/// ```dart
/// const string = 'Dart is fun';
/// print(string.substring(0, 4)); // 'Dart'
/// ```
/// You can use the plus (`+`) operator to concatenate strings:
/// ```dart
/// const string = 'Dart ' + 'is ' + 'fun!';
/// print(string); // 'Dart is fun!'
/// ```
/// Adjacent string literals are concatenated automatically:
/// ```dart
/// const string = 'Dart ' 'is ' 'fun!';
/// print(string); // 'Dart is fun!'
/// ```
/// You can use `${}` to interpolate the value of Dart expressions
/// within strings. The curly braces can be omitted when evaluating identifiers:
/// ```dart
/// const string = 'dartlang';
/// print('$string has ${string.length} letters'); // dartlang has 8 letters
/// ```
/// A string is represented by a sequence of Unicode UTF-16 code units
/// accessible through the [codeUnitAt] or the [codeUnits] members:
/// ```dart
/// const string = 'Dart';
/// final firstCodeUnit = string.codeUnitAt(0);
/// print(firstCodeUnit); // 68, aka U+0044, the code point for 'D'.
/// final allCodeUnits = string.codeUnits;
/// print(allCodeUnits); // [68, 97, 114, 116]
/// ```
/// A string representation of the individual code units is accessible through
/// the index operator:
/// ```dart
/// const string = 'Dart';
/// final charAtIndex = string[0];
/// print(charAtIndex); // 'D'
/// ```
/// The characters of a string are encoded in UTF-16. Decoding UTF-16, which
/// combines surrogate pairs, yields Unicode code points. Following a similar
/// terminology to Go, Dart uses the name 'rune' for an integer representing a
/// Unicode code point. Use the [runes] property to get the runes of a string:
/// ```dart
/// const string = 'Dart';
/// final runes = string.runes.toList();
/// print(runes); // [68, 97, 114, 116]
/// ```
/// For a character outside the Basic Multilingual Plane (plane 0) that is
/// composed of a surrogate pair, [runes] combines the pair and returns a
/// single integer. For example, the Unicode character for a
/// musical G-clef ('𝄞') with rune value 0x1D11E consists of a UTF-16 surrogate
/// pair: `0xD834` and `0xDD1E`. Using [codeUnits] returns the surrogate pair,
/// and using `runes` returns their combined value:
/// ```dart
/// const clef = '\u{1D11E}';
/// for (final item in clef.codeUnits) {
///   print(item.toRadixString(16));
///   // d834
///   // dd1e
/// }
/// for (final item in clef.runes) {
///   print(item.toRadixString(16)); // 1d11e
/// }
/// ```
/// The `String` class cannot be extended or implemented. Attempting to do so
/// yields a compile-time error.
///
/// ## Other resources
///
/// * [StringBuffer] to efficiently build a string incrementally.
/// * [RegExp] to work with regular expressions.
/// * [Strings and regular expressions](https://dart.dev/guides/libraries/library-tour#strings-and-regular-expressions)
@pragma('vm:entry-point')
abstract final class String implements Comparable<String>, Pattern {
  /// Allocates a new string containing the specified [charCodes].
  ///
  /// The [charCodes] can be both UTF-16 code units and runes.
  /// If a char-code value is 16-bit, it is used as a code unit:
  /// ```dart
  /// final string = String.fromCharCodes([68]);
  /// print(string); // D
  /// ```
  /// If a char-code value is greater than 16-bits, it is decomposed into a
  /// surrogate pair:
  /// ```dart
  /// final clef = String.fromCharCodes([0x1D11E]);
  /// clef.codeUnitAt(0); // 0xD834
  /// clef.codeUnitAt(1); // 0xDD1E
  /// ```
  /// If [start] and [end] are provided, only the values of [charCodes]
  /// at positions from `start` to, but not including, `end`, are used.
  /// The `start` and `end` values must satisfy `0 <= start <= end`.
  /// If [start] is omitted, it defaults to zero, the start of [charCodes],
  /// and if [end] is omitted, all char-codes after [start] are included.
  /// If [charCodes] does not have [end], or even [start], elements,
  /// the specified char-codes may be shorter than `end - start`, or even empty.
  external factory String.fromCharCodes(Iterable<int> charCodes,
      [int start = 0, int? end]);

  /// Allocates a new string containing the specified [charCode].
  ///
  /// If the [charCode] can be represented by a single UTF-16 code unit, the new
  /// string contains a single code unit. Otherwise, the [length] is 2 and
  /// the code units form a surrogate pair. See documentation for
  /// [fromCharCodes].
  ///
  /// Creating a [String] with one half of a surrogate pair is allowed.
  external factory String.fromCharCode(int charCode);

  /// Value for [name] in the compilation configuration environment declaration.
  ///
  /// The compilation configuration environment is provided by the
  /// surrounding tools which are compiling or running the Dart program.
  /// The environment is a mapping from a set of string keys to their associated
  /// string value.
  /// The string value, or lack of a value, associated with a [name]
  /// must be consistent across all calls to `String.fromEnvironment`,
  /// [int.fromEnvironment], [bool.fromEnvironment] and [bool.hasEnvironment]
  /// in a single program.
  ///
  /// The result of invoking this constructor is the string associated with
  /// the key [name]. If no value is associated with [name],
  /// the result is instead the [defaultValue] string, which defaults to
  /// the empty string.
  ///
  /// Example of looking up a value:
  /// ```dart
  /// const String.fromEnvironment("defaultFloo", defaultValue: "no floo")
  /// ```
  /// In order to check whether a value is there at all, use
  /// [bool.hasEnvironment]. Example:
  /// ```dart
  /// const maybeDeclared = bool.hasEnvironment("maybeDeclared")
  ///     ? String.fromEnvironment("maybeDeclared")
  ///     : null;
  /// ```
  ///
  /// The string value, or lack of a value, associated with a [name]
  /// must be consistent across all calls to `String.fromEnvironment`,
  /// [int.fromEnvironment], [bool.fromEnvironment] and [bool.hasEnvironment]
  /// in a single program.
  ///
  /// This constructor is only guaranteed to work when invoked as `const`.
  /// It may work as a non-constant invocation on some platforms which
  /// have access to compiler options at run-time, but most ahead-of-time
  /// compiled platforms will not have this information.
  ///
  /// The compilation configuration environment is not the same as the
  /// environment variables of a POSIX process. Those can be accessed on
  /// native platforms using `Platform.environment` from the `dart:io` library.
  external const factory String.fromEnvironment(String name,
      {String defaultValue = ""});

  /// The character (as a single-code-unit [String]) at the given [index].
  ///
  /// The returned string represents exactly one UTF-16 code unit, which may be
  /// half of a surrogate pair. A single member of a surrogate pair is an
  /// invalid UTF-16 string:
  /// ```dart
  /// var clef = '\u{1D11E}';
  /// // These represent invalid UTF-16 strings.
  /// clef[0].codeUnits;      // [0xD834]
  /// clef[1].codeUnits;      // [0xDD1E]
  /// ```
  /// This method is equivalent to
  /// `String.fromCharCode(this.codeUnitAt(index))`.
  String operator [](int index);

  /// Returns the 16-bit UTF-16 code unit at the given [index].
  int codeUnitAt(int index);

  /// The length of the string.
  ///
  /// Returns the number of UTF-16 code units in this string. The number
  /// of [runes] might be fewer if the string contains characters outside
  /// the Basic Multilingual Plane (plane 0):
  /// ```dart
  /// 'Dart'.length;          // 4
  /// 'Dart'.runes.length;    // 4
  ///
  /// var clef = '\u{1D11E}';
  /// clef.length;            // 2
  /// clef.runes.length;      // 1
  /// ```
  int get length;

  /// A hash code derived from the code units of the string.
  ///
  /// This is compatible with [operator ==]. Strings with the same sequence
  /// of code units have the same hash code.
  int get hashCode;

  /// Whether [other] is a `String` with the same sequence of code units.
  ///
  /// This method compares each individual code unit of the strings.
  /// It does not check for Unicode equivalence.
  /// For example, both the following strings represent the string 'Amélie',
  /// but due to their different encoding, are not equal:
  /// ```dart
  /// 'Am\xe9lie' == 'Ame\u{301}lie'; // false
  /// ```
  /// The first string encodes 'é' as a single unicode code unit (also
  /// a single rune), whereas the second string encodes it as 'e' with the
  /// combining accent character '◌́'.
  bool operator ==(Object other);

  /// Compares this string to [other].
  ///
  /// Returns a negative value if `this` is ordered before `other`,
  /// a positive value if `this` is ordered after `other`,
  /// or zero if `this` and `other` are equivalent.
  ///
  /// The ordering is the same as the ordering of the code units at the first
  /// position where the two strings differ.
  /// If one string is a prefix of the other,
  /// then the shorter string is ordered before the longer string.
  /// If the strings have exactly the same content, they are equivalent with
  /// regard to the ordering.
  /// Ordering does not check for Unicode equivalence.
  /// The comparison is case sensitive.
  /// ```dart
  /// var relation = 'Dart'.compareTo('Go');
  /// print(relation); // < 0
  /// relation = 'Go'.compareTo('Forward');
  /// print(relation); // > 0
  /// relation = 'Forward'.compareTo('Forward');
  /// print(relation); // 0
  /// ```
  int compareTo(String other);

  /// Whether this string ends with [other].
  ///
  /// For example:
  /// ```dart
  /// const string = 'Dart is open source';
  /// print(string.endsWith('urce')); // true
  /// ```
  bool endsWith(String other);

  /// Whether this string starts with a match of [pattern].
  ///
  /// ```dart
  /// const string = 'Dart is open source';
  /// print(string.startsWith('Dar')); // true
  /// print(string.startsWith(RegExp(r'[A-Z][a-z]'))); // true
  /// ```
  /// If [index] is provided, this method checks if the substring starting
  /// at that index starts with a match of [pattern]:
  /// ```dart
  /// const string = 'Dart';
  /// print(string.startsWith('art', 0)); // false
  /// print(string.startsWith('art', 1)); // true
  /// print(string.startsWith(RegExp(r'\w{3}'), 2)); // false
  /// ```
  /// [index] must not be negative or greater than [length].
  ///
  /// A [RegExp] containing '^' does not match if the [index] is greater than
  /// zero and the regexp is not multi-line.
  /// The pattern works on the string as a whole, and does not extract
  /// a substring starting at [index] first:
  /// ```dart
  /// const string = 'Dart';
  /// print(string.startsWith(RegExp(r'^art'), 1)); // false
  /// print(string.startsWith(RegExp(r'art'), 1)); // true
  /// ```
  bool startsWith(Pattern pattern, [int index = 0]);

  /// Returns the position of the first match of [pattern] in this string,
  /// starting at [start], inclusive:
  /// ```dart
  /// const string = 'Dartisans';
  /// print(string.indexOf('art')); // 1
  /// print(string.indexOf(RegExp(r'[A-Z][a-z]'))); // 0
  /// ```
  /// Returns -1 if no match is found:
  /// ```dart
  /// const string = 'Dartisans';
  /// string.indexOf(RegExp(r'dart')); // -1
  /// ```
  /// The [start] must be non-negative and not greater than [length].
  int indexOf(Pattern pattern, [int start = 0]);

  /// The starting position of the last match [pattern] in this string.
  ///
  /// Finds a match of pattern by searching backward starting at [start]:
  /// ```dart
  /// const string = 'Dartisans';
  /// print(string.lastIndexOf('a')); // 6
  /// print(string.lastIndexOf(RegExp(r'a(r|n)'))); // 6
  /// ```
  /// Returns -1 if [pattern] could not be found in this string.
  /// ```dart
  /// const string = 'Dartisans';
  /// print(string.lastIndexOf(RegExp(r'DART'))); // -1
  /// ```
  /// If [start] is omitted, search starts from the end of the string.
  /// If supplied, [start] must be non-negative and not greater than [length].
  int lastIndexOf(Pattern pattern, [int? start]);

  /// Whether this string is empty.
  bool get isEmpty;

  /// Whether this string is not empty.
  bool get isNotEmpty;

  /// Creates a new string by concatenating this string with [other].
  ///
  /// Example:
  /// ```dart
  /// const string = 'dart' + 'lang'; // 'dartlang'
  /// ```
  String operator +(String other);

  /// The substring of this string from [start], inclusive, to [end], exclusive.
  ///
  /// Example:
  /// ```dart
  /// const string = 'dartlang';
  /// var result = string.substring(1); // 'artlang'
  /// result = string.substring(1, 4); // 'art'
  /// ```
  ///
  /// Both [start] and [end] must be non-negative and no greater than [length];
  /// [end], if provided, must be greater than or equal to [start].
  String substring(int start, [int? end]);

  /// The string without any leading and trailing whitespace.
  ///
  /// If the string contains leading or trailing whitespace, a new string with no
  /// leading and no trailing whitespace is returned:
  /// ```dart
  /// final trimmed = '\tDart is fun\n'.trim();
  /// print(trimmed); // 'Dart is fun'
  /// ```
  /// Otherwise, the original string itself is returned:
  /// ```dart
  /// const string1 = 'Dart';
  /// final string2 = string1.trim(); // 'Dart'
  /// print(identical(string1, string2)); // true
  /// ```
  /// Whitespace is defined by the Unicode White_Space property (as defined in
  /// version 6.2 or later) and the BOM character, 0xFEFF.
  ///
  /// Here is the list of trimmed characters according to Unicode version 6.3:
  /// ```plaintext
  ///     0009..000D    ; White_Space # Cc   <control-0009>..<control-000D>
  ///     0020          ; White_Space # Zs   SPACE
  ///     0085          ; White_Space # Cc   <control-0085>
  ///     00A0          ; White_Space # Zs   NO-BREAK SPACE
  ///     1680          ; White_Space # Zs   OGHAM SPACE MARK
  ///     2000..200A    ; White_Space # Zs   EN QUAD..HAIR SPACE
  ///     2028          ; White_Space # Zl   LINE SEPARATOR
  ///     2029          ; White_Space # Zp   PARAGRAPH SEPARATOR
  ///     202F          ; White_Space # Zs   NARROW NO-BREAK SPACE
  ///     205F          ; White_Space # Zs   MEDIUM MATHEMATICAL SPACE
  ///     3000          ; White_Space # Zs   IDEOGRAPHIC SPACE
  ///
  ///     FEFF          ; BOM                ZERO WIDTH NO_BREAK SPACE
  /// ```
  /// Some later versions of Unicode do not include U+0085 as a whitespace
  /// character. Whether it is trimmed depends on the Unicode version
  /// used by the system.
  String trim();

  /// The string without any leading whitespace.
  ///
  /// As [trim], but only removes leading whitespace.
  /// ```dart
  /// final string = ' Dart '.trimLeft();
  /// print(string); // 'Dart '
  /// ```
  String trimLeft();

  /// The string without any trailing whitespace.
  ///
  /// As [trim], but only removes trailing whitespace.
  /// ```dart
  /// final string = ' Dart '.trimRight();
  /// print(string); // ' Dart'
  /// ```
  String trimRight();

  /// Creates a new string by concatenating this string with itself a number
  /// of times.
  ///
  /// The result of `str * n` is equivalent to
  /// `str + str + ...`(n times)`... + str`.
  ///
  /// ```dart
  /// const string = 'Dart';
  /// final multiplied = string * 3;
  /// print(multiplied); // 'DartDartDart'
  /// ```
  /// Returns an empty string if [times] is zero or negative.
  String operator *(int times);

  /// Pads this string on the left if it is shorter than [width].
  ///
  /// Returns a new string that prepends [padding] onto this string
  /// one time for each position the length is less than [width].
  ///
  /// ```dart
  /// const string = 'D';
  /// print(string.padLeft(4)); // '   D'
  /// print(string.padLeft(2, 'x')); // 'xD'
  /// print(string.padLeft(4, 'y')); // 'yyyD'
  /// print(string.padLeft(4, '>>')); // '>>>>>>D'
  /// ```
  ///
  /// If [width] is already smaller than or equal to `this.length`,
  /// no padding is added. A negative `width` is treated as zero.
  ///
  /// If [padding] has length different from 1, the result will not
  /// have length `width`. This may be useful for cases where the
  /// padding is a longer string representing a single character, like
  /// `"&nbsp;"` or `"\u{10002}`".
  /// In that case, the user should make sure that `this.length` is
  /// the correct measure of the string's length.
  String padLeft(int width, [String padding = ' ']);

  /// Pads this string on the right if it is shorter than [width].
  ///
  /// Returns a new string that appends [padding] after this string
  /// one time for each position the length is less than [width].
  ///
  /// ```dart
  /// const string = 'D';
  /// print(string.padRight(4)); // 'D    '
  /// print(string.padRight(2, 'x')); // 'Dx'
  /// print(string.padRight(4, 'y')); // 'Dyyy'
  /// print(string.padRight(4, '>>')); // 'D>>>>>>'
  /// ```
  ///
  /// If [width] is already smaller than or equal to `this.length`,
  /// no padding is added. A negative `width` is treated as zero.
  ///
  /// If [padding] has length different from 1, the result will not
  /// have length `width`. This may be useful for cases where the
  /// padding is a longer string representing a single character, like
  /// `"&nbsp;"` or `"\u{10002}`".
  /// In that case, the user should make sure that `this.length` is
  /// the correct measure of the string's length.
  String padRight(int width, [String padding = ' ']);

  /// Whether this string contains a match of [other].
  ///
  /// Example:
  /// ```dart
  /// const string = 'Dart strings';
  /// final containsD = string.contains('D'); // true
  /// final containsUpperCase = string.contains(RegExp(r'[A-Z]')); // true
  /// ```
  /// If [startIndex] is provided, this method matches only at or after that
  /// index:
  /// ```dart
  /// const string = 'Dart strings';
  /// final containsD = string.contains(RegExp('D'), 0); // true
  /// final caseSensitive = string.contains(RegExp(r'[A-Z]'), 1); // false
  /// ```
  /// The [startIndex] must not be negative or greater than [length].
  bool contains(Pattern other, [int startIndex = 0]);

  /// Creates a new string with the first occurrence of [from] replaced by [to].
  ///
  /// Finds the first match of [from] in this string, starting from [startIndex],
  /// and creates a new string where that match is replaced with the [to] string.
  ///
  /// Example:
  /// ```dart
  /// '0.0001'.replaceFirst(RegExp(r'0'), ''); // '.0001'
  /// '0.0001'.replaceFirst(RegExp(r'0'), '7', 1); // '0.7001'
  /// ```
  String replaceFirst(Pattern from, String to, [int startIndex = 0]);

  /// Replace the first occurrence of [from] in this string.
  ///
  /// ```dart
  /// const string = 'Dart is fun';
  /// print(string.replaceFirstMapped(
  ///     'fun', (m) => 'open source')); // Dart is open source
  ///
  /// print(string.replaceFirstMapped(
  ///     RegExp(r'\w(\w*)'), (m) => '<${m[0]}-${m[1]}>')); // <Dart-art> is fun
  /// ```
  ///
  /// Returns a new string, which is this string
  /// except that the first match of [from], starting from [startIndex],
  /// is replaced by the result of calling [replace] with the match object.
  ///
  /// The [startIndex] must be non-negative and no greater than [length].
  String replaceFirstMapped(Pattern from, String replace(Match match),
      [int startIndex = 0]);

  /// Replaces all substrings that match [from] with [replace].
  ///
  /// Creates a new string in which the non-overlapping substrings matching
  /// [from] (the ones iterated by `from.allMatches(thisString)`) are replaced
  /// by the literal string [replace].
  /// ```dart
  /// 'resume'.replaceAll(RegExp(r'e'), 'é'); // 'résumé'
  /// ```
  /// Notice that the [replace] string is not interpreted. If the replacement
  /// depends on the match (for example, on a [RegExp]'s capture groups), use
  /// the [replaceAllMapped] method instead.
  String replaceAll(Pattern from, String replace);

  /// Replace all substrings that match [from] by a computed string.
  ///
  /// Creates a new string in which the non-overlapping substrings that match
  /// [from] (the ones iterated by `from.allMatches(thisString)`) are replaced
  /// by the result of calling [replace] on the corresponding [Match] object.
  ///
  /// This can be used to replace matches with new content that depends on the
  /// match, unlike [replaceAll] where the replacement string is always the same.
  ///
  /// The [replace] function is called with the [Match] generated
  /// by the pattern, and its result is used as replacement.
  ///
  /// The function defined below converts each word in a string to simplified
  /// 'pig latin' using [replaceAllMapped]:
  /// ```dart
  /// String pigLatin(String words) => words.replaceAllMapped(
  ///     RegExp(r'\b(\w*?)([aeiou]\w*)', caseSensitive: false),
  ///     (Match m) => "${m[2]}${m[1]}${m[1]!.isEmpty ? 'way' : 'ay'}");
  ///
  /// final result = pigLatin('I have a secret now!');
  /// print(result); // 'Iway avehay away ecretsay ownay!'
  /// ```
  String replaceAllMapped(Pattern from, String Function(Match match) replace);

  /// Replaces the substring from [start] to [end] with [replacement].
  ///
  /// Creates a new string equivalent to:
  /// ```dart
  /// this.substring(0, start) + replacement + this.substring(end)
  /// ```
  /// Example:
  /// ```dart
  /// const string = 'Dart is fun';
  /// final result = string.replaceRange(8, null, 'open source');
  /// print(result); // Dart is open source
  /// ```
  /// The [start] and [end] indices must specify a valid range of this string.
  /// That is `0 <= start <= end <= this.length`.
  /// If [end] is `null`, it defaults to [length].
  String replaceRange(int start, int? end, String replacement);

  /// Splits the string at matches of [pattern] and returns a list of substrings.
  ///
  /// Finds all the matches of `pattern` in this string,
  /// as by using [Pattern.allMatches],
  /// and returns the list of the substrings between the matches,
  /// before the first match, and after the last match.
  /// ```dart
  /// const string = 'Hello world!';
  /// final splitted = string.split(' ');
  /// print(splitted); // [Hello, world!];
  /// ```
  /// If the pattern doesn't match this string at all,
  /// the result is always a list containing only the original string.
  ///
  /// If the [pattern] is a [String], then it's always the case that:
  /// ```dart
  /// string.split(pattern).join(pattern) == string
  /// ```
  ///
  /// If the first match is an empty match at the start of the string,
  /// the empty substring before it is not included in the result.
  /// If the last match is an empty match at the end of the string,
  /// the empty substring after it is not included in the result.
  /// If a match is empty, and it immediately follows a previous
  /// match (it starts at the position where the previous match ended),
  /// then the empty substring between the two matches is not
  /// included in the result.
  /// ```dart
  /// const string = 'abba';
  /// final re = RegExp(r'b*');
  /// // re.allMatches(string) will find four matches:
  /// // * empty match before first "a".
  /// // * match of "bb"
  /// // * empty match after "bb", before second "a"
  /// // * empty match after second "a".
  /// print(string.split(re)); // [a, a]
  /// ```
  ///
  /// A non-empty match at the start or end of the string, or after another
  /// match, is not treated specially, and will introduce empty substrings
  /// in the result:
  /// ```dart
  /// const string = 'abbaa';
  /// final splitted = string.split('a'); // ['', 'bb', '', '']
  /// ```
  ///
  /// If this string is the empty string, the result is an empty list
  /// if `pattern` matches the empty string, since the empty string
  /// before and after the first-and-last empty match are not included.
  /// (It is still a list containing the original empty string `[""]`
  /// if the pattern doesn't match).
  /// ```dart
  /// const string = '';
  /// print(string.split('')); // []
  /// print(string.split('a')); // []
  /// ```
  ///
  /// Splitting with an empty pattern splits the string into single-code unit
  /// strings.
  /// ```dart
  /// const string = 'Pub';
  /// print(string.split('')); // [P, u, b]
  ///
  /// // Same as:
  /// var codeUnitStrings = [
  ///   for (final unit in string.codeUnits) String.fromCharCode(unit)
  /// ];
  /// print(codeUnitStrings); // [P, u, b]
  /// ```
  ///
  /// Splitting happens at UTF-16 code unit boundaries,
  /// and not at rune (Unicode code point) boundaries:
  /// ```dart
  /// // String made up of two code units, but one rune.
  /// const string = '\u{1D11E}';
  /// final splitted = string.split('');
  /// print(splitted); // ['\ud834', '\udd1e'] - 2 unpaired surrogate values
  /// ```
  /// To get a list of strings containing the individual runes of a string,
  /// you should not use split.
  /// You can instead get a string for each rune as follows:
  /// ```dart
  /// const string = '\u{1F642}';
  /// for (final rune in string.runes) {
  ///   print(String.fromCharCode(rune));
  /// }
  /// ```
  List<String> split(Pattern pattern);

  /// Splits the string, converts its parts, and combines them into a new
  /// string.
  ///
  /// The [pattern] is used to split the string
  /// into parts and separating matches.
  /// Each match of [Pattern.allMatches] of [pattern] on this string is
  /// used as a match, and the substrings between the end of one match
  /// (or the start of the string) and the start of the next match (or the
  /// end of the string) is treated as a non-matched part.
  /// (There is no omission of leading or trailing empty matchs, like
  /// in [split], all matches and parts between the are included.)
  ///
  /// Each match is converted to a string by calling [onMatch]. If [onMatch]
  /// is omitted, the matched substring is used.
  ///
  /// Each non-matched part is converted to a string by a call to [onNonMatch].
  /// If [onNonMatch] is omitted, the non-matching substring itself is used.
  ///
  /// Then all the converted parts are concatenated into the resulting string.
  /// ```dart
  /// final result = 'Eats shoots leaves'.splitMapJoin(RegExp(r'shoots'),
  ///     onMatch: (m) => '${m[0]}', // (or no onMatch at all)
  ///     onNonMatch: (n) => '*');
  /// print(result); // *shoots*
  /// ```
  String splitMapJoin(Pattern pattern,
      {String Function(Match)? onMatch, String Function(String)? onNonMatch});

  /// An unmodifiable list of the UTF-16 code units of this string.
  List<int> get codeUnits;

  /// An [Iterable] of Unicode code-points of this string.
  ///
  /// If the string contains surrogate pairs, they are combined and returned
  /// as one integer by this iterator. Unmatched surrogate halves are treated
  /// like valid 16-bit code-units.
  Runes get runes;

  /// Converts all characters in this string to lower case.
  ///
  /// If the string is already in all lower case, this method returns `this`.
  /// ```dart
  /// 'ALPHABET'.toLowerCase(); // 'alphabet'
  /// 'abc'.toLowerCase(); // 'abc'
  /// ```
  /// This function uses the language independent Unicode mapping and thus only
  /// works in some languages.
  // TODO(floitsch): document better. (See EcmaScript for description).
  String toLowerCase();

  /// Converts all characters in this string to upper case.
  ///
  /// If the string is already in all upper case, this method returns `this`.
  /// ```dart
  /// 'alphabet'.toUpperCase(); // 'ALPHABET'
  /// 'ABC'.toUpperCase(); // 'ABC'
  /// ```
  /// This function uses the language independent Unicode mapping and thus only
  /// works in some languages.
  // TODO(floitsch): document better. (See EcmaScript for description).
  String toUpperCase();
}

/// The runes (integer Unicode code points) of a [String].
///
/// The characters of a string are encoded in UTF-16. Decoding UTF-16, which
/// combines surrogate pairs, yields Unicode code points. Following a similar
/// terminology to Go, Dart uses the name 'rune' for an integer representing a
/// Unicode code point. Use the `runes` property to get the runes of a string.
///
/// Example:
/// ```dart
/// const string = 'Dart';
/// final runes = string.runes.toList();
/// print(runes); // [68, 97, 114, 116]
/// ```
///
/// For a character outside the Basic Multilingual Plane (plane 0) that is
/// composed of a surrogate pair, runes combines the pair and returns a
/// single integer.
///
/// For example, the Unicode character for "Man" emoji ('👨', `U+1F468`) is
/// combined from the surrogates `U+d83d` and `U+dc68`.
///
/// Example:
/// ```dart
/// const emojiMan = '👨';
/// print(emojiMan.runes); // (128104)
///
/// // Surrogate pairs:
/// for (final item in emojiMan.codeUnits) {
///   print(item.toRadixString(16));
///   // d83d
///   // dc68
/// }
/// ```
///
/// **See also:**
/// * [Runes and grapheme clusters](
/// https://dart.dev/guides/language/language-tour#runes-and-grapheme-clusters)
/// in
/// [A tour of the Dart language](https://dart.dev/guides/language/language-tour).
final class Runes extends Iterable<int> {
  /// The string that this is the runes of.
  final String string;

  /// Creates a [Runes] iterator for [string].
  Runes(this.string);

  RuneIterator get iterator => RuneIterator(string);

  int get last {
    if (string.length == 0) {
      throw StateError('No elements.');
    }
    int length = string.length;
    int code = string.codeUnitAt(length - 1);
    if (_isTrailSurrogate(code) && string.length > 1) {
      int previousCode = string.codeUnitAt(length - 2);
      if (_isLeadSurrogate(previousCode)) {
        return _combineSurrogatePair(previousCode, code);
      }
    }
    return code;
  }
}

// Is then code (a 16-bit unsigned integer) a UTF-16 lead surrogate.
bool _isLeadSurrogate(int code) => (code & 0xFC00) == 0xD800;

// Is then code (a 16-bit unsigned integer) a UTF-16 trail surrogate.
bool _isTrailSurrogate(int code) => (code & 0xFC00) == 0xDC00;

// Combine a lead and a trail surrogate value into a single code point.
int _combineSurrogatePair(int start, int end) {
  return 0x10000 + ((start & 0x3FF) << 10) + (end & 0x3FF);
}

/// [Iterator] for reading runes (integer Unicode code points) of a Dart string.
final class RuneIterator implements Iterator<int> {
  /// String being iterated.
  final String string;

  /// Position before the current code point.
  int _position;

  /// Position after the current code point.
  int _nextPosition;

  /// Current code point.
  ///
  /// If the iterator has hit either end, the [_currentCodePoint] is -1
  /// and `_position == _nextPosition`.
  int _currentCodePoint = -1;

  /// Create an iterator positioned at the beginning of the string.
  RuneIterator(String string)
      : this.string = string,
        _position = 0,
        _nextPosition = 0;

  /// Create an iterator positioned before the [index]th code unit of the string.
  ///
  /// When created, there is no [current] value.
  /// A [moveNext] will use the rune starting at [index] the current value,
  /// and a [movePrevious] will use the rune ending just before [index] as
  /// the current value.
  ///
  /// The [index] position must not be in the middle of a surrogate pair.
  RuneIterator.at(String string, int index)
      : string = string,
        _position = index,
        _nextPosition = index {
    RangeError.checkValueInInterval(index, 0, string.length);
    _checkSplitSurrogate(index);
  }

  /// Throw an error if the index is in the middle of a surrogate pair.
  void _checkSplitSurrogate(int index) {
    if (index > 0 &&
        index < string.length &&
        _isLeadSurrogate(string.codeUnitAt(index - 1)) &&
        _isTrailSurrogate(string.codeUnitAt(index))) {
      throw ArgumentError('Index inside surrogate pair: $index');
    }
  }

  /// The starting position of the current rune in the string.
  ///
  /// Returns -1 if there is no current rune ([current] is -1).
  int get rawIndex => (_position != _nextPosition) ? _position : -1;

  /// Resets the iterator to the rune at the specified index of the string.
  ///
  /// Setting a negative [rawIndex], or one greater than or equal to
  /// `string.length`, is an error. So is setting it in the middle of a surrogate
  ///  pair.
  ///
  /// Setting the position to the end of the string means that there is no
  /// current rune.
  void set rawIndex(int rawIndex) {
    IndexError.check(rawIndex, string.length,
        indexable: string, name: "rawIndex");
    reset(rawIndex);
    moveNext();
  }

  /// Resets the iterator to the given index into the string.
  ///
  /// After this the [current] value is unset.
  /// You must call [moveNext] make the rune at the position current,
  /// or [movePrevious] for the last rune before the position.
  ///
  /// The [rawIndex] must be non-negative and no greater than `string.length`.
  /// It must also not be the index of the trailing surrogate of a surrogate
  /// pair.
  void reset([int rawIndex = 0]) {
    RangeError.checkValueInInterval(rawIndex, 0, string.length, "rawIndex");
    _checkSplitSurrogate(rawIndex);
    _position = _nextPosition = rawIndex;
    _currentCodePoint = -1;
  }

  /// The rune (integer Unicode code point) starting at the current position in
  /// the string.
  ///
  /// The value is -1 if there is no current code point.
  int get current => _currentCodePoint;

  /// The number of code units comprising the current rune.
  ///
  /// Returns zero if there is no current rune ([current] is -1).
  int get currentSize => _nextPosition - _position;

  /// A string containing the current rune.
  ///
  /// For runes outside the basic multilingual plane, this will be
  /// a String of length 2, containing two code units.
  ///
  /// Returns an empty string if there is no [current] value.
  String get currentAsString {
    if (_position == _nextPosition) return "";
    if (_position + 1 == _nextPosition) return string[_position];
    return string.substring(_position, _nextPosition);
  }

  /// Move to the next code point.
  ///
  /// Returns `true` and updates [current] if there is a next code point.
  /// Returns `false` otherwise, and then there is no current code point.
  bool moveNext() {
    _position = _nextPosition;
    if (_position == string.length) {
      _currentCodePoint = -1;
      return false;
    }
    int codeUnit = string.codeUnitAt(_position);
    int nextPosition = _position + 1;
    if (_isLeadSurrogate(codeUnit) && nextPosition < string.length) {
      int nextCodeUnit = string.codeUnitAt(nextPosition);
      if (_isTrailSurrogate(nextCodeUnit)) {
        _nextPosition = nextPosition + 1;
        _currentCodePoint = _combineSurrogatePair(codeUnit, nextCodeUnit);
        return true;
      }
    }
    _nextPosition = nextPosition;
    _currentCodePoint = codeUnit;
    return true;
  }

  /// Move back to the previous code point.
  ///
  /// Returns `true` and updates [current] if there is a previous code point.
  /// Returns `false` otherwise, and then there is no current code point.
  bool movePrevious() {
    _nextPosition = _position;
    if (_position == 0) {
      _currentCodePoint = -1;
      return false;
    }
    int position = _position - 1;
    int codeUnit = string.codeUnitAt(position);
    if (_isTrailSurrogate(codeUnit) && position > 0) {
      int prevCodeUnit = string.codeUnitAt(position - 1);
      if (_isLeadSurrogate(prevCodeUnit)) {
        _position = position - 1;
        _currentCodePoint = _combineSurrogatePair(prevCodeUnit, codeUnit);
        return true;
      }
    }
    _position = position;
    _currentCodePoint = codeUnit;
    return true;
  }
}
