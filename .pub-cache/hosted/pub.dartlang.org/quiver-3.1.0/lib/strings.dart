// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library quiver.strings;

/// Returns [true] if [s] is either null, empty or is solely made of whitespace
/// characters (as defined by [String.trim]).
bool isBlank(String? s) => s == null || s.trim().isEmpty;

/// Returns [true] if [s] is neither null, empty nor is solely made of whitespace
/// characters.
///
/// See also:
///
///  * [isBlank]
bool isNotBlank(String? s) => s != null && s.trim().isNotEmpty;

/// Returns [true] if [s] is either null or empty.
bool isEmpty(String? s) => s == null || s.isEmpty;

/// Returns [true] if [s] is a not empty string.
bool isNotEmpty(String? s) => s != null && s.isNotEmpty;

/// Returns a string with characters from the given [s] in reverse order.
///
/// NOTE: without full support for unicode composed character sequences,
/// sequences including zero-width joiners, etc. this function is unsafe to
/// use. No replacement is provided.
String _reverse(String s) {
  if (s == '') return s;
  StringBuffer sb = StringBuffer();
  var runes = s.runes.iterator..reset(s.length);
  while (runes.movePrevious()) {
    sb.writeCharCode(runes.current);
  }
  return sb.toString();
}

/// Loops over [s] and returns traversed characters. Takes arbitrary [from] and
/// [to] indices. Works as a substitute for [String.substring], except it never
/// throws [RangeError]. Supports negative indices. Think of an index as a
/// coordinate in an infinite in both directions vector filled with repeating
/// string [s], whose 0-th coordinate coincides with the 0-th character in [s].
/// Then [loop] returns the sub-vector defined by the interval ([from], [to]).
/// [from] is inclusive. [to] is exclusive.
///
/// This method throws exceptions on [null] and empty strings.
///
/// If [to] is omitted or is [null] the traversing ends at the end of the loop.
///
/// If [to] < [from], traverses [s] in the opposite direction.
///
/// For example:
///
/// loop('Hello, World!', 7) == 'World!'
/// loop('ab', 0, 6) == 'ababab'
/// loop('test.txt', -3) == 'txt'
/// loop('ldwor', -3, 2) == 'world'
String loop(String s, int from, [int? to]) {
  if (s.isEmpty) {
    throw ArgumentError('Input string cannot be empty');
  }
  if (to != null && to < from) {
    // TODO(cbracken): throw ArgumentError in this case.
    return loop(_reverse(s), -from, -to);
  }
  int len = s.length;
  int leftFrag = from >= 0 ? from ~/ len : ((from - len) ~/ len);
  to ??= (leftFrag + 1) * len;
  int rightFrag = to - 1 >= 0 ? to ~/ len : ((to - len) ~/ len);
  int fragOffset = rightFrag - leftFrag - 1;
  if (fragOffset == -1) {
    return s.substring(from - leftFrag * len, to - rightFrag * len);
  }
  StringBuffer sink = StringBuffer(s.substring(from - leftFrag * len));
  _repeat(sink, s, fragOffset);
  sink.write(s.substring(0, to - rightFrag * len));
  return sink.toString();
}

void _repeat(StringBuffer sink, String s, int times) {
  for (int i = 0; i < times; i++) {
    sink.write(s);
  }
}

/// Returns `true` if [rune] represents a digit.
///
/// The definition of digit matches the Unicode `0x3?` range of Western
/// European digits.
bool isDigit(int rune) => rune ^ 0x30 <= 9;

/// Returns `true` if [rune] represents a whitespace character.
///
/// The definition of whitespace matches that used in [String.trim] which is
/// based on Unicode 6.2. This maybe be a different set of characters than the
/// environment's [RegExp] definition for whitespace, which is given by the
/// ECMAScript standard: http://ecma-international.org/ecma-262/5.1/#sec-15.10
bool isWhitespace(int rune) =>
    (rune >= 0x0009 && rune <= 0x000D) ||
    rune == 0x0020 ||
    rune == 0x0085 ||
    rune == 0x00A0 ||
    rune == 0x1680 ||
    rune == 0x180E ||
    (rune >= 0x2000 && rune <= 0x200A) ||
    rune == 0x2028 ||
    rune == 0x2029 ||
    rune == 0x202F ||
    rune == 0x205F ||
    rune == 0x3000 ||
    rune == 0xFEFF;

/// Returns a [String] of length [width] padded with the same number of
/// characters on the left and right from [fill].  On the right, characters are
/// selected from [fill] starting at the end so that the last character in
/// [fill] is the last character in the result. [fill] is repeated if
/// necessary to pad.
///
/// Returns [input] if `input.length` is equal to or greater than width.
/// [input] can be `null` and is treated as an empty string.
///
/// If there are an odd number of characters to pad, then the right will be
/// padded with one more than the left.
String center(String? input, int width, String fill) {
  if (fill.isEmpty) {
    throw ArgumentError('fill cannot be empty');
  }
  input ??= '';
  if (input.length >= width) return input;

  var padding = width - input.length;
  if (padding ~/ 2 > 0) {
    input = loop(fill, 0, padding ~/ 2) + input;
  }
  return input + loop(fill, input.length - width, 0);
}

/// Returns `true` if [a] and [b] are equal after being converted to lower
/// case, or are both null.
bool equalsIgnoreCase(String? a, String? b) =>
    (a == null && b == null) ||
    (a != null && b != null && a.toLowerCase() == b.toLowerCase());

/// Compares [a] and [b] after converting to lower case.
///
/// Both [a] and [b] must not be null.
int compareIgnoreCase(String a, String b) =>
    a.toLowerCase().compareTo(b.toLowerCase());
