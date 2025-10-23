// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [WidgetStateOutlinedBorder].

void main() => runApp(const WidgetStateOutlinedBorderExampleApp());

class WidgetStateOutlinedBorderExampleApp extends StatelessWidget {
  const WidgetStateOutlinedBorderExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: WidgetStateOutlinedBorderExample());
  }
}

class SelectedBorder extends RoundedRectangleBorder implements WidgetStateOutlinedBorder {
  const SelectedBorder();

  @override
  OutlinedBorder? resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.selected)) {
      return const RoundedRectangleBorder();
    }
    return null; // Defer to default value on the theme or widget.
  }
}

class WidgetStateOutlinedBorderExample extends StatefulWidget {
  const WidgetStateOutlinedBorderExample({super.key});

  @override
  State<WidgetStateOutlinedBorderExample> createState() => _WidgetStateOutlinedBorderExampleState();
}

class _WidgetStateOutlinedBorderExampleState extends State<WidgetStateOutlinedBorderExample> {
  bool isSelected = true;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: FilterChip(
        label: const Text('Select chip'),
        selected: isSelected,
        onSelected: (bool value) {
          setState(() {
            isSelected = value;
          });
        },
        shape: const SelectedBorder(),
      ),
    );
  }
}
