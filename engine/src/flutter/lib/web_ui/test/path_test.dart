// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:ui/ui.dart';

import 'matchers.dart';

void main() {
  test('Should have no subpaths when created', () {
    final Path path = Path();
    expect(path.subpaths.length, 0);
  });

  test('LineTo should add command', () {
    final Path path = Path();
    path.moveTo(5.0, 10.0);
    path.lineTo(20.0, 40.0);
    path.lineTo(30.0, 50.0);
    expect(path.subpaths.length, 1);
    expect(path.subpaths[0].currentX, 30.0);
    expect(path.subpaths[0].currentY, 50.0);
  });

  test('LineTo should add moveTo 0,0 when first call to Path API', () {
    final Path path = Path();
    path.lineTo(20.0, 40.0);
    expect(path.subpaths.length, 1);
    expect(path.subpaths[0].currentX, 20.0);
    expect(path.subpaths[0].currentY, 40.0);
  });

  test('relativeLineTo should increments currentX', () {
    final Path path = Path();
    path.moveTo(5.0, 10.0);
    path.lineTo(20.0, 40.0);
    path.relativeLineTo(5.0, 5.0);
    expect(path.subpaths.length, 1);
    expect(path.subpaths[0].currentX, 25.0);
    expect(path.subpaths[0].currentY, 45.0);
  });

  test('Should allow calling relativeLineTo before moveTo', () {
    final Path path = Path();
    path.relativeLineTo(5.0, 5.0);
    path.moveTo(5.0, 10.0);
    expect(path.subpaths.length, 2);
    expect(path.subpaths[0].currentX, 5.0);
    expect(path.subpaths[0].currentY, 5.0);
    expect(path.subpaths[1].currentX, 5.0);
    expect(path.subpaths[1].currentY, 10.0);
  });

  test('Should allow relativeLineTo after reset', () {
    final Path path = Path();
    final Path subPath = Path();
    subPath.moveTo(50.0, 60.0);
    subPath.lineTo(200.0, 200.0);
    path.extendWithPath(subPath, const Offset(0.0, 0.0));
    path.reset();
    path.relativeLineTo(5.0, 5.0);
    expect(path.subpaths.length, 1);
    expect(path.subpaths[0].currentX, 5.0);
    expect(path.subpaths[0].currentY, 5.0);
  });

  test('Should detect rectangular path', () {
    final Path path = Path();
    path.addRect(const Rect.fromLTWH(1.0, 2.0, 3.0, 4.0));
    expect(path.webOnlyPathAsRect, const Rect.fromLTWH(1.0, 2.0, 3.0, 4.0));
  });

  test('Should detect non rectangular path if empty', () {
    final Path path = Path();
    expect(path.webOnlyPathAsRect, null);
  });

  test('Should detect non rectangular path if there are multiple subpaths', () {
    final Path path = Path();
    path.addRect(const Rect.fromLTWH(1.0, 2.0, 3.0, 4.0));
    path.addRect(const Rect.fromLTWH(5.0, 6.0, 7.0, 8.0));
    expect(path.webOnlyPathAsRect, null);
  });

  test('Should detect rounded rectangular path', () {
    final Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(1.0, 2.0, 3.0, 4.0), const Radius.circular(2.0)));
    expect(
        path.webOnlyPathAsRoundedRect,
        RRect.fromRectAndRadius(const Rect.fromLTWH(1.0, 2.0, 3.0, 4.0),
            const Radius.circular(2.0)));
  });

  test('Should detect non rounded rectangular path if empty', () {
    final Path path = Path();
    expect(path.webOnlyPathAsRoundedRect, null);
  });

  test('Should detect rectangular path is not round', () {
    final Path path = Path();
    path.addRect(const Rect.fromLTWH(1.0, 2.0, 3.0, 4.0));
    expect(path.webOnlyPathAsRoundedRect, null);
  });

  test(
      'Should detect non rounded  rectangular path if there are '
      'multiple subpaths', () {
    final Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(1.0, 2.0, 3.0, 4.0), const Radius.circular(2.0)));
    path.addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(1.0, 2.0, 3.0, 4.0), const Radius.circular(2.0)));
    expect(path.webOnlyPathAsRoundedRect, null);
  });

  test('Should compute bounds as empty for empty and moveTo only path', () {
    final Path emptyPath = Path();
    expect(emptyPath.getBounds(), Rect.zero);

    final Path path = Path();
    path.moveTo(50, 60);
    expect(path.getBounds(), const Rect.fromLTRB(50, 60, 50, 60));
  });

  test('Should compute bounds for lines', () {
    final Path path = Path();
    path.moveTo(25, 30);
    path.lineTo(100, 200);
    expect(path.getBounds(), const Rect.fromLTRB(25, 30, 100, 200));

    final Path path2 = Path();
    path2.moveTo(250, 300);
    path2.lineTo(50, 60);
    expect(path2.getBounds(), const Rect.fromLTRB(50, 60, 250, 300));
  });

  test('Should compute bounds for quadraticBezierTo', () {
    final Path path1 = Path();
    path1.moveTo(285.2, 682.1);
    path1.quadraticBezierTo(432.0, 431.4, 594.9, 681.2);
    expect(
        path1.getBounds(),
        within<Rect>(
            distance: 0.1,
            from: const Rect.fromLTRB(285.2, 556.5, 594.9, 682.1)));

    // Control point below start , end.
    final Path path2 = Path();
    path2.moveTo(285.2, 682.1);
    path2.quadraticBezierTo(447.4, 946.8, 594.9, 681.2);
    expect(
        path2.getBounds(),
        within<Rect>(
            distance: 0.1,
            from: const Rect.fromLTRB(285.2, 681.2, 594.9, 814.2)));

    // Control point to the right of end point.
    final Path path3 = Path();
    path3.moveTo(468.3, 685.6);
    path3.quadraticBezierTo(644.7, 555.2, 594.9, 681.2);
    expect(
        path3.getBounds(),
        within<Rect>(
            distance: 0.1,
            from: const Rect.fromLTRB(468.3, 619.3, 605.9, 685.6)));
  });

  test('Should compute bounds for cubicTo', () {
    final Path path1 = Path();
    path1.moveTo(220, 300);
    path1.cubicTo(230, 120, 400, 125, 410, 280);
    expect(
        path1.getBounds(),
        within<Rect>(
            distance: 0.1,
            from: const Rect.fromLTRB(220.0, 164.3, 410.0, 300.0)));

    // control point 1 to the right of control point 2
    final Path path2 = Path();
    path2.moveTo(220, 300);
    path2.cubicTo(564.2, 13.7, 400.0, 125.0, 410.0, 280.0);
    expect(
        path2.getBounds(),
        within<Rect>(
            distance: 0.1,
            from: const Rect.fromLTRB(220.0, 122.8, 440.5, 300.0)));

    // control point 1 to the right of control point 2 inflection
    final Path path3 = Path();
    path3.moveTo(220, 300);
    path3.cubicTo(839.8, 67.9, 400.0, 125.0, 410.0, 280.0);
    expect(
        path3.getBounds(),
        within<Rect>(
            distance: 0.1,
            from: const Rect.fromLTRB(220.0, 144.5, 552.1, 300.0)));

    // control point 1 below and between start and end points
    final Path path4 = Path();
    path4.moveTo(220.0, 300.0);
    path4.cubicTo(354.8, 388.3, 400.0, 125.0, 410.0, 280.0);
    expect(
        path4.getBounds(),
        within<Rect>(
            distance: 0.1,
            from: const Rect.fromLTRB(220.0, 230.0, 410.0, 318.6)));

    // control points inverted below
    final Path path5 = Path();
    path5.moveTo(220.0, 300.0);
    path5.cubicTo(366.5, 487.3, 256.4, 489.9, 410.0, 280.0);
    expect(
        path5.getBounds(),
        within<Rect>(
            distance: 0.1,
            from: const Rect.fromLTRB(220.0, 280.0, 410.0, 439.0)));

    // control points inverted below wide
    final Path path6 = Path();
    path6.moveTo(220.0, 300.0);
    path6.cubicTo(496.1, 485.5, 121.4, 491.6, 410.0, 280.0);
    expect(
        path6.getBounds(),
        within<Rect>(
            distance: 0.1,
            from: const Rect.fromLTRB(220.0, 280.0, 410.0, 439.0)));

    // control point 2 and end point swapped
    final Path path7 = Path();
    path7.moveTo(220.0, 300.0);
    path7.cubicTo(230.0, 120.0, 394.5, 296.1, 382.3, 124.1);
    expect(
        path7.getBounds(),
        within<Rect>(
            distance: 0.1,
            from: const Rect.fromLTRB(220.0, 124.1, 382.9, 300.0)));
  });
}
