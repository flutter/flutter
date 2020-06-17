// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Composited transforms - only offsets', (WidgetTester tester) async {
    final LayerLink link = LayerLink();
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 123.0,
              top: 456.0,
              child: CompositedTransformTarget(
                link: link,
                child: const SizedBox(height: 10.0, width: 10.0),
              ),
            ),
            Positioned(
              left: 787.0,
              top: 343.0,
              child: CompositedTransformFollower(
                link: link,
                child: Container(key: key, height: 10.0, width: 10.0),
              ),
            ),
          ],
        ),
      ),
    );
    final RenderBox box = key.currentContext.findRenderObject() as RenderBox;
    expect(box.localToGlobal(Offset.zero), const Offset(123.0, 456.0));
  });

  testWidgets('Composited transforms - with rotations', (WidgetTester tester) async {
    final LayerLink link = LayerLink();
    final GlobalKey key1 = GlobalKey();
    final GlobalKey key2 = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 123.0,
              left: 456.0,
              child: Transform.rotate(
                angle: 1.0, // radians
                child: CompositedTransformTarget(
                  link: link,
                  child: Container(key: key1, height: 10.0, width: 10.0),
                ),
              ),
            ),
            Positioned(
              top: 787.0,
              left: 343.0,
              child: Transform.rotate(
                angle: -0.3, // radians
                child: CompositedTransformFollower(
                  link: link,
                  child: Container(key: key2, height: 10.0, width: 10.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final RenderBox box1 = key1.currentContext.findRenderObject() as RenderBox;
    final RenderBox box2 = key2.currentContext.findRenderObject() as RenderBox;
    final Offset position1 = box1.localToGlobal(Offset.zero);
    final Offset position2 = box2.localToGlobal(Offset.zero);
    expect(position1.dx, moreOrLessEquals(position2.dx));
    expect(position1.dy, moreOrLessEquals(position2.dy));
  });

  testWidgets('Composited transforms - nested', (WidgetTester tester) async {
    final LayerLink link = LayerLink();
    final GlobalKey key1 = GlobalKey();
    final GlobalKey key2 = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 123.0,
              left: 456.0,
              child: Transform.rotate(
                angle: 1.0, // radians
                child: CompositedTransformTarget(
                  link: link,
                  child: Container(key: key1, height: 10.0, width: 10.0),
                ),
              ),
            ),
            Positioned(
              top: 787.0,
              left: 343.0,
              child: Transform.rotate(
                angle: -0.3, // radians
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CompositedTransformFollower(
                    link: LayerLink(),
                    child: Transform(
                      transform: Matrix4.skew(0.9, 1.1),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: CompositedTransformFollower(
                          link: link,
                          child: Container(key: key2, height: 10.0, width: 10.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final RenderBox box1 = key1.currentContext.findRenderObject() as RenderBox;
    final RenderBox box2 = key2.currentContext.findRenderObject() as RenderBox;
    final Offset position1 = box1.localToGlobal(Offset.zero);
    final Offset position2 = box2.localToGlobal(Offset.zero);
    expect(position1.dx, moreOrLessEquals(position2.dx));
    expect(position1.dy, moreOrLessEquals(position2.dy));
  });

  testWidgets('Composited transforms - hit testing', (WidgetTester tester) async {
    final LayerLink link = LayerLink();
    final GlobalKey key1 = GlobalKey();
    final GlobalKey key2 = GlobalKey();
    final GlobalKey key3 = GlobalKey();
    bool _tapped = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 123.0,
              top: 456.0,
              child: CompositedTransformTarget(
                link: link,
                child: Container(key: key1, height: 10.0, width: 10.0),
              ),
            ),
            CompositedTransformFollower(
              link: link,
              child: GestureDetector(
                key: key2,
                behavior: HitTestBehavior.opaque,
                onTap: () { _tapped = true; },
                child: Container(key: key3, height: 10.0, width: 10.0),
              ),
            ),
          ],
        ),
      ),
    );
    final RenderBox box2 = key2.currentContext.findRenderObject() as RenderBox;
    expect(box2.size, const Size(10.0, 10.0));
    expect(_tapped, isFalse);
    await tester.tap(find.byKey(key1));
    expect(_tapped, isTrue);
  });
}
