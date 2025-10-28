// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for custom labeled radio.

void main() => runApp(const LabeledRadioApp());

class LabeledRadioApp extends StatelessWidget {
  const LabeledRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Custom Labeled Radio Sample')),
        body: const LabeledRadioExample(),
      ),
    );
  }
}

class LabeledRadio extends StatelessWidget {
  const LabeledRadio({super.key, required this.label, required this.padding, required this.value});

  final String label;
  final EdgeInsets padding;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        RadioGroup.maybeOf<bool>(context)?.onChanged(value);
      },
      child: Padding(
        padding: padding,
        child: Row(
          children: <Widget>[
            Radio<bool>(value: value),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class LabeledRadioExample extends StatefulWidget {
  const LabeledRadioExample({super.key});

  @override
  State<LabeledRadioExample> createState() => _LabeledRadioExampleState();
}

class _LabeledRadioExampleState extends State<LabeledRadioExample> {
  bool _isRadioSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RadioGroup<bool>(
        groupValue: _isRadioSelected,
        onChanged: (bool? newValue) {
          setState(() {
            _isRadioSelected = newValue!;
          });
        },
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <LabeledRadio>[
            LabeledRadio(
              label: 'This is the first label text',
              padding: EdgeInsets.symmetric(horizontal: 5.0),
              value: true,
            ),
            LabeledRadio(
              label: 'This is the second label text',
              padding: EdgeInsets.symmetric(horizontal: 5.0),
              value: false,
            ),
          ],
        ),
      ),
    );
  }
}
