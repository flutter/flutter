// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:flutter_api_samples/painting/star_border/star_border.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Finder getStartBorderFinder(StarBorder shape) {
    return find.byWidgetPredicate(
      (Widget widget) => widget is example.ExampleBorder && widget.border == shape,
    );
  }

  testWidgets('Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.StarBorderApp(),
    );

    expect(find.widgetWithText(AppBar, 'StarBorder Example'), findsOne);
    expect(find.text('Star'), findsOne);
    expect(find.text('Polygon'), findsOne);

    expect(
      getStartBorderFinder(const StarBorder(
        side: BorderSide(),
      )),
      findsOne,
    );
    expect(
      find.text('''
Container(
  decoration: ShapeDecoration(
    shape: StarBorder(
      points: 5.00,
      rotation: 0.00,
      innerRadiusRatio: 0.40,
      pointRounding: 0.00,
      valleyRounding: 0.00,
      squash: 0.00,
    ),
  ),
);'''
      ),
      findsOne,
    );
    expect(
      getStartBorderFinder(const StarBorder.polygon(
        side: BorderSide(),
      )),
      findsOne,
    );
    expect(
      find.text('''
Container(
  decoration: ShapeDecoration(
    shape: StarBorder.polygon(
      sides: 5.00,
      rotation: 0.00,
      cornerRounding: 0.00,
      squash: 0.00,
    ),
  ),
);'''
      ),
      findsOne,
    );

    // Put all the sliders to the middle.
    for (int i = 0; i < 6; i++) {
      await tester.tap(find.byType(Slider).at(i));
      await tester.pump();
    }

    expect(
      getStartBorderFinder(const StarBorder(
        side: BorderSide(),
        points: 11.5,
        innerRadiusRatio: 0.5,
        pointRounding: 0.5,
        valleyRounding: 0.5,
        rotation: 180,
        squash: 0.5,
      )),
      findsOne,
    );
    expect(
      find.text('''
Container(
  decoration: ShapeDecoration(
    shape: StarBorder(
      points: 11.50,
      rotation: 180.00,
      innerRadiusRatio: 0.50,
      pointRounding: 0.50,
      valleyRounding: 0.50,
      squash: 0.50,
    ),
  ),
);'''
      ),
      findsOne,
    );
    expect(
      getStartBorderFinder(const StarBorder.polygon(
        side: BorderSide(),
        sides: 11.5,
        pointRounding: 0.5,
        rotation: 180,
        squash: 0.5,
      )),
      findsOne,
    );
    expect(
      find.text('''
Container(
  decoration: ShapeDecoration(
    shape: StarBorder.polygon(
      sides: 11.50,
      rotation: 180.00,
      cornerRounding: 0.50,
      squash: 0.50,
    ),
  ),
);'''
      ),
      findsOne,
    );
  });
}
