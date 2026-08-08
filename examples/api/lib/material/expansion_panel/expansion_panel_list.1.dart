// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for a flat [ExpansionPanelList] with divider separators.

void main() => runApp(const FlatExpansionPanelListExampleApp());

class FlatExpansionPanelListExampleApp extends StatelessWidget {
  const FlatExpansionPanelListExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Flat ExpansionPanelList Sample')),
        body: const Center(child: FlatExpansionPanelListExample()),
      ),
    );
  }
}

class FlatExpansionPanelListExample extends StatefulWidget {
  const FlatExpansionPanelListExample({super.key});

  @override
  State<FlatExpansionPanelListExample> createState() =>
      _FlatExpansionPanelListExampleState();
}

class _FlatExpansionPanelListExampleState
    extends State<FlatExpansionPanelListExample> {
  final List<bool> _isExpanded = <bool>[false, false, false];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: ExpansionPanelList(
            materialGapSize: 0,
            expandedHeaderPadding: EdgeInsets.zero,
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                _isExpanded[index] = isExpanded;
              });
            },
            children: <ExpansionPanel>[
              ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return const ListTile(title: Text('Panel A'));
                },
                body: const ListTile(title: Text('Content for Panel A')),
                isExpanded: _isExpanded[0],
                canTapOnHeader: true,
              ),
              ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return const ListTile(title: Text('Panel B'));
                },
                body: const ListTile(title: Text('Content for Panel B')),
                isExpanded: _isExpanded[1],
                canTapOnHeader: true,
              ),
              ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return const ListTile(title: Text('Panel C'));
                },
                body: const ListTile(title: Text('Content for Panel C')),
                isExpanded: _isExpanded[2],
                canTapOnHeader: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
