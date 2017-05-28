// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../services/mocks_for_image_cache.dart';

const ImageProvider _kImage = const TestImageProvider(21, 42);

void main() {
  testWidgets('ImageIcon sizing - no theme, default size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const ImageIcon(_kImage)
      )
    );

    final RenderBox renderObject = tester.renderObject(find.byType(ImageIcon));
    expect(renderObject.size, equals(const Size.square(24.0)));
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('Icon opacity', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const IconTheme(
          data: const IconThemeData(opacity: 0.5),
          child: const ImageIcon(_kImage),
        ),
      ),
    );

    final Image image = tester.widget(find.byType(Image));
    expect(image, isNotNull);
    expect(image.color.alpha, equals(128));
  });

  testWidgets('ImageIcon sizing - no theme, explicit size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const ImageIcon(
          null,
          size: 96.0
        )
      )
    );

    final RenderBox renderObject = tester.renderObject(find.byType(ImageIcon));
    expect(renderObject.size, equals(const Size.square(96.0)));
  });

  testWidgets('ImageIcon sizing - sized theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const IconTheme(
          data: const IconThemeData(size: 36.0),
          child: const ImageIcon(null)
        )
      )
    );

    final RenderBox renderObject = tester.renderObject(find.byType(ImageIcon));
    expect(renderObject.size, equals(const Size.square(36.0)));
  });

  testWidgets('ImageIcon sizing - sized theme, explicit size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const IconTheme(
          data: const IconThemeData(size: 36.0),
          child: const ImageIcon(
            null,
            size: 48.0
          )
        )
      )
    );

    final RenderBox renderObject = tester.renderObject(find.byType(ImageIcon));
    expect(renderObject.size, equals(const Size.square(48.0)));
  });

  testWidgets('ImageIcon sizing - sizeless theme, default size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const IconTheme(
          data: const IconThemeData(),
          child: const ImageIcon(null)
        )
      )
    );

    final RenderBox renderObject = tester.renderObject(find.byType(ImageIcon));
    expect(renderObject.size, equals(const Size.square(24.0)));
  });
}
