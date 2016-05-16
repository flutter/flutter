// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

final List<String> log = <String>[];

class PathClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    log.add('getClip');
    return new Path()
      ..addRect(new Rect.fromLTWH(50.0, 50.0, 100.0, 100.0));
  }
  @override
  bool shouldRepaint(PathClipper oldWidget) => false;
}

void main() {
  testWidgets('ClipPath', (WidgetTester tester) async {
    await tester.pumpWidget(
      new ClipPath(
        clipper: new PathClipper(),
        child: new GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () { log.add('tap'); },
          child: new Container()
        )
      )
    );
    expect(log, equals(<String>['getClip']));

    await tester.tapAt(new Point(10.0, 10.0));
    expect(log, equals(<String>['getClip']));
    log.clear();

    await tester.tapAt(new Point(100.0, 100.0));
    expect(log, equals(<String>['tap']));
    log.clear();
  });

  testWidgets('ClipOval', (WidgetTester tester) async {
    await tester.pumpWidget(
      new ClipOval(
        child: new GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () { log.add('tap'); },
          child: new Container()
        )
      )
    );
    expect(log, equals(<String>[]));

    await tester.tapAt(new Point(10.0, 10.0));
    expect(log, equals(<String>[]));
    log.clear();

    await tester.tapAt(new Point(400.0, 300.0));
    expect(log, equals(<String>['tap']));
    log.clear();
  });
}
