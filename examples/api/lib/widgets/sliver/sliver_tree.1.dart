// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  final List<SliverTreeNode<String>> tree = <SliverTreeNode<String>>[
    SliverTreeNode<String>('README.md'),
    SliverTreeNode<String>('analysis_options.yaml'),
    SliverTreeNode<String>(
      'lib',
      children: <SliverTreeNode<String>>[
        SliverTreeNode<String>(
          'src',
          children: <SliverTreeNode<String>>[
            SliverTreeNode<String>(
              'widgets',
              children: <SliverTreeNode<String>>[
                SliverTreeNode<String>('about.dart.dart'),
                SliverTreeNode<String>('app.dart'),
                SliverTreeNode<String>('basic.dart'),
                SliverTreeNode<String>('constants.dart'),
              ],
            ),
          ],
        ),
        SliverTreeNode<String>('widgets.dart'),
      ],
    ),
    SliverTreeNode<String>('pubspec.lock'),
    SliverTreeNode<String>('pubspec.yaml'),
    SliverTreeNode<String>(
      'test',
      children: <SliverTreeNode<String>>[
        SliverTreeNode<String>(
          'widgets',
          children: <SliverTreeNode<String>>[
            SliverTreeNode<String>('about_test.dart'),
            SliverTreeNode<String>('app_test.dart'),
            SliverTreeNode<String>('basic_test.dart'),
            SliverTreeNode<String>('constants_test.dart'),
          ],
        ),
      ],
    ),
  ];

  Widget _treeNodeBuilder(
    BuildContext context,
    SliverTreeNode<dynamic> node, {
    AnimationStyle? animationStyle,
  }) {
    final bool isParentNode = node.children.isNotEmpty;
    final BorderSide border = BorderSide(
      width: 2,
      color: Colors.purple[300]!,
    );
    return SliverTree.toggleNodeWith(
      node: node,
      child: Row(
        children: <Widget>[
          // Custom indentation
          SizedBox(width: 10.0 * node.depth! + 8.0),
          DecoratedBox(
            decoration: BoxDecoration(
              border: node.parent != null
                  ? Border(left: border, bottom: border)
                  : null,
            ),
            child: const SizedBox(height: 50.0, width: 20.0),
          ),
          // Leading icon for parent nodes
          if (isParentNode)
            DecoratedBox(
              decoration: BoxDecoration(border: Border.all()),
              child: SizedBox.square(
                dimension: 20.0,
                child: Icon(
                  node.isExpanded ? Icons.remove : Icons.add,
                  size: 14,
                ),
              ),
            ),
          // Spacer
          const SizedBox(width: 8.0),
          // Content
          Text(node.content.toString()),
        ],
      ),
    );
  }

  Widget _getTree() {
    return DecoratedSliver(
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      sliver: SliverTree<String>(
        tree: tree,
        onNodeToggle: (SliverTreeNode<dynamic> node) {
          setState(() {
            _selectedNode = node as SliverTreeNode<String>;
          });
        },
        treeNodeBuilder: _treeNodeBuilder,
        treeRowExtentBuilder: (
          SliverTreeNode<dynamic> node,
          SliverLayoutDimensions layoutDimensions,
        ) {
          // This gives more space to parent nodes.
          return node.children.isNotEmpty ? 60.0 : 50.0;
        },
        // No internal indentation, the custom treeNodeBuilder applies its
        // own indentation to decorate in the indented space.
        indentation: SliverTreeIndentationType.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final List<Widget> selectedChildren = <Widget>[];
    if (_selectedNode != null) {
      selectedChildren.clear();
      selectedChildren.addAll(<Widget>[
        const Spacer(),
        Icon(
          _selectedNode!.children.isEmpty
              ? Icons.file_open_outlined
              : Icons.folder_outlined,
        ),
        const SizedBox(height: 25.0),
        Text(_selectedNode!.content),
        const Spacer(),
      ]);
    }
    return Scaffold(
      body: Row(children: <Widget>[
        SizedBox(
          width: screenSize.width / 2,
          height: double.infinity,
          child: CustomScrollView(
            slivers: <Widget>[
              _getTree(),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(),
          ),
          child: SizedBox(
            width: screenSize.width / 2,
            height: double.infinity,
            child: Center(
              child: Column(
                children: selectedChildren,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
