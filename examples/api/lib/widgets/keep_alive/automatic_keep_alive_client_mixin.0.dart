// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [AutomaticKeepAliveClientMixin].
///
/// This example demonstrates how to use the [AutomaticKeepAliveClientMixin] to
/// preserve the state of individual list items in a `ListView` when they are
/// scrolled out of view. Each item has a counter that maintains its state.
void main() {
  runApp(const AutomaticKeepAliveClientMixinExampleApp());
}

class AutomaticKeepAliveClientMixinExampleApp extends StatefulWidget {
  const AutomaticKeepAliveClientMixinExampleApp({super.key});

  @override
  State<AutomaticKeepAliveClientMixinExampleApp> createState() =>
      _AutomaticKeepAliveClientMixinExampleAppState();
}

class _AutomaticKeepAliveClientMixinExampleAppState
    extends State<AutomaticKeepAliveClientMixinExampleApp> {
  bool _keepAlive = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AutomaticKeepAliveClientMixin Example'),
          actions: <Widget>[
            Row(
              children: <Widget>[
                const Text('Keep Alive'),
                Switch(
                  value: _keepAlive,
                  onChanged: (bool value) {
                    setState(() {
                      _keepAlive = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) {
            return _KeepAliveItem(index: index, keepAlive: _keepAlive);
          },
        ),
      ),
    );
  }
}

class _KeepAliveItem extends StatefulWidget {
  const _KeepAliveItem({required this.index, required this.keepAlive});

  final int index;
  final bool keepAlive;

  @override
  State<_KeepAliveItem> createState() => _KeepAliveItemState();
}

class _KeepAliveItemState extends State<_KeepAliveItem>
    with AutomaticKeepAliveClientMixin<_KeepAliveItem> {
  int _counter = 0;

  @override
  void didUpdateWidget(_KeepAliveItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keepAlive != widget.keepAlive) {
      updateKeepAlive();
    }
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListTile(
      title: Text('Item ${widget.index}: $_counter'),
      trailing: IconButton(
        icon: const Icon(Icons.add),
        onPressed: () {
          setState(() {
            _counter++;
          });
        },
      ),
    );
  }
}
