// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [SnackBar] with Material 3 specifications.

void main() => runApp(const SnackBarExampleApp());

// A Material 3 [SnackBar] demonstrating an optional icon, in either floating
// or fixed format.
class SnackBarExampleApp extends StatelessWidget {
  const SnackBarExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('SnackBar Sample')),
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
  SnackBarBehavior? _snackBarBehavior = SnackBarBehavior.floating;
  bool _withIcon = true;
  bool _withAction = true;
  bool _multiLine = false;
  bool _longActionLabel = false;
  double _sliderValue = 0.25;

  Padding _padRow(List<Widget> children) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(children: children),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 50.0),
      child: Column(
        children: <Widget>[
          _padRow(<Widget>[
            Text('Snack Bar configuration', style: Theme.of(context).textTheme.bodyLarge),
          ]),
          _padRow(
            <Widget>[
              const Text('Fixed'),
              Radio<SnackBarBehavior>(
                value: SnackBarBehavior.fixed,
                groupValue: _snackBarBehavior,
                onChanged: (SnackBarBehavior? value) {
                  setState(() {
                    _snackBarBehavior = value;
                  });
                },
              ),
              const Text('Floating'),
              Radio<SnackBarBehavior>(
                value: SnackBarBehavior.floating,
                groupValue: _snackBarBehavior,
                onChanged: (SnackBarBehavior? value) {
                  setState(() {
                    _snackBarBehavior = value;
                  });
                },
              ),
            ],
          ),
          _padRow(
            <Widget>[
              const Text('Include Icon '),
              Switch(
                value: _withIcon,
                onChanged: (bool value) {
                  setState(() {
                    _withIcon = !_withIcon;
                  });
                },
              ),
            ],
          ),
          _padRow(
            <Widget>[
              const Text('Include Action '),
              Switch(
                value: _withAction,
                onChanged: (bool value) {
                  setState(() {
                    _withAction = !_withAction;
                  });
                },
              ),
              const SizedBox(width: 16.0),
              const Text('Long Action Label '),
              Switch(
                value: _longActionLabel,
                onChanged: !_withAction
                    ? null
                    : (bool value) {
                        setState(() {
                          _longActionLabel = !_longActionLabel;
                        });
                      },
              ),
            ],
          ),
          _padRow(
            <Widget>[
              const Text('Multi Line Text'),
              Switch(
                value: _multiLine,
                onChanged: _snackBarBehavior == SnackBarBehavior.fixed
                    ? null
                    : (bool value) {
                        setState(() {
                          _multiLine = !_multiLine;
                        });
                      },
              ),
            ],
          ),
          _padRow(<Widget>[
            const Text('Action new-line overflow threshold'),
            Slider(
              value: _sliderValue,
              divisions: 20,
              label: _sliderValue.toStringAsFixed(2),
              onChanged: _snackBarBehavior == SnackBarBehavior.fixed
                  ? null
                  : (double value) {
                      setState(() {
                        _sliderValue = value;
                      });
                    },
            ),
          ]),
          const SizedBox(height: 16.0),
          ElevatedButton(
            child: const Text('Show Snackbar'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(_snackBar());
            },
          ),
        ],
      ),
    );
  }

  SnackBar _snackBar() {
    final SnackBarAction? action = _withAction
        ? SnackBarAction(
            label: _longActionLabel ? 'Long Action Text' : 'Action',
            onPressed: () {
              // Code to execute.
            },
          )
        : null;
    final double? width = _snackBarBehavior == SnackBarBehavior.floating && _multiLine ? 400.0 : null;
    final String label =
        _multiLine ? 'A Snack Bar with quite a lot of text which spans across multiple lines' : 'Single Line Snack Bar';
    return SnackBar(
      content: Text(label),
      showCloseIcon: _withIcon,
      width: width,
      behavior: _snackBarBehavior,
      action: action,
      duration: const Duration(seconds: 3),
      actionOverflowThreshold: _sliderValue,
    );
  }
}
