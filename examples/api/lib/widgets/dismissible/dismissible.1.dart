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

class DismissibleExample extends StatefulWidget {
  const DismissibleExample({super.key});

  @override
  State<DismissibleExample> createState() => _DismissibleExampleState();
}

class _DismissibleExampleState extends State<DismissibleExample> {
  late List<_Dismissible> dismissibleWidgets = <_Dismissible>[
    _Dismissible(
      index: 0,
      title: 'Default behavior',
      description: '`shouldDismiss: null`',
      onDismissed: _dismissItem,
    ),
    _Dismissible(
      index: 1,
      title: 'Default behavior',
      description: '`shouldDismiss: (_) => null`',
      shouldDismiss: (_) => null,
      onDismissed: _dismissItem,
    ),
    _Dismissible(
      index: 2,
      title: 'Never dismiss',
      description: '`shouldDismiss: (_) => false`',
      shouldDismiss: (_) => false,
      onDismissed: _dismissItem,
    ),
    _Dismissible(
      index: 3,
      title: 'Always dismiss',
      description: '`shouldDismiss: (_) => true`',
      shouldDismiss: (_) => true,
      onDismissed: _dismissItem,
    ),
    _Dismissible(
      index: 4,
      title: 'Only accept if threshold is reached (Disable flinging)',
      shouldDismiss: (AcceptDismissDetails details) =>
          details.reached ? null : false,
      onDismissed: _dismissItem,
    ),
    _Dismissible(
      index: 5,
      title: 'Accept dismiss before threshold',
      description: '`details.progress >= 0.2`',
      shouldDismiss: (AcceptDismissDetails details) {
        if (details.progress >= 0.2) {
          return true;
        }
        return null;
      },
      onDismissed: _dismissItem,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: dismissibleWidgets,
    );
  }

  void _dismissItem(_Dismissible dismissedItem) {
    setState(() {
      dismissibleWidgets = dismissibleWidgets
          .where((_Dismissible item) => item != dismissedItem)
          .toList();
    });
  }
}

/// A [Dismissible] widget used to demonstrates the behavior of the [shouldDismiss]
/// parameter.
///
/// Change background color to red when the item is reached based on
/// [DismissUpdateDetails.reached] value of [Dismissible.onUpdate] events.
class _Dismissible extends StatefulWidget {
  _Dismissible({
    required this.index,
    required this.title,
    required this.onDismissed,
    this.description,
    this.shouldDismiss,
  }) : super(key: ValueKey<int>(index));

  final int index;
  final String title;
  final String? description;
  final AcceptDismissCallback? shouldDismiss;
  final ValueChanged<_Dismissible> onDismissed;

  @override
  State<_Dismissible> createState() => _DismissibleState();
}

class _DismissibleState extends State<_Dismissible> {
  bool reached = false;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('dismissible-${widget.index}'),
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
      onDismissed: (_) => widget.onDismissed(widget),
    );
  }
}
