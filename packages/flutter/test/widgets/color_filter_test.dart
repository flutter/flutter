// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Color filter - red', (WidgetTester tester) async {
    await tester.pumpWidget(
      const RepaintBoundary(
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.red, BlendMode.color),
          child: Placeholder(),
        ),
      ),
    );
    await expectLater(
      find.byType(ColorFiltered),
      matchesGoldenFile(
        'color_filter_red.png',
        version: 1,
      ),
    );
  });

  testWidgets('Color filter - sepia', (WidgetTester tester) async {
    // TODO(dnfield): This should be const. https://github.com/dart-lang/sdk/issues/37503
    final ColorFilter sepia = ColorFilter.matrix(<double>[
      0.39,  0.769, 0.189, 0, 0, //
      0.349, 0.686, 0.168, 0, 0, //
      0.272, 0.534, 0.131, 0, 0, //
      0,     0,     0,     1, 0, //
    ]);
    await tester.pumpWidget(
      RepaintBoundary(
        child: ColorFiltered(
          colorFilter: sepia,
          child: MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(primarySwatch: Colors.blue),
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Sepia ColorFilter Test'),
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
      )
    );
    await expectLater(
      find.byType(ColorFiltered),
      matchesGoldenFile(
        'color_filter_sepia.png',
        version: 1,
      ),
    );
  });
}