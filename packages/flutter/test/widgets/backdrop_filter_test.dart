// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("BackdropFilter's cull rect does not shrink", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Text('0 0 ' * 10000),
              Center(
                // ClipRect needed for filtering the 200x200 area instead of the
                // whole screen.
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 5.0,
                      sigmaY: 5.0,
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      width: 200.0,
                      height: 200.0,
                      child: const Text('Hello World'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('backdrop_filter_test.cull_rect.png'),
    );
  });

  testWidgets('BackdropFilter blendMode on saveLayer', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Opacity(
            opacity: 0.9,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Text('0 0 ' * 10000),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  // ClipRect needed for filtering the 200x200 area instead of the
                  // whole screen.
                  children: <Widget>[
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 5.0,
                          sigmaY: 5.0,
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          width: 200.0,
                          height: 200.0,
                          color: Colors.yellow.withAlpha(0x7),
                        ),
                      ),
                    ),
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 5.0,
                          sigmaY: 5.0,
                        ),
                        blendMode: BlendMode.src,
                        child: Container(
                          alignment: Alignment.center,
                          width: 200.0,
                          height: 200.0,
                          color: Colors.yellow.withAlpha(0x7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('backdrop_filter_test.saveLayer.blendMode.png'),
    );
  });
}
