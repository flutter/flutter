// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui show Image;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../painting/image_data.dart';
import '../rendering/mock_canvas.dart';

class TestImageProvider extends ImageProvider<TestImageProvider> {
  TestImageProvider(this.future);

  final Future<Null> future;

  static ui.Image image;

  @override
  Future<TestImageProvider> obtainKey(ImageConfiguration configuration) {
    return new SynchronousFuture<TestImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(TestImageProvider key) {
    return new OneFrameImageStreamCompleter(
      future.then<ImageInfo>((Null value) => new ImageInfo(image: image))
    );
  }
}

Future<Null> main() async {
  TestImageProvider.image = await decodeImageFromList(new Uint8List.fromList(kTransparentImage));

  testWidgets('DecoratedBox handles loading images', (WidgetTester tester) async {
    final GlobalKey key = new GlobalKey();
    final Completer<Null> completer = new Completer<Null>();
    await tester.pumpWidget(
      new KeyedSubtree(
        key: key,
        child: new DecoratedBox(
          decoration: new BoxDecoration(
            image: new DecorationImage(
              image: new TestImageProvider(completer.future),
            ),
          ),
        ),
      ),
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
    completer.complete();
    await tester.idle();
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('Moving a DecoratedBox', (WidgetTester tester) async {
    final Completer<Null> completer = new Completer<Null>();
    final Widget subtree = new KeyedSubtree(
      key: new GlobalKey(),
      child: new RepaintBoundary(
        child: new DecoratedBox(
          decoration: new BoxDecoration(
            image: new DecorationImage(
              image: new TestImageProvider(completer.future),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(subtree);
    await tester.idle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(new Container(child: subtree));
    await tester.idle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    completer.complete(); // schedules microtask, does not run it
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.idle(); // runs microtask
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    await tester.idle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('Circles can have uniform borders', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Container(
        padding: const EdgeInsets.all(50.0),
        decoration: new BoxDecoration(
          shape: BoxShape.circle,
          border: new Border.all(width: 10.0, color: const Color(0x80FF00FF)),
          color: Colors.teal[600]
        )
      )
    );
  });

  testWidgets('Bordered Container insets its child', (WidgetTester tester) async {
    const Key key = const Key('outerContainer');
    await tester.pumpWidget(
      new Center(
        child: new Container(
          key: key,
          decoration: new BoxDecoration(border: new Border.all(width: 10.0)),
          child: new Container(
            width: 25.0,
            height: 25.0
          )
        )
      )
    );
    expect(tester.getSize(find.byKey(key)), equals(const Size(45.0, 45.0)));
  });

  testWidgets('BoxDecoration paints its border correctly', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/7672

    const Key key = const Key('Container with BoxDecoration');
    Widget buildFrame(Border border) {
      return new Center(
        child: new Container(
          key: key,
          width: 100.0,
          height: 50.0,
          decoration: new BoxDecoration(border: border),
        ),
      );
    }

    const Color black = const Color(0xFF000000);

    await tester.pumpWidget(buildFrame(new Border.all()));
    expect(find.byKey(key), paints
      ..rect(color: black, style: PaintingStyle.stroke, strokeWidth: 1.0));

    await tester.pumpWidget(buildFrame(new Border.all(width: 0.0)));
    expect(find.byKey(key), paints
      ..rect(color: black, style: PaintingStyle.stroke, strokeWidth: 0.0));

    const Color green = const Color(0xFF00FF00);
    const BorderSide greenSide = const BorderSide(color: green, width: 10.0);

    await tester.pumpWidget(buildFrame(const Border(top: greenSide)));
    expect(find.byKey(key), paints..path(color: green, style: PaintingStyle.fill));

    await tester.pumpWidget(buildFrame(const Border(left: greenSide)));
    expect(find.byKey(key), paints..path(color: green, style: PaintingStyle.fill));

    await tester.pumpWidget(buildFrame(const Border(right: greenSide)));
    expect(find.byKey(key), paints..path(color: green, style: PaintingStyle.fill));

    await tester.pumpWidget(buildFrame(const Border(bottom: greenSide)));
    expect(find.byKey(key), paints..path(color: green, style: PaintingStyle.fill));

    const Color blue = const Color(0xFF0000FF);
    const BorderSide blueSide = const BorderSide(color: blue, width: 0.0);

    await tester.pumpWidget(buildFrame(const Border(top: blueSide, right: greenSide, bottom: greenSide)));
    expect(find.byKey(key), paints
      ..path() // There's not much point checking the arguments to these calls because paintBorder
      ..path() // reuses the same Paint object each time, configured differently, and so they will
      ..path()); // all appear to have the same settings here (that of the last call).
  });

  testWidgets('BoxDecoration paints its border correctly', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/12165
    await tester.pumpWidget(
      new Column(
        children: <Widget>[
          new Container(
            // There's not currently a way to verify that this paints the same size as the others,
            // so the pattern below just asserts that there's four paths but doesn't check the geometry.
            width: 100.0,
            height: 100.0,
            decoration: const BoxDecoration(
              border: const Border(
                top: const BorderSide(
                  width: 10.0,
                  color: const Color(0xFFEEEEEE),
                ),
                left: const BorderSide(
                  width: 10.0,
                  color: const Color(0xFFFFFFFF),
                ),
                right: const BorderSide(
                  width: 10.0,
                  color: const Color(0xFFFFFFFF),
                ),
                bottom: const BorderSide(
                  width: 10.0,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
          new Container(
            width: 100.0,
            height: 100.0,
            decoration: new BoxDecoration(
              border: new Border.all(
                width: 10.0,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
          new Container(
            width: 100.0,
            height: 100.0,
            decoration: new BoxDecoration(
              border: new Border.all(
                width: 10.0,
                color: const Color(0xFFFFFFFF),
              ),
              borderRadius: const BorderRadius.only(
                topRight: const Radius.circular(10.0),
              ),
            ),
          ),
          new Container(
            width: 100.0,
            height: 100.0,
            decoration: new BoxDecoration(
              border: new Border.all(
                width: 10.0,
                color: const Color(0xFFFFFFFF),
              ),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
    expect(find.byType(Column), paints
      ..path()
      ..path()
      ..path()
      ..path()
      ..rect(rect: new Rect.fromLTRB(355.0, 105.0, 445.0, 195.0))
      ..drrect(
        outer: new RRect.fromLTRBAndCorners(
          350.0, 200.0, 450.0, 300.0,
          topLeft: Radius.zero,
          topRight: const Radius.circular(10.0),
          bottomRight: Radius.zero,
          bottomLeft: Radius.zero,
        ),
        inner: new RRect.fromLTRBAndCorners(
          360.0, 210.0, 440.0, 290.0,
          topLeft: const Radius.circular(-10.0),
          topRight: Radius.zero,
          bottomRight: const Radius.circular(-10.0),
          bottomLeft: const Radius.circular(-10.0),
        ),
      )
      ..circle(x: 400.0, y: 350.0, radius: 45.0)
    );
  });

  testWidgets('Can hit test on BoxDecoration', (WidgetTester tester) async {

    List<int> itemsTapped;

    const Key key = const Key('Container with BoxDecoration');
    Widget buildFrame(Border border) {
      itemsTapped = <int>[];
      return new Center(
        child: new GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          child: new Container(
            key: key,
            width: 100.0,
            height: 50.0,
            decoration: new BoxDecoration(border: border),
          ),
          onTap: () {
            itemsTapped.add(1);
          },
        )
      );
    }

    await tester.pumpWidget(buildFrame(new Border.all()));
    expect(itemsTapped, isEmpty);

    await tester.tap(find.byKey(key));
    expect(itemsTapped, <int>[1]);

    await tester.tapAt(const Offset(350.0, 275.0));
    expect(itemsTapped, <int>[1,1]);

    await tester.tapAt(const Offset(449.0, 324.0));
    expect(itemsTapped, <int>[1,1,1]);

  });

  testWidgets('Can hit test on BoxDecoration circle', (WidgetTester tester) async {

    List<int> itemsTapped;

    const Key key = const Key('Container with BoxDecoration');
    Widget buildFrame(Border border) {
      itemsTapped = <int>[];
      return new Center(
        child: new GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            child: new Container(
            key: key,
            width: 100.0,
            height: 50.0,
            decoration: new BoxDecoration(border: border, shape: BoxShape.circle),
          ),
          onTap: () {
            itemsTapped.add(1);
          },
        )
      );
    }

    await tester.pumpWidget(buildFrame(new Border.all()));
    expect(itemsTapped, isEmpty);

    await tester.tapAt(const Offset(0.0, 0.0));
    expect(itemsTapped, isEmpty);

    await tester.tapAt(const Offset(350.0, 275.0));
    expect(itemsTapped, isEmpty);

    await tester.tapAt(const Offset(400.0, 300.0));
    expect(itemsTapped, <int>[1]);

    await tester.tap(find.byKey(key));
    expect(itemsTapped, <int>[1,1]);

  });

}
