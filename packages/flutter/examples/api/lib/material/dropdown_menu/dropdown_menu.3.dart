// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [DropdownMenu] showing how to programmatically
/// clear or reset the selection using a [TextEditingController].

void main() => runApp(const DropdownMenuClearExampleApp());

class DropdownMenuClearExampleApp extends StatelessWidget {
  const DropdownMenuClearExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Clear DropdownMenu Sample')),
        body: const Center(child: DropdownMenuClearExample()),
      ),
    );
  }
}

class DropdownMenuClearExample extends StatefulWidget {
  const DropdownMenuClearExample({super.key});

  @override
  State<DropdownMenuClearExample> createState() =>
      _DropdownMenuClearExampleState();
}

enum ColorItem {
  red('Red'),
  green('Green'),
  blue('Blue');

  const ColorItem(this.label);
  final String label;
}

class _DropdownMenuClearExampleState extends State<DropdownMenuClearExample> {
  final TextEditingController _controller = TextEditingController();
  ColorItem? _selectedColor;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSelection() {
    setState(() {
      _selectedColor = null;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        DropdownMenu<ColorItem>(
          controller: _controller,
          initialSelection: _selectedColor,
          label: const Text('Color'),
          onSelected: (ColorItem? color) {
            setState(() {
              _selectedColor = color;
            });
          },
          dropdownMenuEntries: ColorItem.values
              .map<DropdownMenuEntry<ColorItem>>((ColorItem color) {
                return DropdownMenuEntry<ColorItem>(
                  value: color,
                  label: color.label,
                );
              })
              .toList(),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _clearSelection,
          child: const Text('Clear selection'),
        ),
        const SizedBox(height: 20),
        Text('Selected: ${_selectedColor?.label ?? 'None'}'),
      ],
    );
  }
}
