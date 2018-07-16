// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TableBorder constructor', () {
    const TableBorder border1 = const TableBorder(
      left: const BorderSide(width: 1.0),
      right: const BorderSide(color: const Color(0xFF00FF00)),
      verticalInside: const BorderSide(),
    );
    expect(border1.top, BorderSide.none);
    expect(border1.right, const BorderSide(color: const Color(0xFF00FF00)));
    expect(border1.bottom, BorderSide.none);
    expect(border1.left, const BorderSide(width: 1.0));
    expect(border1.horizontalInside, BorderSide.none);
    expect(border1.verticalInside, const BorderSide(width: 1.0, color: const Color(0xFF000000)));
    expect(border1.dimensions, const EdgeInsets.symmetric(horizontal: 1.0));
    expect(border1.isUniform, isFalse);
    expect(border1.scale(2.0), const TableBorder(
      left: const BorderSide(width: 2.0),
      right: const BorderSide(width: 2.0, color: const Color(0xFF00FF00)),
      verticalInside: const BorderSide(width: 2.0),
    ));
  });

  test('TableBorder.all constructor', () {
    final TableBorder border2 = new TableBorder.all(
      width: 2.0,
      color: const Color(0xFF00FFFF),
    );
    expect(border2.top, const BorderSide(width: 2.0, color: const Color(0xFF00FFFF)));
    expect(border2.right, const BorderSide(width: 2.0, color: const Color(0xFF00FFFF)));
    expect(border2.bottom, const BorderSide(width: 2.0, color: const Color(0xFF00FFFF)));
    expect(border2.left, const BorderSide(width: 2.0, color: const Color(0xFF00FFFF)));
    expect(border2.horizontalInside, const BorderSide(width: 2.0, color: const Color(0xFF00FFFF)));
    expect(border2.verticalInside, const BorderSide(width: 2.0, color: const Color(0xFF00FFFF)));
    expect(border2.dimensions, const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0));
    expect(border2.isUniform, isTrue);
    expect(border2.scale(0.5), new TableBorder.all(color: const Color(0xFF00FFFF)));
  });

  test('TableBorder.symmetric constructor', () {
    final TableBorder border3 = new TableBorder.symmetric(
      inside: const BorderSide(width: 3.0),
      outside: const BorderSide(color: const Color(0xFFFF0000)),
    );
    expect(border3.top, const BorderSide(color: const Color(0xFFFF0000)));
    expect(border3.right, const BorderSide(color: const Color(0xFFFF0000)));
    expect(border3.bottom, const BorderSide(color: const Color(0xFFFF0000)));
    expect(border3.left, const BorderSide(color: const Color(0xFFFF0000)));
    expect(border3.horizontalInside, const BorderSide(width: 3.0));
    expect(border3.verticalInside, const BorderSide(width: 3.0));
    expect(border3.dimensions, const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0));
    expect(border3.isUniform, isFalse);
    expect(border3.scale(0.0), new TableBorder.symmetric(
      inside: const BorderSide(width: 0.0, style: BorderStyle.none),
      outside: const BorderSide(width: 0.0, color: const Color(0xFFFF0000), style: BorderStyle.none),
    ));
  });

  test('TableBorder.lerp', () {
    const BorderSide side1 = const BorderSide(width: 1.0, color: const Color(1));
    const BorderSide side2 = const BorderSide(width: 2.0, color: const Color(2));
    const BorderSide side3 = const BorderSide(width: 3.0, color: const Color(3));
    const BorderSide side4 = const BorderSide(width: 4.0, color: const Color(4));
    const BorderSide side5 = const BorderSide(width: 5.0, color: const Color(5));
    const BorderSide side6 = const BorderSide(width: 6.0, color: const Color(6));
    const TableBorder tableA = const TableBorder(
      top: side1,
      right: side2,
      bottom: side3,
      left: side4,
      horizontalInside: side5,
      verticalInside: side6,
    );
    expect(tableA.isUniform, isFalse);
    expect(tableA.dimensions, const EdgeInsets.fromLTRB(4.0, 1.0, 2.0, 3.0));
    final TableBorder tableB = new TableBorder(
      top: side1.scale(2.0),
      right: side2.scale(2.0),
      bottom: side3.scale(2.0),
      left: side4.scale(2.0),
      horizontalInside: side5.scale(2.0),
      verticalInside: side6.scale(2.0),
    );
    expect(tableB.isUniform, isFalse);
    expect(tableB.dimensions, const EdgeInsets.fromLTRB(4.0, 1.0, 2.0, 3.0) * 2.0);
    final TableBorder tableC = new TableBorder(
      top: side1.scale(3.0),
      right: side2.scale(3.0),
      bottom: side3.scale(3.0),
      left: side4.scale(3.0),
      horizontalInside: side5.scale(3.0),
      verticalInside: side6.scale(3.0),
    );
    expect(tableC.isUniform, isFalse);
    expect(tableC.dimensions, const EdgeInsets.fromLTRB(4.0, 1.0, 2.0, 3.0) * 3.0);
    expect(TableBorder.lerp(tableA, tableC, 0.5), tableB);
    expect(TableBorder.lerp(tableA, tableB, 2.0), tableC);
    expect(TableBorder.lerp(tableB, tableC, -1.0), tableA);
    expect(TableBorder.lerp(tableA, tableC, 0.9195).isUniform, isFalse);
    expect(TableBorder.lerp(tableA, tableC, 0.9195).dimensions,
           EdgeInsets.lerp(tableA.dimensions, tableC.dimensions, 0.9195));
  });

  test('TableBorder.lerp with nulls', () {
    final TableBorder table2 = new TableBorder.all(width: 2.0);
    final TableBorder table1 = new TableBorder.all(width: 1.0);
    expect(TableBorder.lerp(table2, null, 0.5), table1);
    expect(TableBorder.lerp(null, table2, 0.5), table1);
    expect(TableBorder.lerp(null, null, 0.5), null);
  });

  test('TableBorder Object API', () {
    expect(const TableBorder(), isNot(1.0));
    expect(const TableBorder().hashCode, isNot(const TableBorder(top: const BorderSide(width: 0.0)).hashCode));
  });

  test('TableBorder Object API', () {
    final String none = BorderSide.none.toString();
    expect(const TableBorder().toString(), 'TableBorder($none, $none, $none, $none, $none, $none)');
  });
}
