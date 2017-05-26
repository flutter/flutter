// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:test/test.dart';

class TestTree extends Object with TreeDiagnosticsMixin {
  TestTree({
    this.name,
    this.children: const <TestTree>[],
  });

  final String name;
  final List<TestTree> children;

  @override
  String debugDescribeChildren(String prefix) {
    final StringBuffer buffer = new StringBuffer();
    for (TestTree child in children)
      buffer.write(child.toStringDeep('$prefix \u251C\u2500child ${child.name}: ', '$prefix \u2502'));
    return buffer.toString();
  }
}

void main() {
  test('TreeDiagnosticsMixin control test', () async {
    final TestTree tree = new TestTree(
      children: <TestTree>[
        new TestTree(name: 'node A'),
        new TestTree(
          name: 'node B',
          children: <TestTree>[
            new TestTree(name: 'node B1'),
            new TestTree(name: 'node B2'),
            new TestTree(name: 'node B3'),
          ],
        ),
        new TestTree(name: 'node C'),
      ],
    );

    final String dump =
        tree.toStringDeep().replaceAll(new RegExp(r'#\d+'), '#000');
    expect(dump, equals('''TestTree#000
 ├─child node A: TestTree#000
 │
 ├─child node B: TestTree#000
 │ ├─child node B1: TestTree#000
 │ │
 │ ├─child node B2: TestTree#000
 │ │
 │ ├─child node B3: TestTree#000
 │ │
 ├─child node C: TestTree#000
 │
'''));
  });
}
