// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.group_context;

import 'dart:async';

import '../unittest.dart';

/// Setup and teardown functions for a group and its parents, the latter
/// for chaining.
class GroupContext {
  /// The parent context, or `null`.
  final GroupContext parent;

  /// Whether this is the root context.
  bool get isRoot => parent == null;

  /// Description text of the current test group.
  final String _name;

  /// The set-up function called before each test in a group.
  Function get testSetUp => _testSetUp;
  Function _testSetUp;

  set testSetUp(Function setUp) {
    if (parent == null || parent.testSetUp == null) {
      _testSetUp = setUp;
      return;
    }

    _testSetUp = () {
      var f = parent.testSetUp();
      if (f is Future) {
        return f.then((_) => setUp());
      } else {
        return setUp();
      }
    };
  }

  /// The tear-down function called after each test in a group.
  Function get testTearDown => _testTearDown;
  Function _testTearDown;

  set testTearDown(Function tearDown) {
    if (parent == null || parent.testTearDown == null) {
      _testTearDown = tearDown;
      return;
    }

    _testTearDown = () {
      var f = tearDown();
      if (f is Future) {
        return f.then((_) => parent.testTearDown());
      } else {
        return parent.testTearDown();
      }
    };
  }

  /// Returns the fully-qualified name of this context.
  String get fullName =>
      (isRoot || parent.isRoot) ? _name : "${parent.fullName}$groupSep$_name";

  GroupContext.root()
      : parent = null,
        _name = '';

  GroupContext(this.parent, this._name) {
    _testSetUp = parent.testSetUp;
    _testTearDown = parent.testTearDown;
  }
}
