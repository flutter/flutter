// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../image_data.dart';
import '../painting/mocks_for_image_cache.dart';
import 'widgets_app_tester.dart';

void main() {
  testWidgets('RawAvatar renders child widget', (tester) async {
    await tester.pumpWidget(wrap(child: const RawAvatar(child: Text('AB'))));

    expect(find.text('AB'), findsOneWidget);
  });

  testWidgets('RawAvatar applies background color', (tester) async {
    const backgroundColor = Color(0xFF123456);

    await tester.pumpWidget(wrap(child: const RawAvatar(backgroundColor: backgroundColor)));

    final AnimatedContainer container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );

    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, backgroundColor);
  });

  testWidgets('RawAvatar renders icon with iconTheme', (tester) async {
    const iconTheme = IconThemeData(size: 32);

    await tester.pumpWidget(
      wrap(
        child: const RawAvatar(iconTheme: iconTheme, child: Icon(IconData(0xe491))), // Icon person
      ),
    );

    final IconTheme iconThemeWidget = tester.widget<IconTheme>(find.byType(IconTheme));

    expect(iconThemeWidget.data.size, 32);
  });

  testWidgets('RawAvatar applies ShapeDecoration and ClipPath when shape is provided', (
    tester,
  ) async {
    const shape = CircleBorder();

    await tester.pumpWidget(wrap(child: const RawAvatar(shape: shape)));

    final AnimatedContainer container = tester.widget(find.byType(AnimatedContainer));
    expect(container.decoration, isA<ShapeDecoration>());

    final decoration = container.decoration! as ShapeDecoration;
    expect(decoration.shape, shape);

    final ClipPath clipPath = tester.widget(find.byType(ClipPath));
    final clipper = clipPath.clipper! as ShapeBorderClipper;
    expect(clipper.shape, shape);
  });

  testWidgets('RawAvatar with image background', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: RawAvatar(
          backgroundImage: MemoryImage(Uint8List.fromList(kTransparentImage)),
          size: 50.0,
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(RawAvatar));
    expect(box.size, equals(const Size(50.0, 50.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.image!.fit, equals(BoxFit.cover));
  });

  testWidgets('RawAvatar with image foreground', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: RawAvatar(
          foregroundImage: MemoryImage(Uint8List.fromList(kBlueRectPng)),
          size: 50.0,
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(RawAvatar));
    expect(box.size, equals(const Size(50.0, 50.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.image!.fit, equals(BoxFit.cover));
  });

  testWidgets('RawAvatar backgroundImage is used as a fallback for foregroundImage', (
    WidgetTester tester,
  ) async {
    addTearDown(imageCache.clear);
    final errorImage = ErrorImageProvider();
    var caughtForegroundImageError = false;
    await tester.pumpWidget(
      wrap(
        child: RepaintBoundary(
          child: RawAvatar(
            foregroundImage: errorImage,
            backgroundImage: MemoryImage(Uint8List.fromList(kBlueRectPng)),
            size: 50.0,
            onForegroundImageError: (_, _) => caughtForegroundImageError = true,
          ),
        ),
      ),
    );

    expect(caughtForegroundImageError, true);
    final RenderConstrainedBox box = tester.renderObject(find.byType(RawAvatar));
    expect(box.size, equals(const Size(50.0, 50.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.image!.fit, equals(BoxFit.cover));
  });

  testWidgets('RawAvatar respects minSize', (WidgetTester tester) async {
    const backgroundColor = Color(0xFF0D47A1);
    await tester.pumpWidget(
      wrap(
        child: const UnconstrainedBox(
          child: RawAvatar(backgroundColor: backgroundColor, minSize: 50.0, child: Text('Z')),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(RawAvatar));
    expect(box.size, equals(const Size(50.0, 50.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.color, equals(backgroundColor));
  });

  testWidgets('RawAvatar respects maxSize', (WidgetTester tester) async {
    const backgroundColor = Color(0xFF0D47A1);
    await tester.pumpWidget(
      wrap(
        child: const RawAvatar(backgroundColor: backgroundColor, maxSize: 50.0, child: Text('Z')),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(RawAvatar));
    expect(box.size, equals(const Size(50.0, 50.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.color, equals(backgroundColor));
  });

  testWidgets('RawAvatar respects setting both minSize and maxSize', (WidgetTester tester) async {
    const backgroundColor = Color(0xFF0D47A1);
    await tester.pumpWidget(
      wrap(
        child: const RawAvatar(
          backgroundColor: backgroundColor,
          maxSize: 50.0,
          minSize: 50.0,
          child: Text('Z'),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(RawAvatar));
    expect(box.size, equals(const Size(50.0, 50.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.color, equals(backgroundColor));
  });

  testWidgets('RawAvatar renders at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      const TestWidgetsApp(
        color: Color(0x00000000),
        home: SizedBox.shrink(child: RawAvatar(child: Text('X'))),
      ),
    );
  });
}

Widget wrap({required Widget child}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Center(child: child),
    ),
  );
}
