// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [SnackBar] with Material 3 specifications.

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

// A Material 3 [SnackBar] demonstrating an optional icon, in either floating
// or fixed format.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const Center(
          child: SnackBarExample(),
        ),
      ),
    );
  }
}

class SnackBarExample extends StatefulWidget {
  const SnackBarExample({super.key});

  @override
  State<SnackBarExample> createState() => _SnackBarExampleState();
}

class _SnackBarExampleState extends State<SnackBarExample> {
  SnackBarBehavior? _snackBarBehavior = SnackBarBehavior.fixed;

  @override
  Widget build(BuildContext context) {
      final String label = _snackBarBehavior == SnackBarBehavior.fixed
      ? 'Fixed snack bar'
      : 'Floating snack bar with custom width';
    return Column(
      children: <Widget>[
        ListTile(
          title: const Text('Fixed Snack Bar'),
          leading: Radio<SnackBarBehavior>(
            value: SnackBarBehavior.fixed,
            groupValue: _snackBarBehavior,
            onChanged: (SnackBarBehavior? value) {
              setState(() {
                _snackBarBehavior = value;
              });
            },
          ),
        ),
        ListTile(
          title: const Text('Floating Snack Bar'),
          leading: Radio<SnackBarBehavior>(
            value: SnackBarBehavior.floating,
            groupValue: _snackBarBehavior,
            onChanged: (SnackBarBehavior? value) {
              setState(() {
                _snackBarBehavior = value;
              });
            },
          ),
        ),
        ElevatedButton(
          child: const Text('Show Snackbar'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(label),
                icon: const SnackBarIcon(),
                width: _snackBarBehavior == SnackBarBehavior.floating
                    ? 400.0 // Width of the SnackBar.
                    : null,
                behavior: _snackBarBehavior,
                action: SnackBarAction(
                  label: 'Action',
                  onPressed: () {
                    // Code to execute.
                  },
                ),
              ),
            );
          },
        )
      ],
    );
  }
}
