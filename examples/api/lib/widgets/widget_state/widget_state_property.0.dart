// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [WidgetStateProperty].

void main() {
  runApp(const WidgetStatePropertyExampleApp());
}

class WidgetStatePropertyExampleApp extends StatelessWidget {
  const WidgetStatePropertyExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('WidgetStateProperty Sample')),
        body: const Center(
          child: WidgetStatePropertyExample(),
        ),
      ),
    );
  }
}

class WidgetStatePropertyExample extends StatelessWidget {
  const WidgetStatePropertyExample({super.key});

  Color _getButtonColor(Set<WidgetState> states) {
    const Set<WidgetState> interactiveStates = <WidgetState>{
      WidgetState.pressed,
      WidgetState.hovered,
      WidgetState.focused,
    };

    if (states.any(interactiveStates.contains)) {
      return Colors.blue;
    }

    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(_getButtonColor),
      ),
      onPressed: () {},
      child: const Text('TextButton'),
    );
  }
}
