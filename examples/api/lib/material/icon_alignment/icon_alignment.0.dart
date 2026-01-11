// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for the [IconAlignment] property on various Material
/// button widgets.

void main() {
  runApp(const IconAlignmentApp());
}

class IconAlignmentApp extends StatelessWidget {
  const IconAlignmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: IconAlignmentExample()));
  }
}

class IconAlignmentExample extends StatefulWidget {
  const IconAlignmentExample({super.key});

  @override
  State<IconAlignmentExample> createState() => _IconAlignmentExampleState();
}

class _IconAlignmentExampleState extends State<IconAlignmentExample> {
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
              OverflowBar(
                alignment: MainAxisAlignment.spaceEvenly,
                overflowAlignment: OverflowBarAlignment.center,
                spacing: 10,
                overflowSpacing: 10,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      const Text('Icon alignment'),
                      const SizedBox(height: 10),
                      SegmentedButton<IconAlignment>(
                        onSelectionChanged: (Set<IconAlignment> value) {
                          setState(() {
                            _iconAlignment = value.first;
                          });
                        },
                        selected: <IconAlignment>{_iconAlignment},
                        segments: IconAlignment.values.map((
                          IconAlignment iconAlignment,
                        ) {
                          return ButtonSegment<IconAlignment>(
                            value: iconAlignment,
                            label: Text(iconAlignment.name),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  Column(
                    children: <Widget>[
                      const Text('Text direction'),
                      const SizedBox(height: 10),
                      SegmentedButton<TextDirection>(
                        onSelectionChanged: (Set<TextDirection> value) {
                          setState(() {
                            _textDirection = value.first;
                          });
                        },
                        selected: <TextDirection>{_textDirection},
                        segments: const <ButtonSegment<TextDirection>>[
                          ButtonSegment<TextDirection>(
                            value: TextDirection.ltr,
                            label: Text('LTR'),
                          ),
                          ButtonSegment<TextDirection>(
                            value: TextDirection.rtl,
                            label: Text('RTL'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
