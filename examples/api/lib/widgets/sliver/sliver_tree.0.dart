// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [SliverTree].

void main() => runApp(const SliverTreeExampleApp());

class SliverTreeExampleApp extends StatelessWidget {
  const SliverTreeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SliverTreeExample(),
    );
  }
}

class SliverTreeExample extends StatefulWidget {
  const SliverTreeExample({super.key});

  @override
  State<SliverTreeExample> createState() => _SliverTreeExampleState();
}

class _SliverTreeExampleState extends State<SliverTreeExample> {
  SliverTreeNode<String>? _selectedNode;
  final SliverTreeController controller = SliverTreeController();
  final List<SliverTreeNode<String>> _tree = <SliverTreeNode<String>>[
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SliverTree demo'),
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverTree<String>(
            tree: _tree,
            controller: controller,
            treeNodeBuilder: (
              BuildContext context,
              SliverTreeNode<dynamic> node, {
              AnimationStyle? animationStyle,
            }) {
              Widget child = GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  setState(() {
                    controller.toggleNode(node);
                    _selectedNode = node as SliverTreeNode<String>;
                  });
                },
                child: SliverTree.defaultTreeNodeBuilder(
                  context,
                  node,
                  animationStyle: animationStyle,
                ),
              );
              if (_selectedNode == node as SliverTreeNode<String>) {
                child = ColoredBox(
                  color: Colors.purple[100]!,
                  child: child,
                );
              }
              return child;
            },
          ),
        ],
      ),
    );
  }
}
