// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:test/test.dart';

bool _hasAncestorOfType(Element element, Type targetType) {
  expect(element, isNotNull);
  bool result = false;
  element.visitAncestorElements((Element ancestor) {
    if (ancestor.widget.runtimeType == targetType) {
      result = true;
      return false;
    }
    return true;
  });
  return result;
}

class _IsOnStage extends Matcher {
  const _IsOnStage();
  bool matches(item, Map matchState) => !_hasAncestorOfType(item, OffStage);
  Description describe(Description description) => description.add('onstage');
}

class _IsOffStage extends Matcher {
  const _IsOffStage();
  bool matches(item, Map matchState) => _hasAncestorOfType(item, OffStage);
  Description describe(Description description) => description.add('offstage');
}

class _IsInCard extends Matcher {
  const _IsInCard();
  bool matches(item, Map matchState) => _hasAncestorOfType(item, Card);
  Description describe(Description description) => description.add('in card');
}

class _IsNotInCard extends Matcher {
  const _IsNotInCard();
  bool matches(item, Map matchState) => !_hasAncestorOfType(item, Card);
  Description describe(Description description) => description.add('not in card');
}

const Matcher isOnStage = const _IsOnStage();
const Matcher isOffStage = const _IsOffStage();
const Matcher isInCard = const _IsInCard();
const Matcher isNotInCard = const _IsNotInCard();
