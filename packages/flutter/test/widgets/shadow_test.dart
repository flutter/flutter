// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Shadows on BoxDecoration', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.all(50.0),
            decoration: BoxDecoration(
              boxShadow: kElevationToShadow[9],
            ),
            height: 100.0,
            width: 100.0,
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesSkiaGoldFile('shadow.BoxDecoration.disabled.png'),
//      matchesGoldenFile('shadow.BoxDecoration.disabled.png'),
    );
    debugDisableShadows = false;
    tester.binding.reassembleApplication();
    await tester.pump();
    // TODO(ianh): [May no longer apply] use the skip argument instead once that doesn't hang, https://github.com/dart-lang/test/issues/830
    await expectLater(
      find.byType(Container),
      matchesSkiaGoldFile('shadow.BoxDecoration.enabled.png'),
//      matchesGoldenFile('shadow.BoxDecoration.enabled.png'),
    );
    debugDisableShadows = true;
  });

  testWidgets('Shadows on ShapeDecoration', (WidgetTester tester) async {
    debugDisableShadows = false;
    Widget build(int elevation) {
      return Center(
        child: RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.all(150.0),
            decoration: ShapeDecoration(
              shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              shadows: kElevationToShadow[elevation],
            ),
            height: 100.0,
            width: 100.0,
          ),
        ),
      );
    }
    for (int elevation in kElevationToShadow.keys) {
      await tester.pumpWidget(build(elevation));
      await expectLater(
        find.byType(Container),
        matchesSkiaGoldFile('shadow.ShapeDecoration.$elevation.png'),
//        matchesGoldenFile('shadow.ShapeDecoration.$elevation.png'),
      );
    }
    debugDisableShadows = true;
  },
//    skip: !Platform.isLinux
  ); // shadows render differently on different platforms

  testWidgets('Shadows with PhysicalLayer', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.all(150.0),
            color: Colors.yellow[200],
            child: PhysicalModel(
              elevation: 9.0,
              color: Colors.blue[900],
              child: const SizedBox(
                height: 100.0,
                width: 100.0,
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesSkiaGoldFile('shadow.PhysicalModel.disabled.0.png'),
//      matchesGoldenFile('shadow.PhysicalModel.disabled.png'),
    );
    debugDisableShadows = false;
    tester.binding.reassembleApplication();
    await tester.pump();
    // TODO(ianh): [May no longer apply] use the skip argument instead once that doesn't hang, https://github.com/dart-lang/test/issues/830
    await expectLater(
      find.byType(Container),
      matchesSkiaGoldFile('shadow.PhysicalModel.enabled.png'),
//      matchesGoldenFile('shadow.PhysicalModel.enabled.png'),
    );
    debugDisableShadows = true;
  });

  testWidgets('Shadows with PhysicalShape', (WidgetTester tester) async {
    debugDisableShadows = false;
    Widget build(double elevation) {
      return Center(
        child: RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.all(150.0),
            color: Colors.yellow[200],
            child: PhysicalShape(
              color: Colors.green[900],
              clipper: ShapeBorderClipper(shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(20.0))),
              elevation: elevation,
              child: const SizedBox(
                height: 100.0,
                width: 100.0,
              ),
            ),
          ),
        ),
      );
    }
    for (int elevation in kElevationToShadow.keys) {
      await tester.pumpWidget(build(elevation.toDouble()));
      await expectLater(
        find.byType(Container),
        matchesSkiaGoldFile('shadow.PhysicalModel.disabled.1.png'),
//        matchesGoldenFile('shadow.PhysicalModel.disabled.png'),
      );
    }
    debugDisableShadows = true;
  },
//    skip: !Platform.isLinux
  );
}