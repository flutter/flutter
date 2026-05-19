// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrientationBuilder', () {
    testWidgets('OrientationBuilder determines orientation from constraints', (
      WidgetTester tester,
    ) async {
      Orientation? orientation;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(800.0, 600.0),
            // Device orientation is landscape.
          ),
          child: Center(
            child: SizedBox(
              // Widget constraints are portrait (100 wide, 200 tall).
              width: 100.0,
              height: 200.0,
              child: OrientationBuilder(
                builder: (BuildContext context, Orientation o) {
                  orientation = o;
                  return Container();
                },
              ),
            ),
          ),
        ),
      );

      // OrientationBuilder should report portrait because width (100) < height (200).
      expect(orientation, Orientation.portrait);
    });

    testWidgets('OrientationBuilder reports landscape when width > height', (
      WidgetTester tester,
    ) async {
      Orientation? orientation;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(600.0, 800.0)),
          child: Center(
            child: SizedBox(
              // Widget constraints are landscape (200 wide, 100 tall).
              width: 200.0,
              height: 100.0,
              child: OrientationBuilder(
                builder: (BuildContext context, Orientation o) {
                  orientation = o;
                  return Container();
                },
              ),
            ),
          ),
        ),
      );

      // OrientationBuilder should report landscape because width (200) > height (100).
      expect(orientation, Orientation.landscape);
    });

    testWidgets('OrientationBuilder rebuilds when constraints change', (WidgetTester tester) async {
      Orientation? orientation;

      Widget buildTestWidget({required double width, required double height}) {
        return MediaQuery(
          data: const MediaQueryData(size: Size(800.0, 600.0)),
          child: Center(
            child: SizedBox(
              width: width,
              height: height,
              child: OrientationBuilder(
                builder: (BuildContext context, Orientation o) {
                  orientation = o;
                  return Container();
                },
              ),
            ),
          ),
        );
      }

      // First, test portrait orientation.
      await tester.pumpWidget(buildTestWidget(width: 100.0, height: 200.0));
      expect(orientation, Orientation.portrait);

      // Then, test landscape orientation.
      await tester.pumpWidget(buildTestWidget(width: 200.0, height: 100.0));
      expect(orientation, Orientation.landscape);
    });
  });

  group('DeviceOrientationBuilder', () {
    testWidgets('DeviceOrientationBuilder uses MediaQuery orientation', (
      WidgetTester tester,
    ) async {
      Orientation? deviceOrientation;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(800.0, 600.0),
            // Device is in landscape orientation.
          ),
          child: Center(
            child: SizedBox(
              // Widget constraints are portrait, but device is landscape
              width: 100.0,
              height: 200.0,
              child: DeviceOrientationBuilder(
                builder: (BuildContext context, Orientation o) {
                  deviceOrientation = o;
                  return Container();
                },
              ),
            ),
          ),
        ),
      );

      // DeviceOrientationBuilder should report landscape based on MediaQuery
      // even though the widget's constraints are portrait.
      expect(deviceOrientation, Orientation.landscape);
    });

    testWidgets('DeviceOrientationBuilder reports portrait when device is portrait', (
      WidgetTester tester,
    ) async {
      Orientation? deviceOrientation;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(600.0, 800.0),
            // Device is in portrait orientation.
          ),
          child: Center(
            child: SizedBox(
              // Widget constraints are landscape, but device is portrait.
              width: 200.0,
              height: 100.0,
              child: DeviceOrientationBuilder(
                builder: (BuildContext context, Orientation o) {
                  deviceOrientation = o;
                  return Container();
                },
              ),
            ),
          ),
        ),
      );

      // DeviceOrientationBuilder should report portrait based on MediaQuery
      // even though the widget's constraints are landscape.
      expect(deviceOrientation, Orientation.portrait);
    });

    testWidgets('DeviceOrientationBuilder rebuilds when MediaQuery orientation changes', (
      WidgetTester tester,
    ) async {
      Orientation? deviceOrientation;

      Widget buildTestWidget({required Size size}) {
        return MediaQuery(
          data: MediaQueryData(size: size),
          child: DeviceOrientationBuilder(
            builder: (BuildContext context, Orientation o) {
              deviceOrientation = o;
              return Container();
            },
          ),
        );
      }

      // First, test portrait orientation.
      await tester.pumpWidget(buildTestWidget(size: const Size(600.0, 800.0)));
      expect(deviceOrientation, Orientation.portrait);

      // Then, test landscape orientation.
      await tester.pumpWidget(buildTestWidget(size: const Size(800.0, 600.0)));
      expect(deviceOrientation, Orientation.landscape);
    });

    testWidgets('DeviceOrientationBuilder differs from OrientationBuilder', (
      WidgetTester tester,
    ) async {
      Orientation? layoutOrientation;
      Orientation? deviceOrientation;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(800.0, 600.0),
            // Device orientation is landscape.
          ),
          child: Center(
            child: SizedBox(
              // Widget constraints are portrait.
              width: 100.0,
              height: 200.0,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: OrientationBuilder(
                      builder: (BuildContext context, Orientation o) {
                        layoutOrientation = o;
                        return Container();
                      },
                    ),
                  ),
                  Expanded(
                    child: DeviceOrientationBuilder(
                      builder: (BuildContext context, Orientation o) {
                        deviceOrientation = o;
                        return Container();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // This demonstrates the key difference:
      // - OrientationBuilder reports based on widget constraints (portrait)
      // - DeviceOrientationBuilder reports based on device orientation (landscape)
      expect(
        layoutOrientation,
        Orientation.portrait,
        reason: 'OrientationBuilder should use widget constraints',
      );
      expect(
        deviceOrientation,
        Orientation.landscape,
        reason: 'DeviceOrientationBuilder should use MediaQuery orientation',
      );
      expect(
        layoutOrientation,
        isNot(equals(deviceOrientation)),
        reason: 'The two builders can report different orientations',
      );
    });
  });
}
