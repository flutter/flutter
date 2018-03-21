// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show Image;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

class TestImageProvider extends ImageProvider<TestImageProvider> {
  @override
  Future<TestImageProvider> obtainKey(ImageConfiguration configuration) {
    return new SynchronousFuture<TestImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(TestImageProvider key) {
    return new OneFrameImageStreamCompleter(
      new SynchronousFuture<ImageInfo>(new ImageInfo(image: new TestImage()))
    );
  }
}

class TestImage implements ui.Image {
  @override
  int get width => 16;

  @override
  int get height => 9;

  @override
  void dispose() { }
}

void main() {
  testWidgets('DecorationImage RTL with alignment topEnd and match', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            decoration: new BoxDecoration(
              image: new DecorationImage(
                image: new TestImageProvider(),
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
      ..clipRect(rect: new Rect.fromLTRB(0.0, 0.0, 100.0, 50.0))
      ..translate(x: 50.0, y: 0.0)
      ..scale(x: -1.0, y: 1.0)
      ..translate(x: -50.0, y: 0.0)
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(-12.0, 0.0, 4.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(4.0, 0.0, 20.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(20.0, 0.0, 36.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(36.0, 0.0, 52.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(52.0, 0.0, 68.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(68.0, 0.0, 84.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(84.0, 0.0, 100.0, 9.0))
      ..restore()
    );
    expect(find.byType(Container), isNot(paints..scale()..scale()));
  });

  testWidgets('DecorationImage LTR with alignment topEnd (and pointless match)', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            decoration: new BoxDecoration(
              image: new DecorationImage(
                image: new TestImageProvider(),
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
      ..clipRect(rect: new Rect.fromLTRB(0.0, 0.0, 100.0, 50.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(-12.0, 0.0, 4.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(4.0, 0.0, 20.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(20.0, 0.0, 36.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(36.0, 0.0, 52.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(52.0, 0.0, 68.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(68.0, 0.0, 84.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(84.0, 0.0, 100.0, 9.0))
      ..restore()
    );
    expect(find.byType(Container), isNot(paints..scale()));
  });

  testWidgets('DecorationImage RTL with alignment topEnd', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            decoration: new BoxDecoration(
              image: new DecorationImage(
                image: new TestImageProvider(),
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
      ..clipRect(rect: new Rect.fromLTRB(0.0, 0.0, 100.0, 50.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(16.0, 0.0, 32.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(32.0, 0.0, 48.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(48.0, 0.0, 64.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(64.0, 0.0, 80.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(80.0, 0.0, 96.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(96.0, 0.0, 112.0, 9.0))
      ..restore()
    );
    expect(find.byType(Container), isNot(paints..scale()));
  });

  testWidgets('DecorationImage LTR with alignment topEnd', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            decoration: new BoxDecoration(
              image: new DecorationImage(
                image: new TestImageProvider(),
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
      ..clipRect(rect: new Rect.fromLTRB(0.0, 0.0, 100.0, 50.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(-12.0, 0.0, 4.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(4.0, 0.0, 20.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(20.0, 0.0, 36.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(36.0, 0.0, 52.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(52.0, 0.0, 68.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(68.0, 0.0, 84.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(84.0, 0.0, 100.0, 9.0))
      ..restore()
    );
    expect(find.byType(Container), isNot(paints..scale()));
  });

  testWidgets('DecorationImage RTL with alignment center-right and match', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            decoration: new BoxDecoration(
              image: new DecorationImage(
                image: new TestImageProvider(),
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
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(0.0, 20.5, 16.0, 29.5))
      ..restore()
    );
    expect(find.byType(Container), isNot(paints..scale()..scale()));
    expect(find.byType(Container), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('DecorationImage RTL with alignment center-right and no match', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            decoration: new BoxDecoration(
              image: new DecorationImage(
                image: new TestImageProvider(),
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
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(84.0, 20.5, 100.0, 29.5))
    );
    expect(find.byType(Container), isNot(paints..scale()));
    expect(find.byType(Container), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('DecorationImage LTR with alignment center-right and match', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            decoration: new BoxDecoration(
              image: new DecorationImage(
                image: new TestImageProvider(),
                alignment: Alignment.centerRight,
                matchTextDirection: true
              ),
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(Container), paints
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(84.0, 20.5, 100.0, 29.5))
    );
    expect(find.byType(Container), isNot(paints..scale()));
    expect(find.byType(Container), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('DecorationImage LTR with alignment center-right and no match', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            decoration: new BoxDecoration(
              image: new DecorationImage(
                image: new TestImageProvider(),
                alignment: Alignment.centerRight,
                matchTextDirection: true
              ),
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(Container), paints
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(84.0, 20.5, 100.0, 29.5))
    );
    expect(find.byType(Container), isNot(paints..scale()));
    expect(find.byType(Container), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('Image RTL with alignment topEnd and match', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            child: new Image(
              image: new TestImageProvider(),
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
    expect(find.byType(Container), paints
      ..clipRect(rect: new Rect.fromLTRB(0.0, 0.0, 100.0, 50.0))
      ..translate(x: 50.0, y: 0.0)
      ..scale(x: -1.0, y: 1.0)
      ..translate(x: -50.0, y: 0.0)
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(-12.0, 0.0, 4.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(4.0, 0.0, 20.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(20.0, 0.0, 36.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(36.0, 0.0, 52.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(52.0, 0.0, 68.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(68.0, 0.0, 84.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(84.0, 0.0, 100.0, 9.0))
      ..restore()
    );
    expect(find.byType(Container), isNot(paints..scale()..scale()));
  });

  testWidgets('Image LTR with alignment topEnd (and pointless match)', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            child: new Image(
              image: new TestImageProvider(),
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
    expect(find.byType(Container), paints
      ..clipRect(rect: new Rect.fromLTRB(0.0, 0.0, 100.0, 50.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(-12.0, 0.0, 4.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(4.0, 0.0, 20.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(20.0, 0.0, 36.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(36.0, 0.0, 52.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(52.0, 0.0, 68.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(68.0, 0.0, 84.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(84.0, 0.0, 100.0, 9.0))
      ..restore()
    );
    expect(find.byType(Container), isNot(paints..scale()));
  });

  testWidgets('Image RTL with alignment topEnd', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            child: new Image(
              image: new TestImageProvider(),
              alignment: AlignmentDirectional.topEnd,
              repeat: ImageRepeat.repeatX,
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(Container), paints
      ..clipRect(rect: new Rect.fromLTRB(0.0, 0.0, 100.0, 50.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(16.0, 0.0, 32.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(32.0, 0.0, 48.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(48.0, 0.0, 64.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(64.0, 0.0, 80.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(80.0, 0.0, 96.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(96.0, 0.0, 112.0, 9.0))
      ..restore()
    );
    expect(find.byType(Container), isNot(paints..scale()));
  });

  testWidgets('Image LTR with alignment topEnd', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            child: new Image(
              image: new TestImageProvider(),
              alignment: AlignmentDirectional.topEnd,
              repeat: ImageRepeat.repeatX,
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(Container), paints
      ..clipRect(rect: new Rect.fromLTRB(0.0, 0.0, 100.0, 50.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(-12.0, 0.0, 4.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(4.0, 0.0, 20.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(20.0, 0.0, 36.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(36.0, 0.0, 52.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(52.0, 0.0, 68.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(68.0, 0.0, 84.0, 9.0))
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(84.0, 0.0, 100.0, 9.0))
      ..restore()
    );
    expect(find.byType(Container), isNot(paints..scale()));
  });

  testWidgets('Image RTL with alignment center-right and match', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            child: new Image(
              image: new TestImageProvider(),
              alignment: Alignment.centerRight,
              matchTextDirection: true,
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
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(0.0, 20.5, 16.0, 29.5))
      ..restore()
    );
    expect(find.byType(Container), isNot(paints..scale()..scale()));
    expect(find.byType(Container), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('Image RTL with alignment center-right and no match', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            child: new Image(
              image: new TestImageProvider(),
              alignment: Alignment.centerRight,
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(Container), paints
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(84.0, 20.5, 100.0, 29.5))
    );
    expect(find.byType(Container), isNot(paints..scale()));
    expect(find.byType(Container), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('Image LTR with alignment center-right and match', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            child: new Image(
              image: new TestImageProvider(),
              alignment: Alignment.centerRight,
              matchTextDirection: true
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(Container), paints
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(84.0, 20.5, 100.0, 29.5))
    );
    expect(find.byType(Container), isNot(paints..scale()));
    expect(find.byType(Container), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('Image LTR with alignment center-right and no match', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Container(
            width: 100.0,
            height: 50.0,
            child: new Image(
              image: new TestImageProvider(),
              alignment: Alignment.centerRight,
              matchTextDirection: true
            ),
          ),
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    expect(find.byType(Container), paints
      ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 16.0, 9.0), destination: new Rect.fromLTRB(84.0, 20.5, 100.0, 29.5))
    );
    expect(find.byType(Container), isNot(paints..scale()));
    expect(find.byType(Container), isNot(paints..drawImageRect()..drawImageRect()));
  });

  testWidgets('Image - Switch needing direction', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Image(
          image: new TestImageProvider(),
          alignment: Alignment.centerRight,
          matchTextDirection: false,
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Image(
          image: new TestImageProvider(),
          alignment: AlignmentDirectional.centerEnd,
          matchTextDirection: true,
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Image(
          image: new TestImageProvider(),
          alignment: Alignment.centerRight,
          matchTextDirection: false,
        ),
      ),
      Duration.zero,
      EnginePhase.layout, // so that we don't try to paint the fake images
    );
  });
}