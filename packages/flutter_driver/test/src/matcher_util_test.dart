// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:flutter_driver/src/matcher_util.dart';

void main() {
  group('match', () {
    test('matches', () {
      _TestMatcher matcher = new _TestMatcher(1);
      MatchResult ok = match(1, matcher);
      expect(ok.hasMatched, isTrue);
      expect(ok.mismatchDescription, isNull);
      expect(matcher.matchState1 is Map<dynamic, dynamic>, isTrue);
      expect(matcher.matchState2, isNull);
    });

    test('mismatches', () {
      _TestMatcher matcher = new _TestMatcher(2);
      MatchResult fail = match(1, matcher);
      expect(fail.hasMatched, isFalse);
      expect(fail.mismatchDescription, 'mismatch!');
      expect(matcher.matchState1, matcher.matchState2);
    });
  });
}

class _TestMatcher extends Matcher {
  int expected;
  Map<dynamic, dynamic> matchState1;
  Map<dynamic, dynamic> matchState2;

  _TestMatcher(this.expected);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    matchState1 = matchState;
    return item == expected;
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription, Map<dynamic, dynamic> matchState, bool verbose) {
    matchState2 = matchState;
    mismatchDescription.add('mismatch!');
    return mismatchDescription;
  }

  @override
  Description describe(Description description) {
    throw 'not implemented';
  }
}
