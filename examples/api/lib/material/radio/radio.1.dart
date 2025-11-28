// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Radio] to showcase how to customize radio style.

void main() => runApp(const RadioExampleApp());

class RadioExampleApp extends StatelessWidget {
  const RadioExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Radio Sample')),
        body: const Center(child: RadioExample()),
      ),
    );
  }
}

enum RadioType { fillColor, backgroundColor, side, innerRadius }

class RadioExample extends StatefulWidget {
  const RadioExample({super.key});

  @override
  State<RadioExample> createState() => _RadioExampleState();
}

class _RadioExampleState extends State<RadioExample> {
  RadioType? _radioType = RadioType.fillColor;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<RadioType>(
      groupValue: _radioType,
      onChanged: (RadioType? value) {
        setState(() {
          _radioType = value;
        });
      },
      child: Column(
        children: <Widget>[
          ListTile(
            title: const Text('Fill color'),
            leading: Radio<RadioType>(
              value: RadioType.fillColor,
              fillColor: WidgetStateColor.resolveWith((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.deepPurple;
                } else {
                  return Colors.deepPurple.shade200;
                }
              }),
            ),
          ),
          ListTile(
            title: const Text('Background color'),
            leading: Radio<RadioType>(
              value: RadioType.backgroundColor,
              backgroundColor: WidgetStateColor.resolveWith((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.greenAccent.withValues(alpha: 0.5);
                } else {
                  return Colors.grey.shade300.withValues(alpha: 0.3);
                }
              }),
            ),
          ),
          ListTile(
            title: const Text('Side'),
            leading: Radio<RadioType>(
              value: RadioType.side,
              side: WidgetStateBorderSide.resolveWith((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return const BorderSide(
                    color: Colors.red,
                    width: 4,
                    strokeAlign: BorderSide.strokeAlignCenter,
                  );
                } else {
                  return const BorderSide(
                    color: Colors.grey,
                    width: 1.5,
                    strokeAlign: BorderSide.strokeAlignCenter,
                  );
                }
              }),
            ),
          ),

          const ListTile(
            title: Text('Inner radius'),
            leading: Radio<RadioType>(
              value: RadioType.innerRadius,
              innerRadius: WidgetStatePropertyAll<double>(6),
            ),
          ),
        ],
      ),
    );
  }
}
