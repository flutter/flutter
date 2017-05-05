// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:test/test.dart';

import 'finders.dart';

/// Asserts that the [Finder] matches no widgets in the widget tree.
///
/// ## Sample code
///
/// ```dart
/// expect(find.text('Save'), findsNothing);
/// ```
///
/// See also:
///
///  * [findsWidgets], when you want the finder to find one or more widgets.
///  * [findsOneWidget], when you want the finder to find exactly one widget.
///  * [findsNWidgets], when you want the finder to find a specific number of widgets.
const Matcher findsNothing = const _FindsWidgetMatcher(null, 0);

/// Asserts that the [Finder] locates at least one widget in the widget tree.
///
/// ## Sample code
///
/// ```dart
/// expect(find.text('Save'), findsWidgets);
/// ```
///
/// See also:
///
///  * [findsNothing], when you want the finder to not find anything.
///  * [findsOneWidget], when you want the finder to find exactly one widget.
///  * [findsNWidgets], when you want the finder to find a specific number of widgets.
const Matcher findsWidgets = const _FindsWidgetMatcher(1, null);

/// Asserts that the [Finder] locates at exactly one widget in the widget tree.
///
/// ## Sample code
///
/// ```dart
/// expect(find.text('Save'), findsOneWidget);
/// ```
///
/// See also:
///
///  * [findsNothing], when you want the finder to not find anything.
///  * [findsWidgets], when you want the finder to find one or more widgets.
///  * [findsNWidgets], when you want the finder to find a specific number of widgets.
const Matcher findsOneWidget = const _FindsWidgetMatcher(1, 1);

/// Asserts that the [Finder] locates the specified number of widgets in the widget tree.
///
/// ## Sample code
///
/// ```dart
/// expect(find.text('Save'), findsNWidgets(2));
/// ```
///
/// See also:
///
///  * [findsNothing], when you want the finder to not find anything.
///  * [findsWidgets], when you want the finder to find one or more widgets.
///  * [findsOneWidget], when you want the finder to find exactly one widget.
Matcher findsNWidgets(int n) => new _FindsWidgetMatcher(n, n);

/// Asserts that the [Finder] locates the a single widget that has at
/// least one [Offstage] widget ancestor.
///
/// It's important to use a full finder, since by default finders exclude
/// offstage widgets.
///
/// ## Sample code
///
/// ```dart
/// expect(find.text('Save', skipOffstage: false), isOffstage);
/// ```
///
/// See also:
///
///  * [isOnstage], the opposite.
const Matcher isOffstage = const _IsOffstage();

/// Asserts that the [Finder] locates the a single widget that has no
/// [Offstage] widget ancestors.
///
/// See also:
///
///  * [isOffstage], the opposite.
const Matcher isOnstage = const _IsOnstage();

/// Asserts that the [Finder] locates the a single widget that has at
/// least one [Card] widget ancestor.
///
/// See also:
///
///  * [isNotInCard], the opposite.
const Matcher isInCard = const _IsInCard();

/// Asserts that the [Finder] locates the a single widget that has no
/// [Card] widget ancestors.
///
/// This is equivalent to `isNot(isInCard)`.
///
/// See also:
///
///  * [isInCard], the opposite.
const Matcher isNotInCard = const _IsNotInCard();

/// Asserts that an object's toString() is a plausible one-line description.
///
/// Specifically, this matcher checks that the string does not contains newline
/// characters, and does not have leading or trailing whitespace, is not
/// empty, and does not contain the default `Instance of ...` string.
const Matcher hasOneLineDescription = const _HasOneLineDescription();

/// A matcher for functions that throw [FlutterError].
///
/// This is equivalent to `throwsA(const isInstanceOf<FlutterError>())`.
///
/// See also:
///
///  * [throwsAssertionError], to test if a function throws any [AssertionError].
///  * [isFlutterError], to test if any object is a [FlutterError].
///  * [isAssertionError], to test if any object is any kind of [AssertionError].
Matcher throwsFlutterError = throwsA(isFlutterError);

/// A matcher for functions that throw [AssertionError].
///
/// This is equivalent to `throwsA(const isInstanceOf<AssertionError>())`.
///
/// See also:
///
///  * [throwsFlutterError], to test if a function throws a [FlutterError].
///  * [isFlutterError], to test if any object is a [FlutterError].
///  * [isAssertionError], to test if any object is any kind of [AssertionError].
Matcher throwsAssertionError = throwsA(isAssertionError);

/// A matcher for [FlutterError].
///
/// This is equivalent to `const isInstanceOf<FlutterError>()`.
///
/// See also:
///
///  * [throwsFlutterError], to test if a function throws a [FlutterError].
///  * [throwsAssertionError], to test if a function throws any [AssertionError].
///  * [isAssertionError], to test if any object is any kind of [AssertionError].
const Matcher isFlutterError = const isInstanceOf<FlutterError>();

/// A matcher for [AssertionError].
///
/// This is equivalent to `const isInstanceOf<AssertionError>()`.
///
/// See also:
///
///  * [throwsFlutterError], to test if a function throws a [FlutterError].
///  * [throwsAssertionError], to test if a function throws any [AssertionError].
///  * [isFlutterError], to test if any object is a [FlutterError].
const Matcher isAssertionError = const isInstanceOf<AssertionError>();

