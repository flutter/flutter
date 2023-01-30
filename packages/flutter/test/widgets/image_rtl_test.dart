// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show Image;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

class TestImageProvider extends ImageProvider<TestImageProvider> {
  const TestImageProvider(this.image);

  final ui.Image image;

  @override
  Future<TestImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<TestImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(TestImageProvider key, DecoderCallback decode) {
    return OneFrameImageStreamCompleter(
      SynchronousFuture<ImageInfo>(ImageInfo(image: image)),
    );
  }
}

void main() {
  late ui.Image testImage;
  setUpAll(() async {
    testImage = await createTestImage(width: 16, height: 9);
  });
  testWidgets('DecorationImage RTL with alignment topEnd and match', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Container(
            width: 100.0,
            height: 50.0,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: TestImageProvider(testImage),
                alignment: AlignmentDirectional.topEnd,
                repeat: ImageRepeat.repeatX,
                matchTextDirection: true,
              ),
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(Container), paints
      ..translate(x: 50.0, y: 0.0)
      ..scale(x: -1.0, y: 1.0)
      ..translate(x: -50.0, y: 0.0)
      ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 100.0, 50.0), shader: isA<ImageShader>())
      ..restore(),
    );
    expect(find.byType(Container), isNot(paints..scale()..scale()));
  });

  testWidgets('DecorationImage LTR with alignment topEnd (and pointless match)', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            width: 100.0,
            height: 50.0,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: TestImageProvider(testImage),
                alignment: AlignmentDirectional.topEnd,
                repeat: ImageRepeat.repeatX,
                matchTextDirection: true,
              ),
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(Container), paints
      ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 100.0, 50.0), shader: isA<ImageShader>())
      ..restore(),
    );
    expect(find.byType(Container), isNot(paints..scale()));
  });

  testWidgets('DecorationImage RTL with alignment topEnd', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Container(
            width: 100.0,
            height: 50.0,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: TestImageProvider(testImage),
                alignment: AlignmentDirectional.topEnd,
                repeat: ImageRepeat.repeatX,
              ),
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(Container), paints
      ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 100.0, 50.0), shader: isA<ImageShader>())
      ..restore(),
    );
    expect(find.byType(Container), isNot(paints..scale()));
  });

  testWidgets('DecorationImage LTR with alignment topEnd', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            width: 100.0,
            height: 50.0,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: TestImageProvider(testImage),
                alignment: AlignmentDirectional.topEnd,
                repeat: ImageRepeat.repeatX,
              ),
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(Container), paints
      ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 100.0, 50.0), shader: isA<ImageShader>())
      ..restore(),
    );
    expect(find.byType(Container), isNot(paints..scale()));
  });

  testWidgets('DecorationImage RTL with alignment center-right and match', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Container(
            width: 100.0,
            height: 50.0,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: TestImageProvider(testImage),
                alignment: Alignment.centerRight,
                matchTextDirection: true,
              ),
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(Container), paints
      ..translate(x: 50.0, y: 0.0)
      ..scale(x: -1.0, y: 1.0)
      ..translate(x: -50.0, y: 0.0)
      ..drawImageRect(source: const Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: const Rect.fromLTRB(0.0, 20.5, 16.0, 29.5))
      ..restore(),
    );
    expect(find.byType(Container), isNot(paints..scale()..scale()));
    expect(find.byType(Container), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('DecorationImage RTL with alignment center-right and no match', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Container(
            width: 100.0,
            height: 50.0,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: TestImageProvider(testImage),
                alignment: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(Container), paints
      ..drawImageRect(source: const Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: const Rect.fromLTRB(84.0, 20.5, 100.0, 29.5)),
    );
    expect(find.byType(Container), isNot(paints..scale()));
    expect(find.byType(Container), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('DecorationImage LTR with alignment center-right and match', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            width: 100.0,
            height: 50.0,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: TestImageProvider(testImage),
                alignment: Alignment.centerRight,
                matchTextDirection: true,
              ),
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(Container), paints
      ..drawImageRect(source: const Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: const Rect.fromLTRB(84.0, 20.5, 100.0, 29.5)),
    );
    expect(find.byType(Container), isNot(paints..scale()));
    expect(find.byType(Container), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('DecorationImage LTR with alignment center-right and no match', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            width: 100.0,
            height: 50.0,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: TestImageProvider(testImage),
                alignment: Alignment.centerRight,
                matchTextDirection: true,
              ),
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(Container), paints
      ..drawImageRect(source: const Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: const Rect.fromLTRB(84.0, 20.5, 100.0, 29.5)),
    );
    expect(find.byType(Container), isNot(paints..scale()));
    expect(find.byType(Container), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('Image RTL with alignment topEnd and match', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SizedBox(
            width: 100.0,
            height: 50.0,
            child: Image(
              image: TestImageProvider(testImage),
              alignment: AlignmentDirectional.topEnd,
              repeat: ImageRepeat.repeatX,
              matchTextDirection: true,
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(SizedBox), paints
      ..translate(x: 50.0, y: 0.0)
      ..scale(x: -1.0, y: 1.0)
      ..translate(x: -50.0, y: 0.0)
      ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 100.0, 50.0), shader: isA<ImageShader>())
      ..restore(),
    );
    expect(find.byType(SizedBox), isNot(paints..scale()..scale()));
  });

  testWidgets('Image LTR with alignment topEnd (and pointless match)', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 100.0,
            height: 50.0,
            child: Image(
              image: TestImageProvider(testImage),
              alignment: AlignmentDirectional.topEnd,
              repeat: ImageRepeat.repeatX,
              matchTextDirection: true,
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(SizedBox), paints
      ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 100.0, 50.0), shader: isA<ImageShader>())
      ..restore(),
    );
    expect(find.byType(SizedBox), isNot(paints..scale()));
  });

  testWidgets('Image RTL with alignment topEnd', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SizedBox(
            width: 100.0,
            height: 50.0,
            child: Image(
              image: TestImageProvider(testImage),
              alignment: AlignmentDirectional.topEnd,
              repeat: ImageRepeat.repeatX,
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(SizedBox), paints
      ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 100.0, 50.0), shader: isA<ImageShader>())
      ..restore(),
    );
    expect(find.byType(SizedBox), isNot(paints..scale()));
  });

  testWidgets('Image LTR with alignment topEnd', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 100.0,
            height: 50.0,
            child: Image(
              image: TestImageProvider(testImage),
              alignment: AlignmentDirectional.topEnd,
              repeat: ImageRepeat.repeatX,
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(SizedBox), paints
      ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 100.0, 50.0), shader: isA<ImageShader>())
      ..restore(),
    );
    expect(find.byType(SizedBox), isNot(paints..scale()));
  });

  testWidgets('Image RTL with alignment center-right and match', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SizedBox(
            width: 100.0,
            height: 50.0,
            child: Image(
              image: TestImageProvider(testImage),
              alignment: Alignment.centerRight,
              matchTextDirection: true,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(SizedBox), paints
      ..translate(x: 50.0, y: 0.0)
      ..scale(x: -1.0, y: 1.0)
      ..translate(x: -50.0, y: 0.0)
      ..drawImageRect(source: const Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: const Rect.fromLTRB(0.0, 20.5, 16.0, 29.5))
      ..restore(),
    );
    expect(find.byType(SizedBox), isNot(paints..scale()..scale()));
    expect(find.byType(SizedBox), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('Image RTL with alignment center-right and no match', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SizedBox(
            width: 100.0,
            height: 50.0,
            child: Image(
              image: TestImageProvider(testImage),
              alignment: Alignment.centerRight,
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(SizedBox), paints
      ..drawImageRect(source: const Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: const Rect.fromLTRB(84.0, 20.5, 100.0, 29.5)),
    );
    expect(find.byType(SizedBox), isNot(paints..scale()));
    expect(find.byType(SizedBox), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('Image LTR with alignment center-right and match', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 100.0,
            height: 50.0,
            child: Image(
              image: TestImageProvider(testImage),
              alignment: Alignment.centerRight,
              matchTextDirection: true,
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(SizedBox), paints
      ..drawImageRect(source: const Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: const Rect.fromLTRB(84.0, 20.5, 100.0, 29.5)),
    );
    expect(find.byType(SizedBox), isNot(paints..scale()));
    expect(find.byType(SizedBox), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('Image LTR with alignment center-right and no match', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 100.0,
            height: 50.0,
            child: Image(
              image: TestImageProvider(testImage),
              alignment: Alignment.centerRight,
              matchTextDirection: true,
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(SizedBox), paints
      ..drawImageRect(source: const Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: const Rect.fromLTRB(84.0, 20.5, 100.0, 29.5)),
    );
    expect(find.byType(SizedBox), isNot(paints..scale()));
    expect(find.byType(SizedBox), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('Image - Switch needing direction', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Image(
          image: TestImageProvider(testImage),
          alignment: Alignment.centerRight,
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Image(
          image: TestImageProvider(testImage),
          alignment: AlignmentDirectional.centerEnd,
          matchTextDirection: true,
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Image(
          image: TestImageProvider(testImage),
          alignment: Alignment.centerRight,
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
  });
}
