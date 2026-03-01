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

class AbsorbPointerExample extends StatefulWidget {
  const AbsorbPointerExample({super.key});

  @override
  State<AbsorbPointerExample> createState() => _AbsorbPointerExampleState();
}

class _AbsorbPointerExampleState extends State<AbsorbPointerExample> {
  bool isAbsorbing = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 40,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Enable Buttons"),
            Switch(
              value: isAbsorbing,
              onChanged: (value) {
                setState(() {
                  isAbsorbing = value;
                });
              },
            ),
          ],
        ),
        AbsorbPointer(
          absorbing: !isAbsorbing,
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Button 1 Pressed")),
                  );
                },
                child: const Text("Button 1"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Button 2 Pressed")),
                  );
                },
                child: const Text("Button 2"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
