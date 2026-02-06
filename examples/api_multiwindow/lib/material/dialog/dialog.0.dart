// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_internal_member

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

/// Flutter code sample for [Dialog].

class _RegularWindowControllerDelegate extends RegularWindowControllerDelegate {
  @override
  void onWindowDestroyed() {
    exit(0);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final RegularWindowController controller = RegularWindowController(
    preferredSize: Size(800, 600),
    delegate: _RegularWindowControllerDelegate(),
  );
  runWidget(
    RegularWindow(controller: controller, child: const DialogExampleApp()),
  );
}

class DialogExampleApp extends StatelessWidget {
  const DialogExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Dialog Sample')),
        body: const Center(child: DialogExample()),
      ),
    );
  }
}

class DialogExample extends StatelessWidget {
  const DialogExample({super.key});

  void _handleShowDialog(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('This is a typical dialog.'),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleShowFullscreenDialog(BuildContext context) {
    showDialog<String>(
      context: context,
      fullscreenDialog: true,
      builder: (BuildContext context) => Dialog.fullscreen(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('This is a fullscreen dialog.'),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TextButton(
          onPressed: () => _handleShowDialog(context),
          child: const Text('Show Dialog'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => _handleShowFullscreenDialog(context),
          child: const Text('Show Fullscreen Dialog'),
        ),
      ],
    );
  }
}
