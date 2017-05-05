// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestScrollPhysics extends ScrollPhysics {
  const TestScrollPhysics({ this.name, ScrollPhysics parent }) : super(parent: parent);
  final String name;

  @override
  TestScrollPhysics applyTo(ScrollPhysics ancestor) {
    return new TestScrollPhysics(name: name, parent: parent?.applyTo(ancestor) ?? ancestor);
  }

  TestScrollPhysics get namedParent => parent;
  String get names => parent == null ? name : '$name ${namedParent.names}';

  @override
  String toString() {
    if (parent == null)
      return '$runtimeType($name)';
    return '$runtimeType($name) -> $parent';
  }
}


void main() {
  test('ScrollPhysics applyTo()', () {
    const ScrollPhysics a = const TestScrollPhysics(name: 'a');
    const ScrollPhysics b = const TestScrollPhysics(name: 'b');
    const ScrollPhysics c = const TestScrollPhysics(name: 'c');

    expect(a.parent, null);
    expect(b.parent, null);
    expect(c.parent, null);

    final TestScrollPhysics ab = a.applyTo(b);
    expect(ab.names, 'a b');

    final TestScrollPhysics abc = ab.applyTo(c);
    expect(abc.names, 'a b c');
  });
}
