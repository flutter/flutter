// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [MediaQueryData.systemGestureInsets].

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: MyStatefulWidget(),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  double _currentValue = 0.2;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets systemGestureInsets =
        MediaQuery.of(context).systemGestureInsets;
    return Scaffold(
      appBar:
          AppBar(title: const Text('Pad Slider to avoid systemGestureInsets')),
      body: Padding(
        padding: EdgeInsets.only(
          // only left and right padding are needed here
          left: systemGestureInsets.left,
          right: systemGestureInsets.right,
        ),
        child: Slider(
          value: _currentValue,
          onChanged: (double newValue) {
            setState(() {
              _currentValue = newValue;
            });
          },
        ),
      ),
    );
  }
}
