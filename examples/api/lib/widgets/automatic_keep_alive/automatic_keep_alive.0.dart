// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [AutomaticKeepAlive].
// This example demonstrates how to use the `AutomaticKeepAlive` widget
// and the `AutomaticKeepAliveClientMixin` to keep the state of the list
// items alive even when they are scrolled out of view.

void main() {
  runApp(const AutomaticKeepAliveApp());
}

class AutomaticKeepAliveApp extends StatelessWidget {
  const AutomaticKeepAliveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AutomaticKeepAliveExample(),
    );
  }
}

class AutomaticKeepAliveExample extends StatefulWidget {
  const AutomaticKeepAliveExample({super.key});

  @override
  State<AutomaticKeepAliveExample> createState() => _AutomaticKeepAliveExampleState();
}

class _AutomaticKeepAliveExampleState extends State<AutomaticKeepAliveExample> with AutomaticKeepAliveClientMixin<AutomaticKeepAliveExample> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // This is important when using AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: AppBar(
        title: const Text('AutomaticKeepAlive Example'),
      ),
      body: ListView.builder(
        itemCount: 100,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Item $index'),
          );
        },
      ),
    );
  }
}