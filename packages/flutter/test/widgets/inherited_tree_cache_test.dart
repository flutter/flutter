// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('InheritedTreeCache returns null if element is not found', (WidgetTester tester) async {
    final InheritedTreeCache parent = InheritedTreeCache();

    expect(parent[InheritedElementA], isNull);
  });

  testWidgets('InheritedTreeCache can look up element from parent', (WidgetTester tester) async {
    final InheritedTreeCache parent = InheritedTreeCache();
    final InheritedTreeCache child = InheritedTreeCache(parent);
    final InheritedElementA elementA = InheritedElementA(const InheritedWidgetA());

    parent[InheritedElementA] = elementA;

    expect(child[InheritedElementA], elementA);
  });

  testWidgets('InheritedTreeCache can look up multiple elements from parent', (WidgetTester tester) async {
    final InheritedTreeCache parent = InheritedTreeCache();
    final InheritedTreeCache child = InheritedTreeCache(parent);
    final InheritedElementA elementA = InheritedElementA(const InheritedWidgetA());
    final InheritedElementA elementB = InheritedElementA(const InheritedWidgetB());

    parent[InheritedElementA] = elementA;
    parent[InheritedElementB] = elementB;

    expect(child[InheritedElementA], elementA);
    expect(child[InheritedElementB], elementB);
  });

  testWidgets('InheritedTreeCache does cache nulls', (WidgetTester tester) async {
    final InheritedTreeCache parent = InheritedTreeCache();
    final InheritedTreeCache child = InheritedTreeCache(parent);
    final InheritedElementA elementA = InheritedElementA(const InheritedWidgetA());

    // First look up element that has not been cached.
    expect(child[InheritedElementA], null);

    // Then manually add element to parent.
    parent[InheritedElementA] = elementA;

    // Then the child should not be able to find it.
    expect(child[InheritedElementA], null);
  });
}

class InheritedElementA extends InheritedElement {
  InheritedElementA(super.widget);
}

class InheritedWidgetA extends InheritedWidget {
  const InheritedWidgetA({ super.key }) : super(child: const SizedBox());

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}

class InheritedElementB extends InheritedElement {
  InheritedElementB(super.widget);
}

class InheritedWidgetB extends InheritedWidget {
  const InheritedWidgetB({ super.key }) : super(child: const SizedBox());

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}
