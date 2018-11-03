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

  final Future<void> future;

  static ui.Image image;

  @override
  Future<TestImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<TestImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(TestImageProvider key) {
    return OneFrameImageStreamCompleter(
      future.then<ImageInfo>((void value) => ImageInfo(image: image))
    );
  }
}

Future<void> main() async {
  TestImageProvider.image = await decodeImageFromList(Uint8List.fromList(kTransparentImage));

  testWidgets('DecoratedBox handles loading images', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    final Completer<void> completer = Completer<void>();
    await tester.pumpWidget(
      KeyedSubtree(
        key: key,
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: TestImageProvider(completer.future),
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
    final Completer<void> completer = Completer<void>();
    final Widget subtree = KeyedSubtree(
      key: GlobalKey(),
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: TestImageProvider(completer.future),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(subtree);
    await tester.idle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(Container(child: subtree));
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
      Container(
        padding: const EdgeInsets.all(50.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: 10.0, color: const Color(0x80FF00FF)),
          color: Colors.teal[600]
        )
      )
    );
  });

  testWidgets('Bordered Container insets its child', (WidgetTester tester) async {
    const Key key = Key('outerContainer');
    await tester.pumpWidget(
      Center(
        child: Container(
          key: key,
          decoration: BoxDecoration(border: Border.all(width: 10.0)),
          child: Container(
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

    const Key key = Key('Container with BoxDecoration');
    Widget buildFrame(Border border) {
      return Center(
        child: Container(
          key: key,
          width: 100.0,
          height: 50.0,
          decoration: BoxDecoration(border: border),
        ),
      );
    }

    const Color black = Color(0xFF000000);

    await tester.pumpWidget(buildFrame(Border.all()));
    expect(find.byKey(key), paints
      ..rect(color: black, style: PaintingStyle.stroke, strokeWidth: 1.0));

    await tester.pumpWidget(buildFrame(Border.all(width: 0.0)));
    expect(find.byKey(key), paints
      ..rect(color: black, style: PaintingStyle.stroke, strokeWidth: 0.0));

    const Color green = Color(0xFF00FF00);
    const BorderSide greenSide = BorderSide(color: green, width: 10.0);

    await tester.pumpWidget(buildFrame(const Border(top: greenSide)));
    expect(find.byKey(key), paints..path(color: green, style: PaintingStyle.fill));

    await tester.pumpWidget(buildFrame(const Border(left: greenSide)));
    expect(find.byKey(key), paints..path(color: green, style: PaintingStyle.fill));

    await tester.pumpWidget(buildFrame(const Border(right: greenSide)));
    expect(find.byKey(key), paints..path(color: green, style: PaintingStyle.fill));

    await tester.pumpWidget(buildFrame(const Border(bottom: greenSide)));
    expect(find.byKey(key), paints..path(color: green, style: PaintingStyle.fill));

    const Color blue = Color(0xFF0000FF);
    const BorderSide blueSide = BorderSide(color: blue, width: 0.0);

    await tester.pumpWidget(buildFrame(const Border(top: blueSide, right: greenSide, bottom: greenSide)));
    expect(find.byKey(key), paints
      ..path() // There's not much point checking the arguments to these calls because paintBorder
      ..path() // reuses the same Paint object each time, configured differently, and so they will
      ..path()); // all appear to have the same settings here (that of the last call).
  });

  testWidgets('BoxDecoration paints its border correctly', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/12165
    await tester.pumpWidget(
      Column(
        children: <Widget>[
          Container(
            // There's not currently a way to verify that this paints the same size as the others,
            // so the pattern below just asserts that there's four paths but doesn't check the geometry.
            width: 100.0,
            height: 100.0,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  width: 10.0,
                  color: Color(0xFFEEEEEE),
                ),
                left: BorderSide(
                  width: 10.0,
                  color: Color(0xFFFFFFFF),
                ),
                right: BorderSide(
                  width: 10.0,
                  color: Color(0xFFFFFFFF),
                ),
                bottom: BorderSide(
                  width: 10.0,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
          Container(
            width: 100.0,
            height: 100.0,
            decoration: BoxDecoration(
              border: Border.all(
                width: 10.0,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
          Container(
            width: 100.0,
            height: 100.0,
            decoration: BoxDecoration(
              border: Border.all(
                width: 10.0,
                color: const Color(0xFFFFFFFF),
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10.0),
              ),
            ),
          ),
          Container(
            width: 100.0,
            height: 100.0,
            decoration: BoxDecoration(
              border: Border.all(
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
      ..rect(rect: Rect.fromLTRB(355.0, 105.0, 445.0, 195.0))
      ..drrect(
        outer: RRect.fromLTRBAndCorners(
          350.0, 200.0, 450.0, 300.0,
          topLeft: Radius.zero,
          topRight: const Radius.circular(10.0),
          bottomRight: Radius.zero,
          bottomLeft: Radius.zero,
        ),
        inner: RRect.fromLTRBAndCorners(
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

    const Key key = Key('Container with BoxDecoration');
    Widget buildFrame(Border border) {
      itemsTapped = <int>[];
      return Center(
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          child: Container(
            key: key,
            width: 100.0,
            height: 50.0,
            decoration: BoxDecoration(border: border),
          ),
          onTap: () {
            itemsTapped.add(1);
          },
        )
      );
    }

    await tester.pumpWidget(buildFrame(Border.all()));
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

    const Key key = Key('Container with BoxDecoration');
    Widget buildFrame(Border border) {
      itemsTapped = <int>[];
      return Center(
        child: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            child: Container(
            key: key,
            width: 100.0,
            height: 50.0,
            decoration: BoxDecoration(border: border, shape: BoxShape.circle),
          ),
          onTap: () {
            itemsTapped.add(1);
          },
        )
      );
    }

    await tester.pumpWidget(buildFrame(Border.all()));
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
