// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for custom labeled checkbox.

import 'package:flutter/material.dart';

void main() => runApp(const LabeledCheckBoxApp());

class LabeledCheckBoxApp extends StatelessWidget {
  const LabeledCheckBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LabeledCheckBoxExample(),
    );
  }
}

class LabeledCheckbox extends StatelessWidget {
  const LabeledCheckbox({
    super.key,
    required this.label,
    required this.padding,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final EdgeInsets padding;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(!value);
      },
      child: Padding(
        padding: padding,
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Checkbox(
              value: value,
              onChanged: (bool? newValue) {
                onChanged(newValue!);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LabeledCheckBoxExample extends StatefulWidget {
  const LabeledCheckBoxExample({super.key});

  @override
  State<LabeledCheckBoxExample> createState() => _LabeledCheckBoxExampleState();
}

class _LabeledCheckBoxExampleState extends State<LabeledCheckBoxExample> {
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Labeled Checkbox Sample')),
      body: Center(
        child: LabeledCheckbox(
          label: 'This is the label text',
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          value: _isSelected,
          onChanged: (bool newValue) {
            setState(() {
              _isSelected = newValue;
            });
          },
        ),
      ),
    );
  }
}
