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
    const ScrollPhysics d = const TestScrollPhysics(name: 'd');
    const ScrollPhysics e = const TestScrollPhysics(name: 'e');

    expect(a.parent, null);
    expect(b.parent, null);
    expect(c.parent, null);

    final TestScrollPhysics ab = a.applyTo(b);
    expect(ab.names, 'a b');

    final TestScrollPhysics abc = ab.applyTo(c);
    expect(abc.names, 'a b c');

    final TestScrollPhysics de = d.applyTo(e);
    expect(de.names, 'd e');

    final TestScrollPhysics abcde = abc.applyTo(de);
    expect(abcde.names, 'a b c d e');
  });

  test('ScrollPhysics subclasses applyTo()', () {
    const ScrollPhysics bounce = const BouncingScrollPhysics();
    const ScrollPhysics clamp = const ClampingScrollPhysics();
    const ScrollPhysics never = const NeverScrollableScrollPhysics();
    const ScrollPhysics always = const AlwaysScrollableScrollPhysics();
    const ScrollPhysics page = const PageScrollPhysics();

    String types(ScrollPhysics s) => s.parent == null ? '${s.runtimeType}' : '${s.runtimeType} ${types(s.parent)}';

    expect(types(bounce.applyTo(clamp.applyTo(never.applyTo(always.applyTo(page))))),
      'BouncingScrollPhysics ClampingScrollPhysics NeverScrollableScrollPhysics AlwaysScrollableScrollPhysics PageScrollPhysics');

    expect(types(clamp.applyTo(never.applyTo(always.applyTo(page.applyTo(bounce))))),
      'ClampingScrollPhysics NeverScrollableScrollPhysics AlwaysScrollableScrollPhysics PageScrollPhysics BouncingScrollPhysics');

    expect(types(never.applyTo(always.applyTo(page.applyTo(bounce.applyTo(clamp))))),
      'NeverScrollableScrollPhysics AlwaysScrollableScrollPhysics PageScrollPhysics BouncingScrollPhysics ClampingScrollPhysics');

    expect(types(always.applyTo(page.applyTo(bounce.applyTo(clamp.applyTo(never))))),
      'AlwaysScrollableScrollPhysics PageScrollPhysics BouncingScrollPhysics ClampingScrollPhysics NeverScrollableScrollPhysics');

    expect(types(page.applyTo(bounce.applyTo(clamp.applyTo(never.applyTo(always))))),
      'PageScrollPhysics BouncingScrollPhysics ClampingScrollPhysics NeverScrollableScrollPhysics AlwaysScrollableScrollPhysics');
  });
}
