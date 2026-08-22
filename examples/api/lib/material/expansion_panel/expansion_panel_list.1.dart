// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [ExpansionPanel.trailingIconVisibility].

void main() => runApp(const ExpansionPanelIconVisibilityExampleApp());

class ExpansionPanelIconVisibilityExampleApp extends StatelessWidget {
  const ExpansionPanelIconVisibilityExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('ExpansionPanel Icon Visibility')),
        body: const ExpansionPanelIconVisibilityExample(),
      ),
    );
  }
}

class ExpansionPanelIconVisibilityExample extends StatefulWidget {
  const ExpansionPanelIconVisibilityExample({super.key});

  @override
  State<ExpansionPanelIconVisibilityExample> createState() =>
      _ExpansionPanelIconVisibilityExampleState();
}

class _ExpansionPanelIconVisibilityExampleState
    extends State<ExpansionPanelIconVisibilityExample> {
  ExpansionPanelIconVisibility _visibility =
      ExpansionPanelIconVisibility.visible;
  bool _canTapOnHeader = false;
  final List<bool> _isExpanded = <bool>[false, false, false];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: <Widget>[
                SegmentedButton<ExpansionPanelIconVisibility>(
                  segments: const <ButtonSegment<ExpansionPanelIconVisibility>>[
                    ButtonSegment<ExpansionPanelIconVisibility>(
                      value: ExpansionPanelIconVisibility.visible,
                      label: Text('Visible'),
                    ),
                    ButtonSegment<ExpansionPanelIconVisibility>(
                      value: ExpansionPanelIconVisibility.hidden,
                      label: Text('Hidden'),
                    ),
                    ButtonSegment<ExpansionPanelIconVisibility>(
                      value: ExpansionPanelIconVisibility.gone,
                      label: Text('Gone'),
                    ),
                  ],
                  selected: <ExpansionPanelIconVisibility>{_visibility},
                  onSelectionChanged:
                      (Set<ExpansionPanelIconVisibility> selected) {
                        setState(() {
                          _visibility = selected.first;
                        });
                      },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('canTapOnHeader'),
                  value: _canTapOnHeader,
                  onChanged: (bool value) {
                    setState(() {
                      _canTapOnHeader = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                _isExpanded[index] = isExpanded;
              });
            },
            children: <ExpansionPanel>[
              for (int i = 0; i < 3; i++)
                ExpansionPanel(
                  trailingIconVisibility: _visibility,
                  canTapOnHeader: _canTapOnHeader,
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return ListTile(
                      title: Text('Panel ${i + 1}'),
                      trailing: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                  body: ListTile(
                    title: Text('Panel ${i + 1} content'),
                    subtitle: const Text(
                      'When the icon visibility is hidden, the space is preserved. '
                      'When gone, the space is removed.',
                    ),
                  ),
                  isExpanded: _isExpanded[i],
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
