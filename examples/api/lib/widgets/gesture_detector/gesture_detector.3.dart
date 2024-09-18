// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  runApp(const DragBoundaryExampleApp());
}

class DragBoundaryExampleApp extends StatefulWidget {
  const DragBoundaryExampleApp({super.key});

  @override
  State<StatefulWidget> createState() => DragBoundaryExampleAppState();
}

class DragBoundaryExampleAppState extends State<DragBoundaryExampleApp> {
  Offset _currentPosition = Offset.zero;
  final Size _boxSize = const Size(100, 100);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(100),
          child: RectBoundaryProvider(
            child: Builder(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Container(
                      color: Colors.green,
                    ),
                    Positioned(
                      top: _currentPosition.dy,
                      left: _currentPosition.dx,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanUpdate: (DragUpdateDetails details) {
                          final RenderBox containerBox = context.findRenderObject()! as RenderBox;
                          _currentPosition += details.delta;
                          final Rect? withinBoundary = RectBoundaryProvider.maybeOf(context)?.nearestShapeWithinBoundary(
                            containerBox.localToGlobal(_currentPosition) & _boxSize,
                          );
                          if (withinBoundary != null) {
                            _currentPosition = containerBox.globalToLocal(withinBoundary.topLeft);
                          }
                          setState(() {});
                        },
                        child: Container(
                          width: _boxSize.width,
                          height: _boxSize.height,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
