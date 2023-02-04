// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example demonstrates disabling the browser's context menu
// and displaying the context menu of a TextField widget instead.

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show BrowserContextMenu;

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _controller = TextEditingController(
    text: 'Select a word and right click to see the context menu.',
  );

  void disableBrowserContextMenu() {
    if (kIsWeb && BrowserContextMenu.enabled) {
      unawaited(BrowserContextMenu.disableContextMenu());
    }
  }

  void enableBrowserContextMenu() {
    if (kIsWeb && !BrowserContextMenu.enabled) {
      unawaited(BrowserContextMenu.enableContextMenu());
    }
  }

  @override
  void initState() {
    super.initState();
    disableBrowserContextMenu();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Context Menu on the Web'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              // By default a TextField widget
              // already has its own context menu builder.
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    enableBrowserContextMenu();
    _controller.dispose();
    super.dispose();
  }
}
