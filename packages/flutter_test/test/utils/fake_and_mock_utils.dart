// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

TestWidgetsFlutterBinding retrieveTestBinding(final WidgetTester tester) {
  final WidgetsBinding binding = tester.binding;
  assert(binding is TestWidgetsFlutterBinding);
  final TestWidgetsFlutterBinding testBinding = binding as TestWidgetsFlutterBinding;
  return testBinding;
}

void verifyPropertyFaked<TProperty>({
  required final WidgetTester tester,
  required final TProperty realValue,
  required final TProperty fakeValue,
  required final TProperty Function() propertyRetriever,
  required final Function(TestWidgetsFlutterBinding, TProperty fakeValue) propertyFaker,
  final Matcher Function(TProperty) matcher = equals,
}) {
  TProperty propertyBeforeFaking;
  TProperty propertyAfterFaking;

  propertyBeforeFaking = propertyRetriever();

  propertyFaker(retrieveTestBinding(tester), fakeValue);

  propertyAfterFaking = propertyRetriever();

  expect(
    realValue == fakeValue,
    isFalse,
    reason: 'Since the real value and fake value are equal, we cannot validate '
      'that a property has been faked. Choose a different fake value to test.',
  );
  expect(propertyBeforeFaking, matcher(realValue));
  expect(propertyAfterFaking, matcher(fakeValue));
}

void verifyPropertyReset<TProperty>({
  required final WidgetTester tester,
  required final TProperty fakeValue,
  required final TProperty Function() propertyRetriever,
  required final Function() propertyResetter,
  required final Function(TProperty fakeValue) propertyFaker,
  final Matcher Function(TProperty) matcher = equals,
}) {
  TProperty propertyBeforeFaking;
  TProperty propertyAfterFaking;
  TProperty propertyAfterReset;

  propertyBeforeFaking = propertyRetriever();

  propertyFaker(fakeValue);

  propertyAfterFaking = propertyRetriever();

  propertyResetter();

  propertyAfterReset = propertyRetriever();

  expect(propertyAfterFaking, matcher(fakeValue));
  expect(propertyAfterReset, matcher(propertyBeforeFaking));
}

Matcher matchesViewPadding(final ViewPadding expected) => _FakeViewPaddingMatcher(expected);

class _FakeViewPaddingMatcher extends Matcher {
  _FakeViewPaddingMatcher(this.expected);

  final ViewPadding expected;

  @override
  Description describe(final Description description) {
    description.add('two ViewPadding instances match');
    return description;
  }

  @override
  Description describeMismatch(final dynamic item, final Description mismatchDescription, final Map<dynamic, dynamic> matchState, final bool verbose) {
    assert(item is ViewPadding, 'Can only match against implementations of ViewPadding.');
    final ViewPadding actual = item as ViewPadding;

    if (actual.left != expected.left) {
      mismatchDescription.add('actual.left (${actual.left}) did not match expected.left (${expected.left})');
    }
    if (actual.top != expected.top) {
      mismatchDescription.add('actual.top (${actual.top}) did not match expected.top (${expected.top})');
    }
    if (actual.right != expected.right) {
      mismatchDescription.add('actual.right (${actual.right}) did not match expected.right (${expected.right})');
    }
    if (actual.bottom != expected.bottom) {
      mismatchDescription.add('actual.bottom (${actual.bottom}) did not match expected.bottom (${expected.bottom})');
    }

    return mismatchDescription;
  }

  @override
  bool matches(final dynamic item, final Map<dynamic, dynamic> matchState) {
    assert(item is ViewPadding, 'Can only match against implementations of ViewPadding.');
    final ViewPadding actual = item as ViewPadding;

    return actual.left == expected.left &&
      actual.top == expected.top &&
      actual.right == expected.right &&
      actual.bottom == expected.bottom;
  }
}
