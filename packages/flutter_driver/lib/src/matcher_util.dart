// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:matcher/matcher.dart';

/// Matches [value] against the [matcher].
MatchResult match(dynamic value, Matcher matcher) {
  if (matcher.matches(value, {})) {
    return new MatchResult._matched();
  } else {
    Description description =
        matcher.describeMismatch(value, new _TextDescription(), {}, false);
    return new MatchResult._mismatched(description.toString());
  }
}

/// Result of matching a value against a matcher.
class MatchResult {
  MatchResult._matched()
    : hasMatched = true,
      mismatchDescription = null;

  MatchResult._mismatched(String mismatchDescription)
    : hasMatched = false,
      mismatchDescription = mismatchDescription;

  /// Whether the match succeeded.
  final bool hasMatched;

  /// If the match did not succeed, this field contains the explanation.
  final String mismatchDescription;
}

/// Writes description into a string.
class _TextDescription implements Description {
  final StringBuffer _text = new StringBuffer();

  int get length => _text.length;

  Description add(String text) {
    _text.write(text);
    return this;
  }

  Description replace(String text) {
    _text.clear();
    _text.write(text);
    return this;
  }

  Description addDescriptionOf(dynamic value) {
    if (value is Matcher) {
      value.describe(this);
      return this;
    } else {
      return add('$value');
    }
  }

  Description addAll(String start, String separator, String end, Iterable<dynamic> list) {
    add(start);
    if (list.isNotEmpty) {
      addDescriptionOf(list.first);
      for (dynamic item in list.skip(1)) {
        add(separator);
        addDescriptionOf(item);
      }
    }
    add(end);
    return this;
  }

  String toString() => '$_text';
}
