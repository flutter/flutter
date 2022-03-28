// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for ElevatedButton

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: const Color(0xff6750a4), useMaterial3: true),
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const MyStatefulWidget(),
      ),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    final ButtonStyle filledStyle = ElevatedButton.styleFrom(
      useMaterial3Colors: true,
      elevation: 0,
      primary: Theme.of(context).colorScheme.onPrimary,
      surface: Theme.of(context).colorScheme.primary,
    );
    final ButtonStyle filledTonalStyle = ElevatedButton.styleFrom(
      useMaterial3Colors: true,
      elevation: 0,
      primary: Theme.of(context).colorScheme.onSecondaryContainer,
      surface: Theme.of(context).colorScheme.secondaryContainer,
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ElevatedButton(
            style: filledStyle,
            onPressed: () {},
            child: const Text('Filled enabled'),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: filledStyle,
            onPressed: null,
            child: const Text('Filled disabled'),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: filledTonalStyle,
            onPressed: () {},
            child: const Text('Filled Tonal enabled'),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: filledTonalStyle,
            onPressed: null,
            child: const Text('Filled Tonal disabled'),
          ),
        ],
      ),
    );
  }
}
