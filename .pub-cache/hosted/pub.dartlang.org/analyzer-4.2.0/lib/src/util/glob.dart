// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/either.dart';

/// A pattern that matches against filesystem path-like strings with wildcards.
///
/// The pattern matches strings as follows:
///   * The pattern must use `/` as the path separator.
///   * The whole string must match, not a substring.
///   * Any non wildcard is matched as a literal.
///   * '*' matches one or more characters except '/'.
///   * '?' matches exactly one character except '/'.
///   * '**' matches one or more characters including '/'.
class Glob {
  /// The special characters are: \ ^ $ . | + [ ] ( ) { }
  /// as defined here: http://ecma-international.org/ecma-262/5.1/#sec-15.10
  static final RegExp _specialChars = RegExp(r'([\\\^\$\.\|\+\[\]\(\)\{\}])');

  /// The path separator used to separate components in file paths.
  final String _separator;

  /// The pattern string.
  final String _pattern;

  /// The parsed [_pattern].
  final Either2<String, RegExp> _matcher;

  Glob(this._separator, this._pattern) : _matcher = _parse(_pattern);

  @override
  int get hashCode => _pattern.hashCode;

  @override
  bool operator ==(Object other) => other is Glob && _pattern == other._pattern;

  /// Return `true` if the given [path] matches this glob.
  /// The given [path] must use the same [_separator] as the glob.
  bool matches(String path) {
    String posixPath = _toPosixPath(path);
    return _matcher.map(
      (suffix) => posixPath.toLowerCase().endsWith(suffix),
      (regexp) => regexp.matchAsPrefix(posixPath) != null,
    );
  }

  @override
  String toString() => _pattern;

  /// Return the Posix version of the given [path].
  String _toPosixPath(String path) {
    if (_separator == '/') {
      return path;
    }
    return path.replaceAll(_separator, '/');
  }

  /// Return `true` if the [pattern] start with the given [prefix] and does
  /// not have `*` or `?` characters after the [prefix].
  static bool _hasJustPrefix(String pattern, String prefix) {
    if (pattern.startsWith(prefix)) {
      int prefixLength = prefix.length;
      return !pattern.contains('*', prefixLength) &&
          !pattern.contains('?', prefixLength);
    }
    return false;
  }

  static Either2<String, RegExp> _parse(String pattern) {
    if (_hasJustPrefix(pattern, '**/*')) {
      var suffix = pattern.substring(4).toLowerCase();
      return Either2.t1(suffix);
    } else if (_hasJustPrefix(pattern, '**')) {
      var suffix = pattern.substring(2).toLowerCase();
      return Either2.t1(suffix);
    } else {
      var regexp = _regexpFromGlobPattern(pattern);
      return Either2.t2(regexp);
    }
  }

  static RegExp _regexpFromGlobPattern(String pattern) {
    StringBuffer sb = StringBuffer();
    sb.write('^');
    List<String> chars = pattern.split('');
    for (int i = 0; i < chars.length; i++) {
      String c = chars[i];
      if (_specialChars.hasMatch(c)) {
        sb.write(r'\');
        sb.write(c);
      } else if (c == '*') {
        if (i + 1 < chars.length && chars[i + 1] == '*') {
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
    return RegExp(sb.toString(), caseSensitive: false);
  }
}
