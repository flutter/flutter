// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../rendering/mock_canvas.dart';
import 'test_border.dart' show TestBorder;

final List<String> log = <String>[];

class PathClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    log.add('getClip');
    return Path()
      ..addRect(Rect.fromLTWH(50.0, 50.0, 100.0, 100.0));
  }
  @override
  bool shouldReclip(PathClipper oldClipper) => false;
}

class ValueClipper<T> extends CustomClipper<T> {
  ValueClipper(this.message, this.value);

  final String message;
  final T value;

  @override
  T getClip(Size size) {
    log.add(message);
    return value;
  }

  @override
  bool shouldReclip(ValueClipper<T> oldClipper) {
    return oldClipper.message != message || oldClipper.value != value;
  }
}

void main() {
  testWidgets('ClipPath', (WidgetTester tester) async {
    await tester.pumpWidget(
      ClipPath(
        clipper: PathClipper(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () { log.add('tap'); },
        ),
      )
    );
    expect(log, equals(<String>['getClip']));

    await tester.tapAt(const Offset(10.0, 10.0));
    expect(log, equals(<String>['getClip']));
    log.clear();

    await tester.tapAt(const Offset(100.0, 100.0));
    expect(log, equals(<String>['tap']));
    log.clear();
  });

  testWidgets('ClipOval', (WidgetTester tester) async {
    await tester.pumpWidget(
      ClipOval(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () { log.add('tap'); },
        ),
      )
    );
    expect(log, equals(<String>[]));

    await tester.tapAt(const Offset(10.0, 10.0));
    expect(log, equals(<String>[]));
    log.clear();

    await tester.tapAt(const Offset(400.0, 300.0));
    expect(log, equals(<String>['tap']));
    log.clear();
  });

  testWidgets('Transparent ClipOval hit test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Opacity(
        opacity: 0.0,
        child: ClipOval(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () { log.add('tap'); },
          ),
        ),
      )
    );
    expect(log, equals(<String>[]));

    await tester.tapAt(const Offset(10.0, 10.0));
    expect(log, equals(<String>[]));
    log.clear();

    await tester.tapAt(const Offset(400.0, 300.0));
    expect(log, equals(<String>['tap']));
    log.clear();
  });

  testWidgets('ClipRect', (WidgetTester tester) async {
    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 100.0,
          height: 100.0,
          child: ClipRect(
            clipper: ValueClipper<Rect>('a', Rect.fromLTWH(5.0, 5.0, 10.0, 10.0)),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () { log.add('tap'); },
            ),
          ),
        ),
      )
    );
    expect(log, equals(<String>['a']));

    await tester.tapAt(const Offset(10.0, 10.0));
    expect(log, equals(<String>['a', 'tap']));

    await tester.tapAt(const Offset(100.0, 100.0));
    expect(log, equals(<String>['a', 'tap']));

    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 100.0,
          height: 100.0,
          child: ClipRect(
            clipper: ValueClipper<Rect>('a', Rect.fromLTWH(5.0, 5.0, 10.0, 10.0)),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () { log.add('tap'); },
            ),
          ),
        ),
      )
    );
    expect(log, equals(<String>['a', 'tap']));

    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 200.0,
          height: 200.0,
          child: ClipRect(
            clipper: ValueClipper<Rect>('a', Rect.fromLTWH(5.0, 5.0, 10.0, 10.0)),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () { log.add('tap'); },
            ),
          ),
        ),
      )
    );
    expect(log, equals(<String>['a', 'tap', 'a']));

    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 200.0,
          height: 200.0,
          child: ClipRect(
            clipper: ValueClipper<Rect>('a', Rect.fromLTWH(5.0, 5.0, 10.0, 10.0)),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () { log.add('tap'); },
            ),
          ),
        ),
      )
    );
    expect(log, equals(<String>['a', 'tap', 'a']));

    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 200.0,
          height: 200.0,
          child: ClipRect(
            clipper: ValueClipper<Rect>('b', Rect.fromLTWH(5.0, 5.0, 10.0, 10.0)),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () { log.add('tap'); },
            ),
          ),
        ),
      )
    );
    expect(log, equals(<String>['a', 'tap', 'a', 'b']));

    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 200.0,
          height: 200.0,
          child: ClipRect(
            clipper: ValueClipper<Rect>('c', Rect.fromLTWH(25.0, 25.0, 10.0, 10.0)),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () { log.add('tap'); },
            ),
          ),
        ),
      )
    );
    expect(log, equals(<String>['a', 'tap', 'a', 'b', 'c']));

    await tester.tapAt(const Offset(30.0, 30.0));
    expect(log, equals(<String>['a', 'tap', 'a', 'b', 'c', 'tap']));

    await tester.tapAt(const Offset(100.0, 100.0));
    expect(log, equals(<String>['a', 'tap', 'a', 'b', 'c', 'tap']));
  });

  testWidgets('debugPaintSizeEnabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ClipRect(
        child: Placeholder(),
      ),
    );
    expect(tester.renderObject(find.byType(ClipRect)).paint, paints
      ..save()
      ..clipRect(rect: Rect.fromLTRB(0.0, 0.0, 800.0, 600.0))
      ..save()
      ..path() // Placeholder
      ..restore()
      ..restore(),
    );
    debugPaintSizeEnabled = true;
    expect(tester.renderObject(find.byType(ClipRect)).debugPaint, paints
      ..rect(rect: Rect.fromLTRB(0.0, 0.0, 800.0, 600.0))
      ..paragraph(),
    );
    debugPaintSizeEnabled = false;
  });

  testWidgets('ClipRect painting', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(100.0),
              child: SizedBox(
                height: 100.0,
                width: 100.0,
                child: Transform.rotate(
                  angle: 1.0, // radians
                  child: ClipRect(
                    child: Container(
                      color: Colors.red,
                      child: Container(
                        color: Colors.white,
                        child: RepaintBoundary(
                          child: Center(
                            child: Container(
                              color: Colors.black,
                              height: 10.0,
                              width: 10.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('clip.ClipRect.1.png'),
    );
  });

  testWidgets('ClipRect save, overlay, and antialiasing', (WidgetTester tester) async {
    await tester.pumpWidget(
      RepaintBoundary(
        child: Stack(
          textDirection: TextDirection.ltr,
          children: <Widget>[
            Positioned(
              top: 0.0,
              left: 0.0,
              width: 100.0,
              height: 100.0,
              child: ClipRect(
                child: Container(
                  color: Colors.blue,
                ),
                clipBehavior: Clip.hardEdge,
              ),
            ),
            Positioned(
              top: 50.0,
              left: 50.0,
              width: 100.0,
              height: 100.0,
              child: Transform.rotate(
                angle: 1.0,
                child: Container(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('clip.ClipRectOverlay.1.png'),
    );
  });

  testWidgets('ClipRRect painting', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(100.0),
              child: SizedBox(
                height: 100.0,
                width: 100.0,
                child: Transform.rotate(
                  angle: 1.0, // radians
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.elliptical(10.0, 20.0),
                      topRight: Radius.elliptical(5.0, 30.0),
                      bottomLeft: Radius.elliptical(2.5, 12.0),
                      bottomRight: Radius.elliptical(15.0, 6.0),
                    ),
                    child: Container(
                      color: Colors.red,
                      child: Container(
                        color: Colors.white,
                        child: RepaintBoundary(
                          child: Center(
                            child: Container(
                              color: Colors.black,
                              height: 10.0,
                              width: 10.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('clip.ClipRRect.1.png'),
    );
  });

  testWidgets('ClipOval painting', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(100.0),
              child: SizedBox(
                height: 100.0,
                width: 100.0,
                child: Transform.rotate(
                  angle: 1.0, // radians
                  child: ClipOval(
                    child: Container(
                      color: Colors.red,
                      child: Container(
                        color: Colors.white,
                        child: RepaintBoundary(
                          child: Center(
                            child: Container(
                              color: Colors.black,
                              height: 10.0,
                              width: 10.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('clip.ClipOval.1.png'),
    );
  });

  testWidgets('ClipPath painting', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(100.0),
              child: SizedBox(
                height: 100.0,
                width: 100.0,
                child: Transform.rotate(
                  angle: 1.0, // radians
                  child: ClipPath(
                    clipper: ShapeBorderClipper(
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: Container(
                      color: Colors.red,
                      child: Container(
                        color: Colors.white,
                        child: RepaintBoundary(
                          child: Center(
                            child: Container(
                              color: Colors.black,
                              height: 10.0,
                              width: 10.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('clip.ClipPath.1.png'),
    );
  });

  Center genPhysicalModel(Clip clipBehavior) {
    return Center(
      child: RepaintBoundary(
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(100.0),
            child: SizedBox(
              height: 100.0,
              width: 100.0,
              child: Transform.rotate(
                angle: 1.0, // radians
                child: PhysicalModel(
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.red,
                  clipBehavior: clipBehavior,
                  child: Container(
                    color: Colors.white,
                    child: RepaintBoundary(
                      child: Center(
                        child: Container(
                          color: Colors.black,
                          height: 10.0,
                          width: 10.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('PhysicalModel painting with Clip.antiAlias', (WidgetTester tester) async {
    await tester.pumpWidget(genPhysicalModel(Clip.antiAlias));
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('clip.PhysicalModel.antiAlias.png'),
    );
  });

  testWidgets('PhysicalModel painting with Clip.hardEdge', (WidgetTester tester) async {
    await tester.pumpWidget(genPhysicalModel(Clip.hardEdge));
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('clip.PhysicalModel.hardEdge.png'),
    );
  });

  // There will be bleeding edges on the rect edges, but there shouldn't be any bleeding edges on the
  // round corners.
  testWidgets('PhysicalModel painting with Clip.antiAliasWithSaveLayer', (WidgetTester tester) async {
    await tester.pumpWidget(genPhysicalModel(Clip.antiAliasWithSaveLayer));
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('clip.PhysicalModel.antiAliasWithSaveLayer.png'),
    );
  });

  testWidgets('Default PhysicalModel painting', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(100.0),
              child: SizedBox(
                height: 100.0,
                width: 100.0,
                child: Transform.rotate(
                  angle: 1.0, // radians
                  child: PhysicalModel(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.red,
                    child: Container(
                      color: Colors.white,
                      child: RepaintBoundary(
                        child: Center(
                          child: Container(
                            color: Colors.black,
                            height: 10.0,
                            width: 10.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('clip.PhysicalModel.default.png'),
    );
  });

  Center genPhysicalShape(Clip clipBehavior) {
    return Center(
      child: RepaintBoundary(
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(100.0),
            child: SizedBox(
              height: 100.0,
              width: 100.0,
              child: Transform.rotate(
                angle: 1.0, // radians
                child: PhysicalShape(
                  clipper: ShapeBorderClipper(
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  clipBehavior: clipBehavior,
                  color: Colors.red,
                  child: Container(
                    color: Colors.white,
                    child: RepaintBoundary(
                      child: Center(
                        child: Container(
                          color: Colors.black,
                          height: 10.0,
                          width: 10.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('PhysicalShape painting with Clip.antiAlias', (WidgetTester tester) async {
    await tester.pumpWidget(genPhysicalShape(Clip.antiAlias));
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('clip.PhysicalShape.antiAlias.png'),
    );
  });

  testWidgets('PhysicalShape painting with Clip.hardEdge', (WidgetTester tester) async {
    await tester.pumpWidget(genPhysicalShape(Clip.hardEdge));
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('clip.PhysicalShape.hardEdge.png'),
    );
  });

  testWidgets('PhysicalShape painting with Clip.antiAliasWithSaveLayer', (WidgetTester tester) async {
    await tester.pumpWidget(genPhysicalShape(Clip.antiAliasWithSaveLayer));
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('clip.PhysicalShape.antiAliasWithSaveLayer.png'),
    );
  });

  testWidgets('PhysicalShape painting', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(100.0),
              child: SizedBox(
                height: 100.0,
                width: 100.0,
                child: Transform.rotate(
                  angle: 1.0, // radians
                  child: PhysicalShape(
                    clipper: ShapeBorderClipper(
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    color: Colors.red,
                    child: Container(
                      color: Colors.white,
                      child: RepaintBoundary(
                        child: Center(
                          child: Container(
                            color: Colors.black,
                            height: 10.0,
                            width: 10.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('clip.PhysicalShape.default.png'),
    );
  });

  testWidgets('ClipPath.shape', (WidgetTester tester) async {
    final List<String> logs = <String>[];
    final ShapeBorder shape = TestBorder((String message) { logs.add(message); });
    Widget buildClipPath() {
      return ClipPath.shape(
        shape: shape,
        child: const SizedBox(width: 100.0, height: 100.0),
      );
    }
    final Widget clipPath = buildClipPath();
    // verify that a regular clip works as one would expect
    logs.add('--0');
    await tester.pumpWidget(clipPath);
    // verify that pumping again doesn't recompute the clip
    // even though the widget itself is new (the shape doesn't change identity)
    logs.add('--1');
    await tester.pumpWidget(buildClipPath());
    // verify that ClipPath passes the TextDirection on to its shape
    logs.add('--2');
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: clipPath,
    ));
    // verify that changing the text direction from LTR to RTL has an effect
    // even though the widget itself is identical
    logs.add('--3');
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.rtl,
      child: clipPath,
    ));
    // verify that pumping again with a text direction has no effect
    logs.add('--4');
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.rtl,
      child: buildClipPath(),
    ));
    logs.add('--5');
    // verify that changing the text direction and the widget at the same time
    // works as expected
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: clipPath,
    ));
    expect(logs, <String>[
      '--0',
      'getOuterPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) null',
      '--1',
      '--2',
      'getOuterPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.ltr',
      '--3',
      'getOuterPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.rtl',
      '--4',
      '--5',
      'getOuterPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.ltr',
    ]);
  });
}