/// Asserts that two [double]s are equal, within some tolerated error.
///
/// Two values are considered equal if the difference between them is within
/// 1e-10 of the larger one. This is an arbitrary value which can be adjusted
/// using the `epsilon` argument. This matcher is intended to compare floating
/// point numbers that are the result of different sequences of operations, such
/// that they may have accumulated slightly different errors.
///
/// See also:
///
///  * [closeTo], which is identical except that the epsilon argument is
///    required and not named.
///  * [inInclusiveRange], which matches if the argument is in a specified
///    range.
Matcher moreOrLessEquals(double value, { double epsilon: 1e-10 }) {
  return new _MoreOrLessEquals(value, epsilon);
}

class _FindsWidgetMatcher extends Matcher {
  const _FindsWidgetMatcher(this.min, this.max);

  final int min;
  final int max;

  @override
  bool matches(covariant Finder finder, Map<dynamic, dynamic> matchState) {
    assert(min != null || max != null);
    assert(min == null || max == null || min <= max);
    matchState[Finder] = finder;
    int count = 0;
    final Iterator<Element> iterator = finder.evaluate().iterator;
    if (min != null) {
      while (count < min && iterator.moveNext())
        count += 1;
      if (count < min)
        return false;
    }
    if (max != null) {
      while (count <= max && iterator.moveNext())
        count += 1;
      if (count > max)
        return false;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    assert(min != null || max != null);
    if (min == max) {
      if (min == 1)
        return description.add('exactly one matching node in the widget tree');
      return description.add('exactly $min matching nodes in the widget tree');
    }
    if (min == null) {
      if (max == 0)
        return description.add('no matching nodes in the widget tree');
      if (max == 1)
        return description.add('at most one matching node in the widget tree');
      return description.add('at most $max matching nodes in the widget tree');
    }
    if (max == null) {
      if (min == 1)
        return description.add('at least one matching node in the widget tree');
      return description.add('at least $min matching nodes in the widget tree');
    }
    return description.add('between $min and $max matching nodes in the widget tree (inclusive)');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose
  ) {
    final Finder finder = matchState[Finder];
    final int count = finder.evaluate().length;
    if (count == 0) {
      assert(min != null && min > 0);
      if (min == 1 && max == 1)
        return mismatchDescription.add('means none were found but one was expected');
      return mismatchDescription.add('means none were found but some were expected');
    }
    if (max == 0) {
      if (count == 1)
        return mismatchDescription.add('means one was found but none were expected');
      return mismatchDescription.add('means some were found but none were expected');
    }
    if (min != null && count < min)
      return mismatchDescription.add('is not enough');
    assert(max != null && count > min);
    return mismatchDescription.add('is too many');
  }
}

bool _hasAncestorMatching(Finder finder, bool predicate(Widget widget)) {
  final Iterable<Element> nodes = finder.evaluate();
  if (nodes.length != 1)
    return false;
  bool result = false;
  nodes.single.visitAncestorElements((Element ancestor) {
    if (predicate(ancestor.widget)) {
      result = true;
      return false;
    }
    return true;
  });
  return result;
}

bool _hasAncestorOfType(Finder finder, Type targetType) {
  return _hasAncestorMatching(finder, (Widget widget) => widget.runtimeType == targetType);
}

class _IsOffstage extends Matcher {
  const _IsOffstage();

  @override
  bool matches(covariant Finder finder, Map<dynamic, dynamic> matchState) {
    return _hasAncestorMatching(finder, (Widget widget) {
      if (widget is Offstage)
        return widget.offstage;
      return false;
    });
  }

  @override
  Description describe(Description description) => description.add('offstage');
}

class _IsOnstage extends Matcher {
  const _IsOnstage();

  @override
  bool matches(covariant Finder finder, Map<dynamic, dynamic> matchState) {
    final Iterable<Element> nodes = finder.evaluate();
    if (nodes.length != 1)
      return false;
    bool result = true;
    nodes.single.visitAncestorElements((Element ancestor) {
      final Widget widget = ancestor.widget;
      if (widget is Offstage) {
        result = !widget.offstage;
        return false;
      }
      return true;
    });
    return result;
  }

  @override
  Description describe(Description description) => description.add('onstage');
}

class _IsInCard extends Matcher {
  const _IsInCard();

  @override
  bool matches(covariant Finder finder, Map<dynamic, dynamic> matchState) => _hasAncestorOfType(finder, Card);

  @override
  Description describe(Description description) => description.add('in card');
}

class _IsNotInCard extends Matcher {
  const _IsNotInCard();

  @override
  bool matches(covariant Finder finder, Map<dynamic, dynamic> matchState) => !_hasAncestorOfType(finder, Card);

  @override
  Description describe(Description description) => description.add('not in card');
}

class _HasOneLineDescription extends Matcher {
  const _HasOneLineDescription();

  @override
  bool matches(Object object, Map<dynamic, dynamic> matchState) {
    final String description = object.toString();
    return description.isNotEmpty
        && !description.contains('\n')
        && !description.contains('Instance of ')
        && description.trim() == description;
  }

  @override
  Description describe(Description description) => description.add('one line description');
}

class _MoreOrLessEquals extends Matcher {
  const _MoreOrLessEquals(this.value, this.epsilon);

  final double value;
  final double epsilon;

  @override
  bool matches(Object object, Map<dynamic, dynamic> matchState) {
    if (object is! double)
      return false;
    if (object == value)
      return true;
    final double test = object;
    return (test - value).abs() <= epsilon;
  }

  @override
  Description describe(Description description) => description.add('$value (±$epsilon)');
}
