// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const kCustomYellow = Color(0xFFFFF59D);
  const kCustomBlue = Color(0xFF0D47A1);
  const kCustomGreen = Color(0xFF1B5E20);

  // Shadow definitions derived from the Material Design 2 palette.
  const kKeyUmbraOpacity = Color(0x33000000);
  const kKeyPenumbraOpacity = Color(0x24000000);
  const kAmbientShadowOpacity = Color(0x1F000000);
  const elevationToShadow = <int, List<BoxShadow>>{
    0: <BoxShadow>[],
    1: <BoxShadow>[
      BoxShadow(
        offset: Offset(0.0, 2.0),
        blurRadius: 1.0,
        spreadRadius: -1.0,
        color: kKeyUmbraOpacity,
      ),
      BoxShadow(offset: Offset(0.0, 1.0), blurRadius: 1.0, color: kKeyPenumbraOpacity),
      BoxShadow(offset: Offset(0.0, 1.0), blurRadius: 3.0, color: kAmbientShadowOpacity),
    ],
    2: <BoxShadow>[
      BoxShadow(
        offset: Offset(0.0, 3.0),
        blurRadius: 1.0,
        spreadRadius: -2.0,
        color: kKeyUmbraOpacity,
      ),
      BoxShadow(offset: Offset(0.0, 2.0), blurRadius: 2.0, color: kKeyPenumbraOpacity),
      BoxShadow(offset: Offset(0.0, 1.0), blurRadius: 5.0, color: kAmbientShadowOpacity),
    ],
    3: <BoxShadow>[
      BoxShadow(
        offset: Offset(0.0, 3.0),
        blurRadius: 3.0,
        spreadRadius: -2.0,
        color: kKeyUmbraOpacity,
      ),
      BoxShadow(offset: Offset(0.0, 3.0), blurRadius: 4.0, color: kKeyPenumbraOpacity),
      BoxShadow(offset: Offset(0.0, 1.0), blurRadius: 8.0, color: kAmbientShadowOpacity),
    ],
    4: <BoxShadow>[
      BoxShadow(
        offset: Offset(0.0, 2.0),
        blurRadius: 4.0,
        spreadRadius: -1.0,
        color: kKeyUmbraOpacity,
      ),
      BoxShadow(offset: Offset(0.0, 4.0), blurRadius: 5.0, color: kKeyPenumbraOpacity),
      BoxShadow(offset: Offset(0.0, 1.0), blurRadius: 10.0, color: kAmbientShadowOpacity),
    ],
    6: <BoxShadow>[
      BoxShadow(
        offset: Offset(0.0, 3.0),
        blurRadius: 5.0,
        spreadRadius: -1.0,
        color: kKeyUmbraOpacity,
      ),
      BoxShadow(offset: Offset(0.0, 6.0), blurRadius: 10.0, color: kKeyPenumbraOpacity),
      BoxShadow(offset: Offset(0.0, 1.0), blurRadius: 18.0, color: kAmbientShadowOpacity),
    ],
    8: <BoxShadow>[
      BoxShadow(
        offset: Offset(0.0, 5.0),
        blurRadius: 5.0,
        spreadRadius: -3.0,
        color: kKeyUmbraOpacity,
      ),
      BoxShadow(
        offset: Offset(0.0, 8.0),
        blurRadius: 10.0,
        spreadRadius: 1.0,
        color: kKeyPenumbraOpacity,
      ),
      BoxShadow(
        offset: Offset(0.0, 3.0),
        blurRadius: 14.0,
        spreadRadius: 2.0,
        color: kAmbientShadowOpacity,
      ),
    ],
    9: <BoxShadow>[
      BoxShadow(
        offset: Offset(0.0, 5.0),
        blurRadius: 6.0,
        spreadRadius: -3.0,
        color: kKeyUmbraOpacity,
      ),
      BoxShadow(
        offset: Offset(0.0, 9.0),
        blurRadius: 12.0,
        spreadRadius: 1.0,
        color: kKeyPenumbraOpacity,
      ),
      BoxShadow(
        offset: Offset(0.0, 3.0),
        blurRadius: 16.0,
        spreadRadius: 2.0,
        color: kAmbientShadowOpacity,
      ),
    ],
    12: <BoxShadow>[
      BoxShadow(
        offset: Offset(0.0, 7.0),
        blurRadius: 8.0,
        spreadRadius: -4.0,
        color: kKeyUmbraOpacity,
      ),
      BoxShadow(
        offset: Offset(0.0, 12.0),
        blurRadius: 17.0,
        spreadRadius: 2.0,
        color: kKeyPenumbraOpacity,
      ),
      BoxShadow(
        offset: Offset(0.0, 5.0),
        blurRadius: 22.0,
        spreadRadius: 4.0,
        color: kAmbientShadowOpacity,
      ),
    ],
    16: <BoxShadow>[
      BoxShadow(
        offset: Offset(0.0, 8.0),
        blurRadius: 10.0,
        spreadRadius: -5.0,
        color: kKeyUmbraOpacity,
      ),
      BoxShadow(
        offset: Offset(0.0, 16.0),
        blurRadius: 24.0,
        spreadRadius: 2.0,
        color: kKeyPenumbraOpacity,
      ),
      BoxShadow(
        offset: Offset(0.0, 6.0),
        blurRadius: 30.0,
        spreadRadius: 5.0,
        color: kAmbientShadowOpacity,
      ),
    ],
    24: <BoxShadow>[
      BoxShadow(
        offset: Offset(0.0, 11.0),
        blurRadius: 15.0,
        spreadRadius: -7.0,
        color: kKeyUmbraOpacity,
      ),
      BoxShadow(
        offset: Offset(0.0, 24.0),
        blurRadius: 38.0,
        spreadRadius: 3.0,
        color: kKeyPenumbraOpacity,
      ),
      BoxShadow(
        offset: Offset(0.0, 9.0),
        blurRadius: 46.0,
        spreadRadius: 8.0,
        color: kAmbientShadowOpacity,
      ),
    ],
  };

  tearDown(() {
    debugDisableShadows = true;
  });

  testWidgets('Shadows on BoxDecoration', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.all(50.0),
            decoration: BoxDecoration(boxShadow: elevationToShadow[9]),
            height: 100.0,
            width: 100.0,
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('shadow.BoxDecoration.disabled.png'),
    );
    debugDisableShadows = false;
    tester.binding.reassembleApplication();
    await tester.pump();
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('shadow.BoxDecoration.enabled.png'),
    );
    debugDisableShadows = true;
  });

  group('Shadows on ShapeDecoration', () {
    Widget build(int elevation) {
      return Center(
        child: RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.all(150.0),
            decoration: ShapeDecoration(
              shape: const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20.0)),
              ),
              shadows: elevationToShadow[elevation],
            ),
            height: 100.0,
            width: 100.0,
          ),
        ),
      );
    }

    for (final int elevation in elevationToShadow.keys) {
      testWidgets('elevation $elevation', (WidgetTester tester) async {
        debugDisableShadows = false;
        await tester.pumpWidget(build(elevation));
        await expectLater(
          find.byType(Container),
          matchesGoldenFile('shadow.ShapeDecoration.$elevation.png'),
        );
        debugDisableShadows = true;
      });
    }
  });

  testWidgets('Shadows with PhysicalLayer', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.all(150.0),
            color: kCustomYellow,
            child: const PhysicalModel(
              elevation: 9.0,
              color: kCustomBlue,
              child: SizedBox(height: 100.0, width: 100.0),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('shadow.PhysicalModel.disabled.png'),
    );
    debugDisableShadows = false;
    tester.binding.reassembleApplication();
    await tester.pump();
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('shadow.PhysicalModel.enabled.png'),
    );
    debugDisableShadows = true;
  });

  group('Shadows with PhysicalShape', () {
    Widget build(double elevation) {
      return Center(
        child: RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.all(150.0),
            color: kCustomYellow,
            child: PhysicalShape(
              color: kCustomGreen,
              clipper: const ShapeBorderClipper(
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              elevation: elevation,
              child: const SizedBox(height: 100.0, width: 100.0),
            ),
          ),
        ),
      );
    }

    for (final int elevation in elevationToShadow.keys) {
      testWidgets('elevation $elevation', (WidgetTester tester) async {
        debugDisableShadows = false;
        await tester.pumpWidget(build(elevation.toDouble()));
        await expectLater(
          find.byType(Container),
          matchesGoldenFile('shadow.PhysicalShape.$elevation.png'),
        );
        debugDisableShadows = true;
      });
    }
  });
}
