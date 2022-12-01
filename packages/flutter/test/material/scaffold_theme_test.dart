// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  test('ScaffoldThemeData copyWith, ==, hashCode basics', () {
    expect(const ScaffoldThemeData(), const ScaffoldThemeData().copyWith());
    expect(const ScaffoldThemeData().hashCode, const ScaffoldThemeData().copyWith().hashCode);
  });

  test('ScaffoldThemeData defaults', () {
    const ScaffoldThemeData themeData = ScaffoldThemeData();
    expect(themeData.backgroundColor, null);
    expect(themeData.drawerScrimColor, null);
  });

  test('ScaffoldThemeData default debugFillProperties', () async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ScaffoldThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  test('ScaffoldThemeData implements debugFillProperties', () async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ScaffoldThemeData(
      backgroundColor: Color(0xfffffff0),
      drawerScrimColor: Color(0xfffffff1),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'backgroundColor: Color(0xfffffff0)',
      'drawerScrimColor: Color(0xfffffff1)',
    ]);
  });

  test('ScaffoldThemeData copyWith', () {
    final ScaffoldThemeData theme = const ScaffoldThemeData().copyWith(
      backgroundColor: Colors.black,
      drawerScrimColor: Colors.green,
    );
    expect(theme.backgroundColor, Colors.black);
    expect(theme.drawerScrimColor, Colors.green);
  });
}
