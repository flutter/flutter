// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'feature_matcher.dart';
import 'interfaces.dart';

/// Returns a matcher which matches if the match argument is a string and
/// is equal to [value] when compared case-insensitively.
Matcher equalsIgnoringCase(String value) => _IsEqualIgnoringCase(value);

class _IsEqualIgnoringCase extends FeatureMatcher<String> {
  final String _value;
  final String _matchValue;

  _IsEqualIgnoringCase(String value)
      : _value = value,
        _matchValue = value.toLowerCase();

  @override
  bool typedMatches(String item, Map matchState) =>
      _matchValue == item.toLowerCase();

  @override
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
///     expect("hello   world", equalsIgnoringWhitespace("hello world"));
///     expect("  hello world", equalsIgnoringWhitespace("hello world"));
///     expect("hello world  ", equalsIgnoringWhitespace("hello world"));
///
/// The following will not match:
///
///     expect("helloworld", equalsIgnoringWhitespace("hello world"));
///     expect("he llo world", equalsIgnoringWhitespace("hello world"));
Matcher equalsIgnoringWhitespace(String value) =>
    _IsEqualIgnoringWhitespace(value);

class _IsEqualIgnoringWhitespace extends FeatureMatcher<String> {
  final String _matchValue;

  _IsEqualIgnoringWhitespace(String value)
      : _matchValue = collapseWhitespace(value);

  @override
  bool typedMatches(String item, Map matchState) =>
      _matchValue == collapseWhitespace(item);

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_matchValue).add(' ignoring whitespace');

  @override
  Description describeTypedMismatch(dynamic item,
      Description mismatchDescription, Map matchState, bool verbose) {
    return mismatchDescription
        .add('is ')
        .addDescriptionOf(collapseWhitespace(item))
        .add(' with whitespace compressed');
  }
}

/// Returns a matcher that matches if the match argument is a string and
/// starts with [prefixString].
Matcher startsWith(String prefixString) => _StringStartsWith(prefixString);

class _StringStartsWith extends FeatureMatcher<String> {
  final String _prefix;

  const _StringStartsWith(this._prefix);

  @override
  bool typedMatches(dynamic item, Map matchState) => item.startsWith(_prefix);

  @override
  Description describe(Description description) =>
      description.add('a string starting with ').addDescriptionOf(_prefix);
}

/// Returns a matcher that matches if the match argument is a string and
/// ends with [suffixString].
Matcher endsWith(String suffixString) => _StringEndsWith(suffixString);

class _StringEndsWith extends FeatureMatcher<String> {
  final String _suffix;

  const _StringEndsWith(this._suffix);

  @override
  bool typedMatches(dynamic item, Map matchState) => item.endsWith(_suffix);

  @override
  Description describe(Description description) =>
      description.add('a string ending with ').addDescriptionOf(_suffix);
}

/// Returns a matcher that matches if the match argument is a string and
/// contains a given list of [substrings] in relative order.
///
/// For example, `stringContainsInOrder(["a", "e", "i", "o", "u"])` will match
/// "abcdefghijklmnopqrstuvwxyz".

Matcher stringContainsInOrder(List<String> substrings) =>
    _StringContainsInOrder(substrings);

class _StringContainsInOrder extends FeatureMatcher<String> {
  final List<String> _substrings;

  const _StringContainsInOrder(this._substrings);

  @override
  bool typedMatches(dynamic item, Map matchState) {
    var fromIndex = 0;
    for (var s in _substrings) {
      var index = item.indexOf(s, fromIndex);
      if (index < 0) return false;
      fromIndex = index + s.length;
    }
    return true;
  }

  @override
  Description describe(Description description) => description.addAll(
      'a string containing ', ', ', ' in order', _substrings);
}

/// Returns a matcher that matches if the match argument is a string and
/// matches the regular expression given by [re].
///
/// [re] can be a [RegExp] instance or a [String]; in the latter case it will be
/// used to create a RegExp instance.
Matcher matches(Pattern re) => _MatchesRegExp(re);

class _MatchesRegExp extends FeatureMatcher<String> {
  final RegExp _regexp;

  _MatchesRegExp(Pattern re)
      : _regexp = (re is String)
            ? RegExp(re)
            : (re is RegExp)
                ? re
                : throw ArgumentError('matches requires a regexp or string');

  @override
  bool typedMatches(dynamic item, Map matchState) => _regexp.hasMatch(item);

  @override
  Description describe(Description description) =>
      description.add("match '${_regexp.pattern}'");
}

/// Utility function to collapse whitespace runs to single spaces
/// and strip leading/trailing whitespace.
String collapseWhitespace(String string) {
  var result = StringBuffer();
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
