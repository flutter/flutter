// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Flutter code sample for [DraggableScrollableSheet].

void main() => runApp(const DraggableScrollableSheetExampleApp());

class DraggableScrollableSheetExampleApp extends StatelessWidget {
  const DraggableScrollableSheetExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade100),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('DraggableScrollableSheet Sample')),
        body: const DraggableScrollableSheetExample(),
      ),
    );
  }
}

class DraggableScrollableSheetExample extends StatefulWidget {
  const DraggableScrollableSheetExample({super.key});

  @override
  State<DraggableScrollableSheetExample> createState() =>
      _DraggableScrollableSheetExampleState();
}

class _DraggableScrollableSheetExampleState
    extends State<DraggableScrollableSheetExample> {
  // This variable is used to restore the draggable sheet drag position
  // for the purpose of handling over-dragging beyond bounds when
  // the dragging mouse pointer re-enters the window on web and desktop platforms.
  double _dragPosition = 0.5;
  late double _sheetPosition = _dragPosition;
  final minChildSize = 0.25;
  final maxChildSize = 1.0;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewHeight = constraints.maxHeight;

        return DraggableScrollableSheet(
          initialChildSize: _sheetPosition,
          builder: (BuildContext context, ScrollController scrollController) {
            return ColoredBox(
              color: colorScheme.primary,
              child: Column(
                children: <Widget>[
                  if (_isOnDesktopAndWeb)
                    Grabber(
                      onVerticalDragUpdate: (DragUpdateDetails details) {
                        setState(() {
                          _dragPosition -= details.delta.dy / viewHeight;
                          _sheetPosition = _dragPosition.clamp(
                            minChildSize,
                            maxChildSize,
                          );
                        });
                      },
                    ),
                  Flexible(
                    child: ListView.builder(
                      controller: _isOnDesktopAndWeb ? null : scrollController,
                      itemCount: 25,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: Text(
                            'Item $index',
                            style: TextStyle(color: colorScheme.surface),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool get _isOnDesktopAndWeb =>
      kIsWeb ||
      switch (defaultTargetPlatform) {
        TargetPlatform.macOS ||
        TargetPlatform.linux ||
        TargetPlatform.windows => true,
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia => false,
      };
}

/// A draggable widget that accepts vertical drag gestures.
///
/// This is typically only used in desktop or web platforms.
class Grabber extends StatelessWidget {
  const Grabber({super.key, required this.onVerticalDragUpdate});

  final ValueChanged<DragUpdateDetails> onVerticalDragUpdate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onVerticalDragUpdate: onVerticalDragUpdate,
      child: Container(
        width: double.infinity,
        color: colorScheme.onSurface,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            width: 32.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
    );
  }
}
