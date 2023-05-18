// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for migrating from [ToggleButtons] to [SegmentedButton].

void main() {
  runApp(const ToggleButtonsApp());
}

class ToggleButtonsApp extends StatelessWidget {
  const ToggleButtonsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(
        body: ToggleButtonsExample(),
      ),
    );
  }
}

enum Sizes { extraSmall, small, medium, large, extraLarge }

class ToggleButtonsExample extends StatefulWidget {
  const ToggleButtonsExample({super.key});

  @override
  State<ToggleButtonsExample> createState() => _ToggleButtonsExampleState();
}

class _ToggleButtonsExampleState extends State<ToggleButtonsExample> {
  final List<bool> _toggleButtonsSelection = Sizes.values.map((Sizes e) => e == Sizes.medium).toList();
  Set<Sizes> _segmentedButtonSelection = <Sizes>{Sizes.medium};

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('ToggleButtons'),
          const SizedBox(height: 10),
          // This ToggleButtons allows multiple or no selection.
          ToggleButtons(
            // ToggleButtons uses a List<bool> to track its selection state.
            isSelected: _toggleButtonsSelection,
            // This callback return the index of the child that was pressed.
            onPressed: (int index) {
              setState(() {
                _toggleButtonsSelection[index] = !_toggleButtonsSelection[index];
              });
            },
            // Constraints are used to determine the size of each child widget.
            constraints: const BoxConstraints(
              minHeight: 32.0,
              minWidth: 56.0,
            ),
            // ToggleButtons uses a List<Widget> to build its children.
            children: const <Widget>[
              Text('XS'),
              Text('S'),
              Text('M'),
              Text('L'),
              Text('XL'),
            ],
          ),
          const SizedBox(height: 20),
          const Text('SegmentedButton'),
          const SizedBox(height: 10),
          SegmentedButton<Sizes>(
            // ToggleButtons above allows multiple or no selection.
            // Set `multiSelectionEnabled` and `emptySelectionAllowed` to true
            // to match the behavior of ToggleButtons.
            multiSelectionEnabled: true,
            emptySelectionAllowed: true,
            // Hide the selected icon to match the behavior of ToggleButtons.
            showSelectedIcon: false,
            // SegmentedButton uses a Set<T> to track its selection state.
            selected: _segmentedButtonSelection,
            // This callback returns a set of selected segment values.
            onSelectionChanged: (Set<Sizes> newSelection) {
              setState(() {
                _segmentedButtonSelection = newSelection;
              });
            },
            // SegmentedButton uses a List<ButtonSegment<T>> to build its children
            // instead of a List<Widget> like ToggleButtons.
            segments: const <ButtonSegment<Sizes>>[
              ButtonSegment<Sizes>(value: Sizes.extraSmall, label: Text('XS')),
              ButtonSegment<Sizes>(value: Sizes.small, label: Text('S')),
              ButtonSegment<Sizes>(value: Sizes.medium, label: Text('M')),
              ButtonSegment<Sizes>(value: Sizes.large, label: Text('L')),
              ButtonSegment<Sizes>(value: Sizes.extraLarge, label: Text('XL')),
            ],
          ),
        ],
      ),
    );
  }
}
