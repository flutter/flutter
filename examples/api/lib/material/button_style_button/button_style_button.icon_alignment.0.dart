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
          title: const Text('ButtonStyleButton iconAlignment Sample'),
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
  IconAlignment iconAlignment = IconAlignment.start;
  TextDirection textDirection = TextDirection.ltr;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      key: const Key('Directionality'),
      textDirection: textDirection,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                  ...IconAlignment.values.map((IconAlignment e) {
                    return ChoiceChip(
                      label: Text(e.toString()),
                      selected: iconAlignment == e,
                      onSelected: (bool isSelected) {
                        if (isSelected) {
                          setState(() {
                            iconAlignment = e;
                          });
                        }
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 30),
              OverflowBar(
                spacing: 10,
                overflowSpacing: 20,
                alignment: MainAxisAlignment.center,
                overflowAlignment: OverflowBarAlignment.center,
                children: <Widget>[
                  ...TextDirection.values.map((TextDirection e) {
                    return ChoiceChip(
                      label: Text(e.toString()),
                      selected: textDirection == e,
                      onSelected: (bool isSelected) {
                        if (isSelected) {
                          setState(() {
                            textDirection = e;
                          });
                        }
                      },
                    );
                  }),
                ],
              ),
              const Spacer(),
              OverflowBar(
                spacing: 10,
                overflowSpacing: 20,
                alignment: MainAxisAlignment.center,
                overflowAlignment: OverflowBarAlignment.center,
                children: <Widget>[
                  ElevatedButton.icon(
                    key: const Key('ElevatedButton.icon'),
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('ElevatedButton.icon'),
                    iconAlignment: iconAlignment,
                  ),
                  FilledButton.icon(
                    key: const Key('FilledButton.icon'),
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('FilledButton.icon'),
                    iconAlignment: iconAlignment,
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('FilledButton.tonalIcon'),
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('FilledButton.tonalIcon'),
                    iconAlignment: iconAlignment,
                  ),
                  OutlinedButton.icon(
                    key: const Key('OutlinedButton.icon'),
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('OutlinedButton.icon'),
                    iconAlignment: iconAlignment,
                  ),
                  TextButton.icon(
                    key: const Key('TextButton.icon'),
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('TextButton.icon'),
                    iconAlignment: iconAlignment,
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
