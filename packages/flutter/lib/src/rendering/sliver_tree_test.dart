// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

List<SliverTreeNode<String>> _setUpNodes() {
  return <SliverTreeNode<String>>[
    SliverTreeNode<String>('First'),
    SliverTreeNode<String>(
      'Second',
      children: <SliverTreeNode<String>>[
        SliverTreeNode<String>(
          'alpha',
          children: <SliverTreeNode<String>>[
            SliverTreeNode<String>('uno'),
            SliverTreeNode<String>('dos'),
            SliverTreeNode<String>('tres'),
          ],
        ),
        SliverTreeNode<String>('beta'),
        SliverTreeNode<String>('kappa'),
      ],
    ),
    SliverTreeNode<String>(
      'Third',
      expanded: true,
      children: <SliverTreeNode<String>>[
        SliverTreeNode<String>('gamma'),
        SliverTreeNode<String>('delta'),
        SliverTreeNode<String>('epsilon'),
      ],
    ),
    SliverTreeNode<String>('Fourth'),
  ];
}

List<SliverTreeNode<String>> treeNodes = _setUpNodes();

void main() {
  testWidgets('asserts proper axis directions', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CustomScrollView(
        reverse: true,
        slivers: <Widget>[
          SliverTree<String>(tree: treeNodes),
        ],
      ),
    ));
    expect(tester.takeException().toString(), contains(''));
  });
}
