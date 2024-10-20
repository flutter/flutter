// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import '../image_data.dart';
import '../painting/mocks_for_image_cache.dart';

void main() {
  testWidgetsWithLeakTracking('CircleAvatar with dark background color', (WidgetTester tester) async {
    final Color backgroundColor = Colors.blue.shade900;
    await tester.pumpWidget(
      wrap(
        child: CircleAvatar(
          backgroundColor: backgroundColor,
          radius: 50.0,
          child: const Text('Z'),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(CircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final RenderDecoratedBox child = box.child! as RenderDecoratedBox;
    final BoxDecoration decoration = child.decoration as BoxDecoration;
    expect(decoration.color, equals(backgroundColor));

    final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    expect(paragraph.text.style!.color, equals(ThemeData.fallback().primaryColorLight));
  });

  testWidgetsWithLeakTracking('CircleAvatar with light background color', (WidgetTester tester) async {
    final Color backgroundColor = Colors.blue.shade100;
    await tester.pumpWidget(
      wrap(
        child: CircleAvatar(
          backgroundColor: backgroundColor,
          radius: 50.0,
          child: const Text('Z'),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(CircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final RenderDecoratedBox child = box.child! as RenderDecoratedBox;
    final BoxDecoration decoration = child.decoration as BoxDecoration;
    expect(decoration.color, equals(backgroundColor));

    final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    expect(paragraph.text.style!.color, equals(ThemeData.fallback().primaryColorDark));
  });

  testWidgetsWithLeakTracking('CircleAvatar with image background', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: CircleAvatar(
          backgroundImage: MemoryImage(Uint8List.fromList(kTransparentImage)),
          radius: 50.0,
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(CircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final RenderDecoratedBox child = box.child! as RenderDecoratedBox;
    final BoxDecoration decoration = child.decoration as BoxDecoration;
    expect(decoration.image!.fit, equals(BoxFit.cover));
  });

  testWidgetsWithLeakTracking('CircleAvatar with image foreground', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: CircleAvatar(
          foregroundImage: MemoryImage(Uint8List.fromList(kBlueRectPng)),
          radius: 50.0,
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(CircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final RenderDecoratedBox child = box.child! as RenderDecoratedBox;
    final BoxDecoration decoration = child.decoration as BoxDecoration;
    expect(decoration.image!.fit, equals(BoxFit.cover));
  });

  testWidgetsWithLeakTracking('CircleAvatar backgroundImage is used as a fallback for foregroundImage', (WidgetTester tester) async {
    final ErrorImageProvider errorImage = ErrorImageProvider();
    bool caughtForegroundImageError = false;
    await tester.pumpWidget(
      wrap(
        child: RepaintBoundary(
          child: CircleAvatar(
          foregroundImage: errorImage,
          backgroundImage: MemoryImage(Uint8List.fromList(kBlueRectPng)),
          radius: 50.0,
          onForegroundImageError: (_,__) => caughtForegroundImageError = true,
          ),
        ),
      ),
    );

    expect(caughtForegroundImageError, true);
    final RenderConstrainedBox box = tester.renderObject(find.byType(CircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final RenderDecoratedBox child = box.child! as RenderDecoratedBox;
    final BoxDecoration decoration = child.decoration as BoxDecoration;
    expect(decoration.image!.fit, equals(BoxFit.cover));
    await expectLater(
      find.byType(CircleAvatar),
      matchesGoldenFile('circle_avatar.fallback.png'),
    );
  });

  testWidgetsWithLeakTracking('CircleAvatar with foreground color', (WidgetTester tester) async {
    final Color foregroundColor = Colors.red.shade100;
    await tester.pumpWidget(
      wrap(
        child: CircleAvatar(
          foregroundColor: foregroundColor,
          child: const Text('Z'),
        ),
      ),
    );

    final ThemeData fallback = ThemeData.fallback();

    final RenderConstrainedBox box = tester.renderObject(find.byType(CircleAvatar));
    expect(box.size, equals(const Size(40.0, 40.0)));
    final RenderDecoratedBox child = box.child! as RenderDecoratedBox;
    final BoxDecoration decoration = child.decoration as BoxDecoration;
    expect(decoration.color, equals(fallback.primaryColorDark));

    final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    expect(paragraph.text.style!.color, equals(foregroundColor));
  });

  testWidgetsWithLeakTracking('CircleAvatar default colors', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);
    await tester.pumpWidget(
      wrap(
        child: Theme(
          data: theme,
          child: const CircleAvatar(
            child: Text('Z'),
          ),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(CircleAvatar));
    final RenderDecoratedBox child = box.child! as RenderDecoratedBox;
    final BoxDecoration decoration = child.decoration as BoxDecoration;
    expect(decoration.color, equals(theme.colorScheme.primaryContainer));

    final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    expect(paragraph.text.style!.color, equals(theme.colorScheme.onPrimaryContainer));
  });

  testWidgetsWithLeakTracking('CircleAvatar text does not expand with textScaleFactor', (WidgetTester tester) async {
    final Color foregroundColor = Colors.red.shade100;
    await tester.pumpWidget(
      wrap(
        child: CircleAvatar(
          foregroundColor: foregroundColor,
          child: const Text('Z'),
        ),
      ),
    );

    expect(tester.getSize(find.text('Z')), equals(const Size(16.0, 16.0)));

    await tester.pumpWidget(
      wrap(
        child: MediaQuery(
          data: const MediaQueryData(
            textScaleFactor: 2.0,
            size: Size(111.0, 111.0),
            devicePixelRatio: 1.1,
            padding: EdgeInsets.all(11.0),
          ),
          child: CircleAvatar(
            child: Builder(
              builder: (BuildContext context) {
                final MediaQueryData data = MediaQuery.of(context);

                // These should not change.
                expect(data.size, equals(const Size(111.0, 111.0)));
                expect(data.devicePixelRatio, equals(1.1));
                expect(data.padding, equals(const EdgeInsets.all(11.0)));

                // This should be overridden to 1.0.
                expect(data.textScaleFactor, equals(1.0));
                return const Text('Z');
              },
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.text('Z')), equals(const Size(16.0, 16.0)));
  });

  testWidgetsWithLeakTracking('CircleAvatar respects minRadius', (WidgetTester tester) async {
    final Color backgroundColor = Colors.blue.shade900;
    await tester.pumpWidget(
      wrap(
        child: UnconstrainedBox(
          child: CircleAvatar(
            backgroundColor: backgroundColor,
            minRadius: 50.0,
            child: const Text('Z'),
          ),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(CircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final RenderDecoratedBox child = box.child! as RenderDecoratedBox;
    final BoxDecoration decoration = child.decoration as BoxDecoration;
    expect(decoration.color, equals(backgroundColor));

    final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    expect(paragraph.text.style!.color, equals(ThemeData.fallback().primaryColorLight));
  });

  testWidgetsWithLeakTracking('CircleAvatar respects maxRadius', (WidgetTester tester) async {
    final Color backgroundColor = Colors.blue.shade900;
    await tester.pumpWidget(
      wrap(
        child: CircleAvatar(
          backgroundColor: backgroundColor,
          maxRadius: 50.0,
          child: const Text('Z'),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(CircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final RenderDecoratedBox child = box.child! as RenderDecoratedBox;
    final BoxDecoration decoration = child.decoration as BoxDecoration;
    expect(decoration.color, equals(backgroundColor));

    final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    expect(paragraph.text.style!.color, equals(ThemeData.fallback().primaryColorLight));
  });

  testWidgetsWithLeakTracking('CircleAvatar respects setting both minRadius and maxRadius', (WidgetTester tester) async {
    final Color backgroundColor = Colors.blue.shade900;
    await tester.pumpWidget(
      wrap(
        child: CircleAvatar(
          backgroundColor: backgroundColor,
          maxRadius: 50.0,
          minRadius: 50.0,
          child: const Text('Z'),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(CircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final RenderDecoratedBox child = box.child! as RenderDecoratedBox;
    final BoxDecoration decoration = child.decoration as BoxDecoration;
    expect(decoration.color, equals(backgroundColor));

    final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    expect(paragraph.text.style!.color, equals(ThemeData.fallback().primaryColorLight));
  });

  group('Material 2', () {
    // These tests are only relevant for Material 2. Once Material 2
    // support is deprecated and the APIs are removed, these tests
    // can be deleted.

    testWidgetsWithLeakTracking('CircleAvatar default colors with light theme', (WidgetTester tester) async {
      final ThemeData theme = ThemeData(useMaterial3: false, primaryColor: Colors.grey.shade100);
      await tester.pumpWidget(
        wrap(
          child: Theme(
            data: theme,
            child: const CircleAvatar(
              child: Text('Z'),
            ),
          ),
        ),
      );

      final RenderConstrainedBox box = tester.renderObject(find.byType(CircleAvatar));
      final RenderDecoratedBox child = box.child! as RenderDecoratedBox;
      final BoxDecoration decoration = child.decoration as BoxDecoration;
      expect(decoration.color, equals(theme.primaryColorLight));

      final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
      expect(paragraph.text.style!.color, equals(theme.primaryTextTheme.titleLarge!.color));
    });

    testWidgetsWithLeakTracking('CircleAvatar default colors with dark theme', (WidgetTester tester) async {
      final ThemeData theme = ThemeData(useMaterial3: false, primaryColor: Colors.grey.shade800);
      await tester.pumpWidget(
        wrap(
          child: Theme(
            data: theme,
            child: const CircleAvatar(
              child: Text('Z'),
            ),
          ),
        ),
      );

      final RenderConstrainedBox box = tester.renderObject(find.byType(CircleAvatar));
      final RenderDecoratedBox child = box.child! as RenderDecoratedBox;
      final BoxDecoration decoration = child.decoration as BoxDecoration;
      expect(decoration.color, equals(theme.primaryColorDark));

      final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
      expect(paragraph.text.style!.color, equals(theme.primaryTextTheme.titleLarge!.color));
    });
  });
}

Widget wrap({ required Widget child }) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Center(child: child)),
    ),
  );
}
