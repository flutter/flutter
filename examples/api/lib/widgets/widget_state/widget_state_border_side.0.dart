// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [WidgetStateBorderSide].

void main() {
  runApp(const WidgetStateBorderSideExampleApp());
}

class WidgetStateBorderSideExampleApp extends StatelessWidget {
  const WidgetStateBorderSideExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('WidgetStateBorderSide Sample')),
        body: const Center(
          child: WidgetStateBorderSideExample(),
        ),
      ),
    );
  }
}

class WidgetStateBorderSideExample extends StatefulWidget {
  const WidgetStateBorderSideExample({super.key});

  @override
  State<WidgetStateBorderSideExample> createState() =>
      _WidgetStateBorderSideExampleState();
}

class _WidgetStateBorderSideExampleState
    extends State<WidgetStateBorderSideExample> {
  bool isSelected = true;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: const Text('Select chip'),
      selected: isSelected,
      onSelected: (bool value) {
        setState(() {
          isSelected = value;
        });
      },
      side: const WidgetStateBorderSide.fromMap(
        <WidgetStatesConstraint, BorderSide?>{
          WidgetState.selected: BorderSide(color: Colors.red),
          WidgetState.any: null, // Defer to default value of the theme or widget.
        },
      ),
    );
  }
}
