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
  bool isEnabled = true;
  String message = "No button pressed yet";

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Enable Buttons"),
            Switch(
              value: isEnabled,
              onChanged: (value) {
                setState(() {
                  isEnabled = value;
                  message = value
                      ? "Buttons are enabled"
                      : "Buttons are disabled";
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 40),
        AbsorbPointer(
          absorbing: !isEnabled,
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    message = "Button 1 Pressed";
                  });
                },
                child: const Text("Button 1"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    message = "Button 2 Pressed";
                  });
                },
                child: const Text("Button 2"),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(
              isEnabled ? Icons.check_circle : Icons.block,
              color: isEnabled ? Colors.green : Colors.red,
            ),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
