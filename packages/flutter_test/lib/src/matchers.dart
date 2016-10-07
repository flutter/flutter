// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:test/test.dart';
import 'package:meta/meta.dart';

import 'finders.dart';

/// Asserts that the [Finder] matches no widgets in the widget tree.
///
/// Example:
///
///     expect(find.text('Save'), findsNothing);
const Matcher findsNothing = const _FindsWidgetMatcher(null, 0);

/// Asserts that the [Finder] locates at least one widget in the widget tree.
///
/// Example:
///
///     expect(find.text('Save'), findsWidgets);
const Matcher findsWidgets = const _FindsWidgetMatcher(1, null);

/// Asserts that the [Finder] locates at exactly one widget in the widget tree.
///
/// Example:
///
///     expect(find.text('Save'), findsOneWidget);
const Matcher findsOneWidget = const _FindsWidgetMatcher(1, 1);

/// Asserts that the [Finder] locates the specified number of widgets in the widget tree.
///
/// Example:
///
///     expect(find.text('Save'), findsNWidgets(2));
Matcher findsNWidgets(int n) => new _FindsWidgetMatcher(n, n);

/// Asserts that the [Finder] locates the a single widget that has at
/// least one [Offstage] widget ancestor.
///
/// It's important to use a full finder, since by default finders exclude
/// offstage widgets.
///
/// Example:
///
///     expect(find.text('Save', skipOffstage: false), isOffstage);
const Matcher isOffstage = const _IsOffstage();

/// Asserts that the [Finder] locates the a single widget that has no
/// [Offstage] widget ancestors.
const Matcher isOnstage = const _IsOnstage();

/// Asserts that the [Finder] locates the a single widget that has at
/// least one [Card] widget ancestor.
const Matcher isInCard = const _IsInCard();

/// Asserts that the [Finder] locates the a single widget that has no
/// [Card] widget ancestors.
const Matcher isNotInCard = const _IsNotInCard();

/// Asserts that an object's toString() is a plausible one-line description.
///
/// Specifically, this matcher checks that the string does not contains newline
/// characters, and does not have leading or trailing whitespace, and is not
/// empty.
const Matcher hasOneLineDescription = const _HasOneLineDescription();

class _FindsWidgetMatcher extends Matcher {
  const _FindsWidgetMatcher(this.min, this.max);

  final int min;
  final int max;

  @override
  bool matches(@checked Finder finder, Map<dynamic, dynamic> matchState) {
    assert(min != null || max != null);
    assert(min == null || max == null || min <= max);
    matchState[Finder] = finder;
    int count = 0;
    Iterator<Element> iterator = finder.evaluate().iterator;
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
    Finder finder = matchState[Finder];
    int count = finder.evaluate().length;
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
  Iterable<Element> nodes = finder.evaluate();
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
  bool matches(@checked Finder finder, Map<dynamic, dynamic> matchState) {
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
  bool matches(@checked Finder finder, Map<dynamic, dynamic> matchState) {
    Iterable<Element> nodes = finder.evaluate();
    if (nodes.length != 1)
      return false;
    bool result = true;
    nodes.single.visitAncestorElements((Element ancestor) {
      Widget widget = ancestor.widget;
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
  bool matches(@checked Finder finder, Map<dynamic, dynamic> matchState) => _hasAncestorOfType(finder, Card);

  @override
  Description describe(Description description) => description.add('in card');
}

class _IsNotInCard extends Matcher {
  const _IsNotInCard();

  @override
  bool matches(@checked Finder finder, Map<dynamic, dynamic> matchState) => !_hasAncestorOfType(finder, Card);

  @override
  Description describe(Description description) => description.add('not in card');
}

class _HasOneLineDescription extends Matcher {
  const _HasOneLineDescription();

  @override
  bool matches(Object object, Map<dynamic, dynamic> matchState) {
    String description = object.toString();
    return description.isNotEmpty
        && !description.contains('\n')
        && description.trim() == description;
  }

  @override
  Description describe(Description description) => description.add('one line description');
}
