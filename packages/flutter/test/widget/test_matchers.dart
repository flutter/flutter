// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';

bool _hasAncestorOfType(WidgetTester tester, Finder finder, Type targetType) {
  expect(tester, hasWidget(finder));
  bool result = false;
  finder.findFirst(tester).visitAncestorElements((Element ancestor) {
    if (ancestor.widget.runtimeType == targetType) {
      result = true;
      return false;
    }
    return true;
  });
  return result;
}

class _IsOnStage extends Matcher {
  const _IsOnStage(this.tester);

  final WidgetTester tester;

  @override
  bool matches(Finder finder, Map<dynamic, dynamic> matchState) => !_hasAncestorOfType(tester, finder, OffStage);

  @override
  Description describe(Description description) => description.add('onstage');
}

class _IsOffStage extends Matcher {
  const _IsOffStage(this.tester);

  final WidgetTester tester;

  @override
  bool matches(Finder finder, Map<dynamic, dynamic> matchState) => _hasAncestorOfType(tester, finder, OffStage);

  @override
  Description describe(Description description) => description.add('offstage');
}

class _IsInCard extends Matcher {
  const _IsInCard(this.tester);

  final WidgetTester tester;

  @override
  bool matches(Finder finder, Map<dynamic, dynamic> matchState) => _hasAncestorOfType(tester, finder, Card);

  @override
  Description describe(Description description) => description.add('in card');
}

class _IsNotInCard extends Matcher {
  const _IsNotInCard(this.tester);

  final WidgetTester tester;

  @override
  bool matches(Finder finder, Map<dynamic, dynamic> matchState) => !_hasAncestorOfType(tester, finder, Card);

  @override
  Description describe(Description description) => description.add('not in card');
}

Matcher isOnStage(WidgetTester tester) => new _IsOnStage(tester);
Matcher isOffStage(WidgetTester tester) => new _IsOffStage(tester);
Matcher isInCard(WidgetTester tester) => new _IsInCard(tester);
Matcher isNotInCard(WidgetTester tester) => new _IsNotInCard(tester);
