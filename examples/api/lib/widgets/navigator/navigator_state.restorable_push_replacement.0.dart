// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [NavigatorState.restorablePushReplacement].

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
  static Route<void> _myRouteBuilder(BuildContext context, Object? arguments) {
    return MaterialPageRoute<void>(
      builder: (BuildContext context) => const MyStatefulWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Code'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).restorablePushReplacement(
          _myRouteBuilder,
        ),
        tooltip: 'Increment Counter',
        child: const Icon(Icons.add),
      ),
    );
  }
}
