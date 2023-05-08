// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [InteractiveViewer].

void main() => runApp(const InteractiveViewerExampleApp());

class InteractiveViewerExampleApp extends StatelessWidget {
  const InteractiveViewerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('InteractiveViewer Sample')),
        body: const InteractiveViewerExample(),
      ),
    );
  }
}

class InteractiveViewerExample extends StatelessWidget {
  const InteractiveViewerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(20.0),
        minScale: 0.1,
        maxScale: 1.6,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Colors.orange, Colors.red],
              stops: <double>[0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
