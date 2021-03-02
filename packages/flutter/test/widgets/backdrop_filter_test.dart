// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets("BackdropFilter's cull rect does not shrink", (WidgetTester tester) async {
    tester.binding.addTime(const Duration(seconds: 15));
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
}
