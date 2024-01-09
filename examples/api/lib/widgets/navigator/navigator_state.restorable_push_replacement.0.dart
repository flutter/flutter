// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [NavigatorState.restorablePushReplacement].

void main() => runApp(const RestorablePushReplacementExampleApp());

class RestorablePushReplacementExampleApp extends StatelessWidget {
  const RestorablePushReplacementExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RestorablePushReplacementExample(),
    );
  }
}

class RestorablePushReplacementExample extends StatefulWidget {
  const RestorablePushReplacementExample({super.key});

  @override
  State<RestorablePushReplacementExample> createState() => _RestorablePushReplacementExampleState();
}

class _RestorablePushReplacementExampleState extends State<RestorablePushReplacementExample> {
  @pragma('vm:entry-point')
  static Route<void> _myRouteBuilder(BuildContext context, Object? arguments) {
    return MaterialPageRoute<void>(
      builder: (BuildContext context) => const RestorablePushReplacementExample(),
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
