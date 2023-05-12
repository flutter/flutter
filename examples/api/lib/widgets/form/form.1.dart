// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// This sample demonstrates showing a confirmation dialog when the user
/// attempts to navigate away from a page with unsaved [Form] data.

void main() => runApp(_MyApp());

class _MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  final TextEditingController _controller = TextEditingController();
  String _savedValue = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  Future<void> _showDialog() async {
    final bool? shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Any unsaved changes will be lost!'),
          actions: <Widget>[
            TextButton(
              child: const Text('Yes, discard my changes'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
            TextButton(
              child: const Text('No, continue editing'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
          ],
        );
      },
    );

    if (shouldDiscard ?? false) {
      SystemNavigator.pop();
    }
  }

  void _save(String? value) {
    setState(() {
      _savedValue = value ?? '';
    });
  }

  bool get _isDirty => _savedValue != _controller.text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation Dialog Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('If the field below is unsaved, a confirmation dialog will be shown on back.'),
            const SizedBox(height: 20.0),
            Form(
              popEnabled: !_isDirty,
              onPop: () {
                if (!_isDirty) {
                  return;
                }
                _showDialog();
              },
              autovalidateMode: AutovalidateMode.always,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextFormField(
                    controller: _controller,
                    onFieldSubmitted: (String? value) {
                      _save(value);
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      _save(_controller.text);
                    },
                    child: Row(
                      children: <Widget>[
                        const Text('Save'),
                        if (_controller.text.isNotEmpty)
                          Icon(
                            _isDirty ? Icons.warning : Icons.check,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                if (_isDirty) {
                  _showDialog();
                  return;
                }
                SystemNavigator.pop();
              },
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
