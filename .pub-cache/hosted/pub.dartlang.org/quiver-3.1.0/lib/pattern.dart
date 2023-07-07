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

/// This library contains utilities for working with [RegExp]s and other
/// [Pattern]s.
library quiver.pattern;

// From the PatternCharacter rule here:
// http://ecma-international.org/ecma-262/5.1/#sec-15.10
final _specialChars = RegExp(r'([\\\^\$\.\|\+\[\]\(\)\{\}])');

/// Escapes special regex characters in [str] so that it can be used as a
/// literal match inside of a [RegExp].
///
/// The special characters are: \ ^ $ . | + [ ] ( ) { }
/// as defined here: http://ecma-international.org/ecma-262/5.1/#sec-15.10
String escapeRegex(String str) => str.splitMapJoin(_specialChars,
    onMatch: (Match m) => '\\${m.group(0)}', onNonMatch: (s) => s);

/// Returns a [Pattern] that matches against every pattern in [include] and
/// returns all the matches. If the input string matches against any pattern in
/// [exclude] no matches are returned.
Pattern matchAny(Iterable<Pattern> include, {Iterable<Pattern>? exclude}) =>
    _MultiPattern(include, exclude: exclude);

class _MultiPattern extends Pattern {
  _MultiPattern(this.include, {this.exclude});

  final Iterable<Pattern> include;
  final Iterable<Pattern>? exclude;

  @override
  Iterable<Match> allMatches(String str, [int start = 0]) {
    final _allMatches = <Match>[];
    for (final pattern in include) {
      var matches = pattern.allMatches(str, start);
      if (_hasMatch(matches)) {
        if (exclude != null) {
          for (final excludePattern in exclude!) {
            if (_hasMatch(excludePattern.allMatches(str, start))) {
              return [];
            }
          }
        }
        _allMatches.addAll(matches);
      }
    }
    return _allMatches;
  }

  @override
  Match? matchAsPrefix(String str, [int start = 0]) {
    for (final match in allMatches(str)) {
      if (match.start == start) {
        return match;
      }
    }
    return null;
  }
}

/// Returns true if [pattern] has a single match in [str] that matches the
/// whole string, not a substring.
bool matchesFull(Pattern pattern, String str) {
  var match = pattern.matchAsPrefix(str);
  return match != null && match.end == str.length;
}

bool _hasMatch(Iterable<Match> matches) => matches.iterator.moveNext();

// TODO(justin): add more detailed documentation and explain how matching
// differs or is similar to globs in Python and various shells.
/// A [Pattern] that matches against filesystem path-like strings with
/// wildcards.
///
/// The pattern matches strings as follows:
///   * The whole string must match, not a substring
///   * Any non wildcard is matched as a literal
///   * '*' matches one or more characters except '/'
///   * '?' matches exactly one character except '/'
///   * '**' matches one or more characters including '/'
class Glob implements Pattern {
  Glob(this.pattern) : regex = _regexpFromGlobPattern(pattern);

  final RegExp regex;
  final String pattern;

  @override
  Iterable<Match> allMatches(String str, [int start = 0]) =>
      regex.allMatches(str, start);

  @override
  Match? matchAsPrefix(String string, [int start = 0]) =>
      regex.matchAsPrefix(string, start);

  bool hasMatch(String str) => regex.hasMatch(str);

  @override
  String toString() => pattern;

  @override
  int get hashCode => pattern.hashCode;

  @override
  bool operator ==(Object other) => other is Glob && pattern == other.pattern;
}

RegExp _regexpFromGlobPattern(String pattern) {
  var sb = StringBuffer();
  sb.write('^');
  var chars = pattern.split('');
  for (var i = 0; i < chars.length; i++) {
    var c = chars[i];
    if (_specialChars.hasMatch(c)) {
      sb.write('\\$c');
    } else if (c == '*') {
      if ((i + 1 < chars.length) && (chars[i + 1] == '*')) {
        sb.write('.*');
        i++;
      } else {
        sb.write('[^/]*');
      }
    } else if (c == '?') {
      sb.write('[^/]');
    } else {
      sb.write(c);
    }
  }
  sb.write(r'$');
  return RegExp(sb.toString());
}
