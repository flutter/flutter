// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [MaterialStateBorderSide].

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const Center(
          child: MyStatefulWidget(),
        ),
      ),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
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
      side: MaterialStateBorderSide.resolveWith((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return const BorderSide(color: Colors.red);
        }
        return null; // Defer to default value on the theme or widget.
      }),
    );
  }
}
