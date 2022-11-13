// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  test('MaterialThemeData copyWith, ==, hashCode basics', () {
    expect(const MaterialThemeData(), const MaterialThemeData().copyWith());
    expect(const MaterialThemeData().hashCode, const MaterialThemeData().copyWith().hashCode);
  });

  test('MaterialThemeData defaults', () {
    const MaterialThemeData themeData = MaterialThemeData();
    expect(themeData.color, null);
    expect(themeData.shadowColor, null);
  });

  test('MaterialThemeData default debugFillProperties', () async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const MaterialThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  test('MaterialThemeData implements debugFillProperties', () async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const MaterialThemeData(
      color: Color(0xfffffff0),
      shadowColor: Color(0xfffffff1),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'color: Color(0xfffffff0)',
      'shadowColor: Color(0xfffffff1)',
    ]);
  });

  test('MaterialThemeData copyWith', () {
    final MaterialThemeData theme = const MaterialThemeData().copyWith(
      color: Colors.black,
      shadowColor: Colors.green,
    );
    expect(theme.color, Colors.black);
    expect(theme.shadowColor, Colors.green);
  });
}