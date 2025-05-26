// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Flutter code sample for [SliverEnsureSemantics].

void main() => runApp(const SliverEnsureSemanticsExampleApp());

class SliverEnsureSemanticsExampleApp extends StatelessWidget {
  const SliverEnsureSemanticsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SliverEnsureSemanticsExample());
  }
}

class SliverEnsureSemanticsExample extends StatefulWidget {
  const SliverEnsureSemanticsExample({super.key});

  @override
  State<SliverEnsureSemanticsExample> createState() => _SliverEnsureSemanticsExampleState();
}

class _SliverEnsureSemanticsExampleState extends State<SliverEnsureSemanticsExample> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: const Text('SliverEnsureSemantics Demo'),
      ),
      body: Center(
        child: CustomScrollView(
          semanticChildCount: 106,
          slivers: <Widget>[
            SliverEnsureSemantics(
              sliver: SliverToBoxAdapter(
                child: IndexedSemantics(
                  index: 0,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Semantics(
                            header: true,
                            headingLevel: 3,
                            child: Text('Steps to reproduce', style: theme.textTheme.headlineSmall),
                          ),
                          const Text('Issue description'),
                          Semantics(
                            header: true,
                            headingLevel: 3,
                            child: Text('Expected Results', style: theme.textTheme.headlineSmall),
                          ),
                          Semantics(
                            header: true,
                            headingLevel: 3,
                            child: Text('Actual Results', style: theme.textTheme.headlineSmall),
                          ),
                          Semantics(
                            header: true,
                            headingLevel: 3,
                            child: Text('Code Sample', style: theme.textTheme.headlineSmall),
                          ),
                          Semantics(
                            header: true,
                            headingLevel: 3,
                            child: Text('Screenshots', style: theme.textTheme.headlineSmall),
                          ),
                          Semantics(
                            header: true,
                            headingLevel: 3,
                            child: Text('Logs', style: theme.textTheme.headlineSmall),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverFixedExtentList(
              itemExtent: 44.0,
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Card(
                    child: Padding(padding: const EdgeInsets.all(8.0), child: Text('Item $index')),
                  );
                },
                childCount: 50,
                semanticIndexOffset: 1,
              ),
            ),
            SliverEnsureSemantics(
              sliver: SliverToBoxAdapter(
                child: IndexedSemantics(
                  index: 51,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Semantics(header: true, child: const Text('Footer 1')),
                    ),
                  ),
                ),
              ),
            ),
            SliverEnsureSemantics(
              sliver: SliverToBoxAdapter(
                child: IndexedSemantics(
                  index: 52,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Semantics(header: true, child: const Text('Footer 2')),
                    ),
                  ),
                ),
              ),
            ),
            SliverEnsureSemantics(
              sliver: SliverToBoxAdapter(
                child: IndexedSemantics(
                  index: 53,
                  child: Semantics(link: true, child: const Text('Link #1')),
                ),
              ),
            ),
            SliverEnsureSemantics(
              sliver: SliverToBoxAdapter(
                child: IndexedSemantics(
                  index: 54,
                  child: OverflowBar(
                    children: <Widget>[
                      TextButton(onPressed: () {}, child: const Text('Button 1')),
                      TextButton(onPressed: () {}, child: const Text('Button 2')),
                    ],
                  ),
                ),
              ),
            ),
            SliverEnsureSemantics(
              sliver: SliverToBoxAdapter(
                child: IndexedSemantics(
                  index: 55,
                  child: Semantics(link: true, child: const Text('Link #2')),
                ),
              ),
            ),
            SliverEnsureSemantics(
              sliver: SliverSemanticsList(
                sliver: SliverFixedExtentList(
                  itemExtent: 44.0,
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return Semantics(
                        role: SemanticsRole.listItem,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Second List Item $index'),
                          ),
                        ),
                      );
                    },
                    childCount: 50,
                    semanticIndexOffset: 56,
                  ),
                ),
              ),
            ),
            SliverEnsureSemantics(
              sliver: SliverToBoxAdapter(
                child: IndexedSemantics(
                  index: 107,
                  child: Semantics(link: true, child: const Text('Link #3')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A sliver that assigns the role of SemanticsRole.list to its sliver child.
class SliverSemanticsList extends SingleChildRenderObjectWidget {
  const SliverSemanticsList({super.key, required Widget sliver}) : super(child: sliver);

  @override
  RenderSliverSemanticsList createRenderObject(BuildContext context) => RenderSliverSemanticsList();
}

class RenderSliverSemanticsList extends RenderProxySliver {
  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.role = SemanticsRole.list;
  }
}
