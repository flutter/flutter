// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Composited transforms - only offsets', (WidgetTester tester) async {
    final LayerLink link = new LayerLink();
    final GlobalKey key = new GlobalKey();
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          children: <Widget>[
            new Positioned(
              left: 123.0,
              top: 456.0,
              child: new CompositedTransformTarget(
                link: link,
                child: new Container(height: 10.0, width: 10.0),
              ),
            ),
            new Positioned(
              left: 787.0,
              top: 343.0,
              child: new CompositedTransformFollower(
                link: link,
                child: new Container(key: key, height: 10.0, width: 10.0),
              ),
            ),
          ],
        ),
      ),
    );
    final RenderBox box = key.currentContext.findRenderObject();
    expect(box.localToGlobal(Offset.zero), const Offset(123.0, 456.0));
  });

  testWidgets('Composited transforms - with rotations', (WidgetTester tester) async {
    final LayerLink link = new LayerLink();
    final GlobalKey key1 = new GlobalKey();
    final GlobalKey key2 = new GlobalKey();
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          children: <Widget>[
            new Positioned(
              top: 123.0,
              left: 456.0,
              child: new Transform.rotate(
                angle: 1.0, // radians
                child: new CompositedTransformTarget(
                  link: link,
                  child: new Container(key: key1, height: 10.0, width: 10.0),
                ),
              ),
            ),
            new Positioned(
              top: 787.0,
              left: 343.0,
              child: new Transform.rotate(
                angle: -0.3, // radians
                child: new CompositedTransformFollower(
                  link: link,
                  child: new Container(key: key2, height: 10.0, width: 10.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final RenderBox box1 = key1.currentContext.findRenderObject();
    final RenderBox box2 = key2.currentContext.findRenderObject();
    final Offset position1 = box1.localToGlobal(Offset.zero);
    final Offset position2 = box2.localToGlobal(Offset.zero);
    expect(position1.dx, moreOrLessEquals(position2.dx));
    expect(position1.dy, moreOrLessEquals(position2.dy));
  });

  testWidgets('Composited transforms - nested', (WidgetTester tester) async {
    final LayerLink link = new LayerLink();
    final GlobalKey key1 = new GlobalKey();
    final GlobalKey key2 = new GlobalKey();
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          children: <Widget>[
            new Positioned(
              top: 123.0,
              left: 456.0,
              child: new Transform.rotate(
                angle: 1.0, // radians
                child: new CompositedTransformTarget(
                  link: link,
                  child: new Container(key: key1, height: 10.0, width: 10.0),
                ),
              ),
            ),
            new Positioned(
              top: 787.0,
              left: 343.0,
              child: new Transform.rotate(
                angle: -0.3, // radians
                child: new Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: new CompositedTransformFollower(
                    link: new LayerLink(),
                    child: new Transform(
                      transform: new Matrix4.skew(0.9, 1.1),
                      child: new Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: new CompositedTransformFollower(
                          link: link,
                          child: new Container(key: key2, height: 10.0, width: 10.0),
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
    final RenderBox box1 = key1.currentContext.findRenderObject();
    final RenderBox box2 = key2.currentContext.findRenderObject();
    final Offset position1 = box1.localToGlobal(Offset.zero);
    final Offset position2 = box2.localToGlobal(Offset.zero);
    expect(position1.dx, moreOrLessEquals(position2.dx));
    expect(position1.dy, moreOrLessEquals(position2.dy));
  });

  testWidgets('Composited transforms - hit testing', (WidgetTester tester) async {
    final LayerLink link = new LayerLink();
    final GlobalKey key1 = new GlobalKey();
    final GlobalKey key2 = new GlobalKey();
    final GlobalKey key3 = new GlobalKey();
    bool _tapped = false;
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          children: <Widget>[
            new Positioned(
              left: 123.0,
              top: 456.0,
              child: new CompositedTransformTarget(
                link: link,
                child: new Container(key: key1, height: 10.0, width: 10.0),
              ),
            ),
            new CompositedTransformFollower(
              link: link,
              child: new GestureDetector(
                key: key2,
                behavior: HitTestBehavior.opaque,
                onTap: () { _tapped = true; },
                child: new Container(key: key3, height: 10.0, width: 10.0),
              ),
            ),
          ],
        ),
      ),
    );
    final RenderBox box2 = key2.currentContext.findRenderObject();
    expect(box2.size, const Size(10.0, 10.0));
    expect(_tapped, isFalse);
    await tester.tap(find.byKey(key1));
    expect(_tapped, isTrue);
  });
}
