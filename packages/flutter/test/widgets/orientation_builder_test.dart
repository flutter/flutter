// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrientationBuilder', () {
    testWidgets('OrientationBuilder determines orientation from constraints', (WidgetTester tester) async {
      Orientation? orientation;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(800.0, 600.0),
            // Device orientation is landscape
          ),
          child: Center(
            child: SizedBox(
              // Widget constraints are portrait (100 wide, 200 tall)
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

      // OrientationBuilder should report portrait because width (100) < height (200)
      expect(orientation, Orientation.portrait);
    });

    testWidgets('OrientationBuilder reports landscape when width > height', (WidgetTester tester) async {
      Orientation? orientation;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(600.0, 800.0),
          ),
          child: Center(
            child: SizedBox(
              // Widget constraints are landscape (200 wide, 100 tall)
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

      // OrientationBuilder should report landscape because width (200) > height (100)
      expect(orientation, Orientation.landscape);
    });

    testWidgets('OrientationBuilder rebuilds when constraints change', (WidgetTester tester) async {
      Orientation? orientation;

      Widget buildTestWidget({required double width, required double height}) {
        return MediaQuery(
          data: const MediaQueryData(
            size: Size(800.0, 600.0),
          ),
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

      // First, test portrait orientation
      await tester.pumpWidget(buildTestWidget(width: 100.0, height: 200.0));
      expect(orientation, Orientation.portrait);

      // Then, test landscape orientation
      await tester.pumpWidget(buildTestWidget(width: 200.0, height: 100.0));
      expect(orientation, Orientation.landscape);
    });
  });
}
