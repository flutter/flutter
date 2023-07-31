// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'core_matchers.dart';
import 'equals_matcher.dart';
import 'interfaces.dart';

/// A [Map] between whitespace characters and their escape sequences.
const _escapeMap = {
  '\n': r'\n',
  '\r': r'\r',
  '\f': r'\f',
  '\b': r'\b',
  '\t': r'\t',
  '\v': r'\v',
  '\x7F': r'\x7F', // delete
};

/// A [RegExp] that matches whitespace characters that should be escaped.
final _escapeRegExp = RegExp(
    '[\\x00-\\x07\\x0E-\\x1F${_escapeMap.keys.map(_getHexLiteral).join()}]');

/// Useful utility for nesting match states.
void addStateInfo(Map matchState, Map values) {
  var innerState = Map.of(matchState);
  matchState.clear();
  matchState['state'] = innerState;
  matchState.addAll(values);
}

/// Takes an argument and returns an equivalent [Matcher].
///
/// If the argument is already a matcher this does nothing,
/// else if the argument is a function, it generates a predicate
/// function matcher, else it generates an equals matcher.
Matcher wrapMatcher(Object? valueOrMatcher) {
  if (valueOrMatcher is Matcher) {
    return valueOrMatcher;
  } else if (valueOrMatcher is bool Function(Object?)) {
    // already a predicate that can handle anything
    return predicate(valueOrMatcher);
  } else if (valueOrMatcher is bool Function(Never)) {
    // unary predicate, but expects a specific type
    // so wrap it.
    // ignore: unnecessary_lambdas
    return predicate((a) => (valueOrMatcher as dynamic)(a));
  } else {
    return equals(valueOrMatcher);
  }
}

/// Returns [str] with all whitespace characters represented as their escape
/// sequences.
///
/// Backslash characters are escaped as `\\`
String escape(String str) {
  str = str.replaceAll('\\', r'\\');
  return str.replaceAllMapped(_escapeRegExp, (match) {
    var mapped = _escapeMap[match[0]];
    if (mapped != null) return mapped;
    return _getHexLiteral(match[0]!);
  });
}

/// Given single-character string, return the hex-escaped equivalent.
String _getHexLiteral(String input) {
  var rune = input.runes.single;
  return r'\x' + rune.toRadixString(16).toUpperCase().padLeft(2, '0');
}
