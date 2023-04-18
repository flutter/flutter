// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Navigator.restorablePush].

void main() => runApp(const RestorablePushExampleApp());

class RestorablePushExampleApp extends StatelessWidget {
  const RestorablePushExampleApp({super.key});

  @override
  Widget build(final BuildContext context) {
    return const MaterialApp(
      home: RestorablePushExample(),
    );
  }
}

class RestorablePushExample extends StatefulWidget {
  const RestorablePushExample({super.key});

  @override
  State<RestorablePushExample> createState() => _RestorablePushExampleState();
}

class _RestorablePushExampleState extends State<RestorablePushExample> {
  @pragma('vm:entry-point')
  static Route<void> _myRouteBuilder(final BuildContext context, final Object? arguments) {
    return MaterialPageRoute<void>(
      builder: (final BuildContext context) => const RestorablePushExample(),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Code'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.restorablePush(context, _myRouteBuilder),
        tooltip: 'Increment Counter',
        child: const Icon(Icons.add),
      ),
    );
  }
}
