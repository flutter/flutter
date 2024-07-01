// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
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
  Offset _basePosition = Offset.zero;
  Offset _dragPosition = Offset.zero;
  late DragBoundary? boundaryInfo;
  @override
  Widget build(BuildContext context) {
    final Offset offset = _dragPosition - _basePosition;
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(100),
          child: DragRectBoundaryProvider(
            child: Stack(
              children: <Widget>[
                Container(
                  color: Colors.green,
                ),
                Positioned(
                  top: offset.dy,
                  left: offset.dx,
                  child: Builder(
                    builder: (BuildContext context) {
                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanStart: (DragStartDetails details) {
                          boundaryInfo = DragRectBoundaryProvider.of(context)?.getDragBoundary(context, details.globalPosition);
                          setState(() {
                            _basePosition = details.globalPosition - offset;
                            _dragPosition = details.globalPosition;
                          });
                        },
                        onPanUpdate: (DragUpdateDetails details) {
                          setState(() {
                            if (boundaryInfo == null) {
                              return;
                            }
                            if (boundaryInfo!.isWithinBoundary(details.globalPosition)) {
                              _dragPosition = details.globalPosition;
                            } else {
                              _dragPosition = boundaryInfo!.getNearestPositionWithinBoundary(details.globalPosition);
                            }
                          });
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          color: Colors.red,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
