// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Dismissible] using [Dismissible.shouldDismiss].

void main() => runApp(const DismissibleExampleApp());

class DismissibleExampleApp extends StatefulWidget {
  const DismissibleExampleApp({super.key});

  @override
  State<DismissibleExampleApp> createState() => _DismissibleExampleAppState();
}

class _DismissibleExampleAppState extends State<DismissibleExampleApp> {
  UniqueKey _refreshKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => setState(() {
            _refreshKey = UniqueKey();
          }),
          child: const Icon(Icons.refresh),
        ),
        appBar: AppBar(title: const Text('Dismissible Sample - shouldDismiss')),
        body: DismissibleExample(key: _refreshKey),
      ),
    );
  }
}

class DismissibleExample extends StatelessWidget {
  const DismissibleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        const _Dismissible(
          title: 'Default behavior',
          description: '`shouldDismiss: null`',
        ),
        _Dismissible(
          title: 'Default behavior',
          description: '`shouldDismiss: (_) => null`',
          shouldDismiss: (_) => null,
        ),
        _Dismissible(
          title: 'Never dismiss',
          description: '`shouldDismiss: (_) => false`',
          shouldDismiss: (_) => false,
        ),
        _Dismissible(
          title: 'Always dismiss',
          description: '`shouldDismiss: (_) => true`',
          shouldDismiss: (_) => true,
        ),
        _Dismissible(
          title: 'Only accept if threshold is reached (Disable flinging)',
          shouldDismiss: (AcceptDismissDetails details) => details.reached ? null : false,
        ),
        _Dismissible(
          title: 'Accept dismiss before threshold',
          description: '`details.progress >= 0.1`',
          shouldDismiss: (AcceptDismissDetails details) {
            if (details.progress >= 0.1) {
              return true;
            }
            return null;
          },
        ),
      ],
    );
  }
}

/// A [Dismissible] widget used to demonstrates the behavior of the [shouldDismiss]
/// parameter.
///
/// Change background color to red when the item is reached based on
/// [DismissUpdateDetails.reached] value of [Dismissible.onUpdate] events.
class _Dismissible extends StatefulWidget {
  const _Dismissible({
    required this.title,
    this.description,
    this.shouldDismiss,
  });

  final String title;
  final String? description;
  final AcceptDismissCallback? shouldDismiss;

  @override
  State<_Dismissible> createState() => _DismissibleState();
}

class _DismissibleState extends State<_Dismissible> {
  bool reached = false;
  final UniqueKey _key = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: _key,
      background: ColoredBox(
        color: reached ? Colors.red : Colors.blue,
      ),
      onUpdate: (DismissUpdateDetails details) {
        setState(() {
          reached = details.reached;
        });
      },
      shouldDismiss: widget.shouldDismiss,
      child: ListTile(
        title: Text(widget.title),
        subtitle: widget.description != null ? Text(widget.description!) : null,
      ),
    );
  }
}
