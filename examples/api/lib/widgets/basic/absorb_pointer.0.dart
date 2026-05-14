// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [AbsorbPointer].

void main() => runApp(const AbsorbPointerApp());

class AbsorbPointerApp extends StatelessWidget {
  const AbsorbPointerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('AbsorbPointer Sample')),
        body: const Center(child: AbsorbPointerExample()),
      ),
    );
  }
}

/// An example of using [AbsorbPointer] to disable a group of buttons.
class AbsorbPointerExample extends StatefulWidget {
  const AbsorbPointerExample({super.key});

  @override
  State<AbsorbPointerExample> createState() => _AbsorbPointerExampleState();
}

class _AbsorbPointerExampleState extends State<AbsorbPointerExample> {
  bool absorbing = false;
  String lastPressed = 'none';

  void setAbsorbing(bool newValue) {
    setState(() {
      absorbing = newValue;
    });
  }

  void setLastPressed(String label) {
    setState(() {
      lastPressed = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Text('Absorbing: $absorbing'),
        AbsorbPointer(
          absorbing: absorbing,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  setLastPressed('Button 1');
                },
                child: const Text('Button 1'),
              ),
              const SizedBox(width: 16.0),
              ElevatedButton(
                onPressed: () {
                  setLastPressed('Button 2');
                },
                child: const Text('Button 2'),
              ),
            ],
          ),
        ),
        Text('Last button pressed: $lastPressed'),
        FilledButton(
          onPressed: () {
            setAbsorbing(!absorbing);
          },
          child: Text(
            absorbing ? 'Set absorbing to false' : 'Set absorbing to true',
          ),
        ),
      ],
    );
  }
}
