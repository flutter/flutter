// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.string_matchers;

import 'interfaces.dart';

/// Returns a matcher which matches if the match argument is a string and
/// is equal to [value] when compared case-insensitively.
Matcher equalsIgnoringCase(String value) => new _IsEqualIgnoringCase(value);

class _IsEqualIgnoringCase extends _StringMatcher {
  final String _value;
  final String _matchValue;

  _IsEqualIgnoringCase(String value)
      : _value = value,
        _matchValue = value.toLowerCase();

  bool matches(item, Map matchState) =>
      item is String && _matchValue == item.toLowerCase();

  Description describe(Description description) =>
      description.addDescriptionOf(_value).add(' ignoring case');
}

/// Returns a matcher which matches if the match argument is a string and
/// is equal to [value], ignoring whitespace.
///
/// In this matcher, "ignoring whitespace" means comparing with all runs of
/// whitespace collapsed to single space characters and leading and trailing
/// whitespace removed.
///
/// For example, the following will all match successfully:
///
///     expect("hello   world", equalsIgnoringCase("hello world"));
///     expect("  hello world", equalsIgnoringCase("hello world"));
///     expect("hello world  ", equalsIgnoringCase("hello world"));
///
/// The following will not match:
///
///     expect("helloworld", equalsIgnoringCase("hello world"));
///     expect("he llo world", equalsIgnoringCase("hello world"));
Matcher equalsIgnoringWhitespace(String value) =>
    new _IsEqualIgnoringWhitespace(value);

class _IsEqualIgnoringWhitespace extends _StringMatcher {
  final String _value;
  final String _matchValue;

  _IsEqualIgnoringWhitespace(String value)
      : _value = value,
        _matchValue = collapseWhitespace(value);

  bool matches(item, Map matchState) =>
      item is String && _matchValue == collapseWhitespace(item);

  Description describe(Description description) =>
      description.addDescriptionOf(_matchValue).add(' ignoring whitespace');

  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is String) {
      return mismatchDescription
          .add('is ')
          .addDescriptionOf(collapseWhitespace(item))
          .add(' with whitespace compressed');
    } else {
      return super.describeMismatch(
          item, mismatchDescription, matchState, verbose);
    }
  }
}

/// Returns a matcher that matches if the match argument is a string and
/// starts with [prefixString].
Matcher startsWith(String prefixString) => new _StringStartsWith(prefixString);

class _StringStartsWith extends _StringMatcher {
  final String _prefix;

  const _StringStartsWith(this._prefix);

  bool matches(item, Map matchState) =>
      item is String && item.startsWith(_prefix);

  Description describe(Description description) =>
      description.add('a string starting with ').addDescriptionOf(_prefix);
}

/// Returns a matcher that matches if the match argument is a string and
/// ends with [suffixString].
Matcher endsWith(String suffixString) => new _StringEndsWith(suffixString);

class _StringEndsWith extends _StringMatcher {
  final String _suffix;

  const _StringEndsWith(this._suffix);

  bool matches(item, Map matchState) =>
      item is String && item.endsWith(_suffix);

  Description describe(Description description) =>
      description.add('a string ending with ').addDescriptionOf(_suffix);
}

/// Returns a matcher that matches if the match argument is a string and
/// contains a given list of [substrings] in relative order.
///
/// For example, `stringContainsInOrder(["a", "e", "i", "o", "u"])` will match
/// "abcdefghijklmnopqrstuvwxyz".

Matcher stringContainsInOrder(List<String> substrings) =>
    new _StringContainsInOrder(substrings);

class _StringContainsInOrder extends _StringMatcher {
  final List<String> _substrings;

  const _StringContainsInOrder(this._substrings);

  bool matches(item, Map matchState) {
    if (!(item is String)) {
      return false;
    }
    var from_index = 0;
    for (var s in _substrings) {
      from_index = item.indexOf(s, from_index);
      if (from_index < 0) return false;
    }
    return true;
  }

  Description describe(Description description) => description.addAll(
      'a string containing ', ', ', ' in order', _substrings);
}

/// Returns a matcher that matches if the match argument is a string and
/// matches the regular expression given by [re].
///
/// [re] can be a [RegExp] instance or a [String]; in the latter case it will be
/// used to create a RegExp instance.
Matcher matches(re) => new _MatchesRegExp(re);

class _MatchesRegExp extends _StringMatcher {
  RegExp _regexp;

  _MatchesRegExp(re) {
    if (re is String) {
      _regexp = new RegExp(re);
    } else if (re is RegExp) {
      _regexp = re;
    } else {
      throw new ArgumentError('matches requires a regexp or string');
    }
  }

  bool matches(item, Map matchState) =>
      item is String ? _regexp.hasMatch(item) : false;

  Description describe(Description description) =>
      description.add("match '${_regexp.pattern}'");
}

// String matchers match against a string. We add this intermediate
// class to give better mismatch error messages than the base Matcher class.
abstract class _StringMatcher extends Matcher {
  const _StringMatcher();
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (!(item is String)) {
      return mismatchDescription.addDescriptionOf(item).add(' not a string');
    } else {
      return super.describeMismatch(
          item, mismatchDescription, matchState, verbose);
    }
  }
}

/// Utility function to collapse whitespace runs to single spaces
/// and strip leading/trailing whitespace.
String collapseWhitespace(String string) {
  var result = new StringBuffer();
  var skipSpace = true;
  for (var i = 0; i < string.length; i++) {
    var character = string[i];
    if (_isWhitespace(character)) {
      if (!skipSpace) {
        result.write(' ');
        skipSpace = true;
      }
    } else {
      result.write(character);
      skipSpace = false;
    }
  }
  return result.toString().trim();
}

bool _isWhitespace(String ch) =>
    ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t';
