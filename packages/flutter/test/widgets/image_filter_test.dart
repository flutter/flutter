// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  testWidgets('Image filter - blur', (WidgetTester tester) async {
    await tester.pumpWidget(
      RepaintBoundary(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: const Placeholder(),
        ),
      ),
    );
    await expectLater(
      find.byType(ImageFiltered),
      matchesGoldenFile('image_filter_blur.png'),
    );
  });

  testWidgets('Image filter - matrix', (WidgetTester tester) async {
    final ImageFilter matrix = ImageFilter.matrix(Float64List.fromList(<double>[
      0.5, 0.0, 0.0, 0.0, //
      0.0, 0.5, 0.0, 0.0, //
      0.0, 0.0, 1.0, 0.0, //
      0.0, 0.0, 0.0, 1.0, //
    ]));
    await tester.pumpWidget(
      RepaintBoundary(
        child: ImageFiltered(
          imageFilter: matrix,
          child: MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(primarySwatch: Colors.blue),
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Matrix ImageFilter Test'),
              ),
              body: const Center(
                child:Text('Hooray!'),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () { },
                tooltip: 'Increment',
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(ImageFiltered),
      matchesGoldenFile('image_filter_matrix.png'),
    );
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/45213

  testWidgets('Image filter - reuses its layer', (WidgetTester tester) async {
    Future<void> pumpWithSigma(double sigma) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: const Placeholder(),
          ),
        ),
      );
    }

    await pumpWithSigma(5.0);
    final RenderObject renderObject = tester.firstRenderObject(find.byType(ImageFiltered));
    final ImageFilterLayer originalLayer = renderObject.debugLayer! as ImageFilterLayer;

    // Change blur sigma to force a repaint.
    await pumpWithSigma(10.0);
    expect(renderObject.debugLayer, same(originalLayer));
  });
}
