// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for using [ButtonStyleButton.iconAlignment] parameter.

void main() => runApp(const ButtonStyleButtonIconAlignmentExampleApp());

class ButtonStyleButtonIconAlignmentExampleApp extends StatelessWidget {
  const ButtonStyleButtonIconAlignmentExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ButtonStyleButton.iconAlignment'),
        ),
        body: const ButtonStyleButtonIconAlignmentExample(),
      ),
    );
  }
}

class ButtonStyleButtonIconAlignmentExample extends StatefulWidget {
  const ButtonStyleButtonIconAlignmentExample({super.key});

  @override
  State<ButtonStyleButtonIconAlignmentExample> createState() => _ButtonStyleButtonIconAlignmentExampleState();
}

class _ButtonStyleButtonIconAlignmentExampleState extends State<ButtonStyleButtonIconAlignmentExample> {
  TextDirection _textDirection = TextDirection.ltr;
  IconAlignment _iconAlignment = IconAlignment.start;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Directionality(
        key: const Key('Directionality'),
        textDirection: _textDirection,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Spacer(),
              OverflowBar(
                spacing: 10,
                overflowSpacing: 20,
                alignment: MainAxisAlignment.center,
                overflowAlignment: OverflowBarAlignment.center,
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.sunny),
                    label: const Text('ElevatedButton'),
                    iconAlignment: _iconAlignment,
                  ),
                  FilledButton.icon(
                    onPressed: () {},
                  icon: const Icon(Icons.beach_access),
                    label: const Text('FilledButton'),
                    iconAlignment: _iconAlignment,
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {},
                    icon: const Icon(Icons.cloud),
                    label: const Text('FilledButton Tonal'),
                    iconAlignment: _iconAlignment,
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.light),
                    label: const Text('OutlinedButton'),
                    iconAlignment: _iconAlignment,
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.flight_takeoff),
                    label: const Text('TextButton'),
                    iconAlignment: _iconAlignment,
                  ),
                ],
              ),
              const Spacer(),
              const Text('Icon alignment'),
              SegmentedButton<IconAlignment>(
                onSelectionChanged: (Set<IconAlignment> value) {
                  setState(() {
                    _iconAlignment = value.first;
                  });
                },
                selected: <IconAlignment>{ _iconAlignment },
                segments: IconAlignment.values.map((IconAlignment iconAlignment) {
                  return ButtonSegment<IconAlignment>(
                    value: iconAlignment,
                    label: Text(iconAlignment.name),
                  );
                }).toList(),
              ),
              SwitchListTile(
                title: const Text('RTL'),
                value: _textDirection == TextDirection.rtl,
                onChanged: (bool value) {
                  setState(() {
                    _textDirection = value ? TextDirection.rtl : TextDirection.ltr;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
