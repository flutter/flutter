// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../image_data.dart';

void main() {
  testWidgets('RawAvatar with child displays initials', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: const RawAvatar(
          size: 100.0,
          shape: CircleBorder(),
          backgroundColor: Color(0xFF0000FF),
          foregroundColor: Color(0xFFFFFFFF),
          child: Center(child: Text('AB')),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject<RenderConstrainedBox>(
      find.byType(RawAvatar),
    );
    expect(box.size, equals(const Size(100.0, 100.0)));

    expect(find.text('AB'), findsOneWidget);

    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.text('AB'));
    expect(paragraph.text.style!.color, equals(const Color(0xFFFFFFFF)));
  });

  testWidgets('RawAvatar with background image', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: RawAvatar(
          size: 100.0,
          shape: const CircleBorder(),
          backgroundImage: MemoryImage(Uint8List.fromList(kTransparentImage)),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject<RenderConstrainedBox>(
      find.byType(RawAvatar),
    );
    expect(box.size, equals(const Size(100.0, 100.0)));

    // Verify the decoration was applied
    final Container container = tester.widget<Container>(find.byType(Container));
    expect(container.decoration, isNotNull);
    final decoration = container.decoration! as ShapeDecoration;
    expect(decoration.image!.fit, equals(BoxFit.cover));
    expect(decoration.shape, isA<CircleBorder>());
  });

  testWidgets('RawAvatar with rounded rectangle shape', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: RawAvatar(
          size: 100.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          backgroundColor: const Color(0xFF00FF00),
          child: const Center(child: Text('XY')),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject<RenderConstrainedBox>(
      find.byType(RawAvatar),
    );
    expect(box.size, equals(const Size(100.0, 100.0)));

    final Container container = tester.widget<Container>(find.byType(Container));
    expect(container.decoration, isNotNull);
    final decoration = container.decoration! as ShapeDecoration;
    expect(decoration.color, equals(const Color(0xFF00FF00)));
    expect(decoration.shape, isA<RoundedRectangleBorder>());
  });

  testWidgets('RawAvatar uses default size when none specified', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: const RawAvatar(
          shape: CircleBorder(),
          backgroundColor: Color(0xFF0000FF),
          child: Center(child: Text('A')),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject<RenderConstrainedBox>(
      find.byType(RawAvatar),
    );
    // Default size is 40.0
    expect(box.size, equals(const Size(40.0, 40.0)));
  });

  testWidgets('RawAvatar with foreground image', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: RawAvatar(
          size: 100.0,
          shape: const CircleBorder(),
          backgroundColor: const Color(0xFF0000FF),
          foregroundImage: MemoryImage(Uint8List.fromList(kBlueRectPng)),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject<RenderConstrainedBox>(
      find.byType(RawAvatar),
    );
    expect(box.size, equals(const Size(100.0, 100.0)));

    // Check foreground decoration is present
    final Container container = tester.widget<Container>(find.byType(Container));
    expect(container.foregroundDecoration, isNotNull);
    final foregroundDecoration = container.foregroundDecoration! as ShapeDecoration;
    expect(foregroundDecoration.image!.fit, equals(BoxFit.cover));
    expect(foregroundDecoration.shape, isA<CircleBorder>());
  });

  testWidgets('RawAvatar respects minSize and maxSize', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: const UnconstrainedBox(
          child: RawAvatar(
            minSize: 60.0,
            maxSize: 100.0,
            shape: CircleBorder(),
            backgroundColor: Color(0xFF0000FF),
          ),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject<RenderConstrainedBox>(
      find.byType(RawAvatar),
    );
    // With minSize 60, the unconstrained avatar should be at least 60x60
    expect(box.size.width, greaterThanOrEqualTo(60.0));
    expect(box.size.height, greaterThanOrEqualTo(60.0));
  });

  testWidgets('RawAvatar with stadium shape', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: const RawAvatar(
          size: 80.0,
          shape: StadiumBorder(),
          backgroundColor: Color(0xFFFF0000),
          child: Center(child: Text('Stadium')),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject<RenderConstrainedBox>(
      find.byType(RawAvatar),
    );
    expect(box.size, equals(const Size(80.0, 80.0)));

    final Container container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as ShapeDecoration;
    expect(decoration.shape, isA<StadiumBorder>());
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
