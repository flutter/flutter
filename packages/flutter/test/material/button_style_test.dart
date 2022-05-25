// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ButtonStyle copyWith, merge, ==, hashCode basics', () {
    expect(const ButtonStyle(), const ButtonStyle().copyWith());
    expect(const ButtonStyle().merge(const ButtonStyle()), const ButtonStyle());
    expect(const ButtonStyle().hashCode, const ButtonStyle().copyWith().hashCode);
  });

  test('ButtonStyle defaults', () {
    const ButtonStyle style = ButtonStyle();
    expect(style.textStyle, null);
    expect(style.backgroundColor, null);
    expect(style.foregroundColor, null);
    expect(style.overlayColor, null);
    expect(style.shadowColor, null);
    expect(style.surfaceTintColor, null);
    expect(style.elevation, null);
    expect(style.padding, null);
    expect(style.minimumSize, null);
    expect(style.fixedSize, null);
    expect(style.maximumSize, null);
    expect(style.side, null);
    expect(style.shape, null);
    expect(style.mouseCursor, null);
    expect(style.visualDensity, null);
    expect(style.tapTargetSize, null);
    expect(style.animationDuration, null);
    expect(style.enableFeedback, null);
  });

  testWidgets('Default ButtonStyle debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ButtonStyle().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  testWidgets('ButtonStyle debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ButtonStyle(
      textStyle: MaterialStatePropertyAll<TextStyle>(TextStyle(fontSize: 10.0)),
      backgroundColor: MaterialStatePropertyAll<Color>(Color(0xfffffff1)),
      foregroundColor: MaterialStatePropertyAll<Color>(Color(0xfffffff2)),
      overlayColor: MaterialStatePropertyAll<Color>(Color(0xfffffff3)),
      shadowColor: MaterialStatePropertyAll<Color>(Color(0xfffffff4)),
      surfaceTintColor: MaterialStatePropertyAll<Color>(Color(0xfffffff5)),
      elevation: MaterialStatePropertyAll<double>(1.5),
      padding: MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.all(1.0)),
      minimumSize: MaterialStatePropertyAll<Size>(Size(1.0, 2.0)),
      side: MaterialStatePropertyAll<BorderSide>(BorderSide(width: 4.0, color: Color(0xfffffff6))),
      maximumSize: MaterialStatePropertyAll<Size>(Size(100.0, 200.0)),
      shape: MaterialStatePropertyAll<OutlinedBorder>(StadiumBorder()),
      mouseCursor: MaterialStatePropertyAll<MouseCursor>(SystemMouseCursors.forbidden),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      animationDuration: Duration(seconds: 1),
      enableFeedback: true,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[
      'textStyle: MaterialStatePropertyAll(TextStyle(inherit: true, size: 10.0))',
      'backgroundColor: MaterialStatePropertyAll(Color(0xfffffff1))',
      'foregroundColor: MaterialStatePropertyAll(Color(0xfffffff2))',
      'overlayColor: MaterialStatePropertyAll(Color(0xfffffff3))',
      'shadowColor: MaterialStatePropertyAll(Color(0xfffffff4))',
      'surfaceTintColor: MaterialStatePropertyAll(Color(0xfffffff5))',
      'elevation: MaterialStatePropertyAll(1.5)',
      'padding: MaterialStatePropertyAll(EdgeInsets.all(1.0))',
      'minimumSize: MaterialStatePropertyAll(Size(1.0, 2.0))',
      'maximumSize: MaterialStatePropertyAll(Size(100.0, 200.0))',
      'side: MaterialStatePropertyAll(BorderSide(Color(0xfffffff6), 4.0, BorderStyle.solid))',
      'shape: MaterialStatePropertyAll(StadiumBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none)))',
      'mouseCursor: MaterialStatePropertyAll(SystemMouseCursor(forbidden))',
      'tapTargetSize: shrinkWrap',
      'animationDuration: 0:00:01.000000',
      'enableFeedback: true',
    ]);
  });

  testWidgets('ButtonStyle copyWith, merge', (WidgetTester tester) async {
    const MaterialStateProperty<TextStyle> textStyle = MaterialStatePropertyAll<TextStyle>(TextStyle(fontSize: 10));
    const MaterialStateProperty<Color> backgroundColor = MaterialStatePropertyAll<Color>(Color(0xfffffff1));
    const MaterialStateProperty<Color> foregroundColor = MaterialStatePropertyAll<Color>(Color(0xfffffff2));
    const MaterialStateProperty<Color> overlayColor = MaterialStatePropertyAll<Color>(Color(0xfffffff3));
    const MaterialStateProperty<Color> shadowColor =  MaterialStatePropertyAll<Color>(Color(0xfffffff4));
    const MaterialStateProperty<Color> surfaceTintColor = MaterialStatePropertyAll<Color>(Color(0xfffffff5));
    const MaterialStateProperty<double> elevation = MaterialStatePropertyAll<double>(1);
    const MaterialStateProperty<EdgeInsets> padding = MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.all(1));
    const MaterialStateProperty<Size> minimumSize = MaterialStatePropertyAll<Size>(Size(1, 2));
    const MaterialStateProperty<Size> fixedSize = MaterialStatePropertyAll<Size>(Size(3, 4));
    const MaterialStateProperty<Size> maximumSize = MaterialStatePropertyAll<Size>(Size(5, 6));
    const MaterialStateProperty<BorderSide> side = MaterialStatePropertyAll<BorderSide>(BorderSide());
    const MaterialStateProperty<OutlinedBorder> shape = MaterialStatePropertyAll<OutlinedBorder>(StadiumBorder());
    const MaterialStateProperty<MouseCursor> mouseCursor = MaterialStatePropertyAll<MouseCursor>(SystemMouseCursors.forbidden);
    const VisualDensity visualDensity = VisualDensity.compact;
    const MaterialTapTargetSize tapTargetSize = MaterialTapTargetSize.shrinkWrap;
    const Duration animationDuration = Duration(seconds: 1);
    const bool enableFeedback = true;

    const ButtonStyle style = ButtonStyle(
      textStyle: textStyle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      overlayColor: overlayColor,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      elevation: elevation,
      padding: padding,
      minimumSize: minimumSize,
      fixedSize: fixedSize,
      maximumSize: maximumSize,
      side: side,
      shape: shape,
      mouseCursor: mouseCursor,
      visualDensity: visualDensity,
      tapTargetSize: tapTargetSize,
      animationDuration: animationDuration,
      enableFeedback: enableFeedback,
    );

    expect(
      style,
      const ButtonStyle().copyWith(
        textStyle: textStyle,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        overlayColor: overlayColor,
        shadowColor: shadowColor,
        surfaceTintColor: surfaceTintColor,
        elevation: elevation,
        padding: padding,
        minimumSize: minimumSize,
        fixedSize: fixedSize,
        maximumSize: maximumSize,
        side: side,
        shape: shape,
        mouseCursor: mouseCursor,
        visualDensity: visualDensity,
        tapTargetSize: tapTargetSize,
        animationDuration: animationDuration,
        enableFeedback: enableFeedback,
      ),
    );

    expect(
      style,
      const ButtonStyle().merge(style),
    );

    expect(
      style.copyWith(),
      style.merge(const ButtonStyle()),
    );
  });

  test('ButtonStyle.lerp BorderSide', () {
    // This is regression test for https://github.com/flutter/flutter/pull/78051
    expect(ButtonStyle.lerp(null, null, 0), null);
    expect(ButtonStyle.lerp(null, null, 0.5), null);
    expect(ButtonStyle.lerp(null, null, 1), null);

    const BorderSide blackSide = BorderSide();
    const BorderSide whiteSide = BorderSide(color: Color(0xFFFFFFFF));
    const BorderSide emptyBlackSide = BorderSide(width: 0, color: Color(0x00000000));

    const ButtonStyle blackStyle = ButtonStyle(side: MaterialStatePropertyAll<BorderSide>(blackSide));
    const ButtonStyle whiteStyle = ButtonStyle(side: MaterialStatePropertyAll<BorderSide>(whiteSide));

    // MaterialState.all<Foo>(value) properties resolve to value
    // for any set of MaterialStates.
    const Set<MaterialState> states = <MaterialState>{ };

    expect(ButtonStyle.lerp(blackStyle, blackStyle, 0)?.side?.resolve(states), blackSide);
    expect(ButtonStyle.lerp(blackStyle, blackStyle, 0.5)?.side?.resolve(states), blackSide);
    expect(ButtonStyle.lerp(blackStyle, blackStyle, 1)?.side?.resolve(states), blackSide);

    expect(ButtonStyle.lerp(blackStyle, null, 0)?.side?.resolve(states), blackSide);
    expect(ButtonStyle.lerp(blackStyle, null, 0.5)?.side?.resolve(states), BorderSide.lerp(blackSide, emptyBlackSide, 0.5));
    expect(ButtonStyle.lerp(blackStyle, null, 1)?.side?.resolve(states), emptyBlackSide);

    expect(ButtonStyle.lerp(null, blackStyle, 0)?.side?.resolve(states), emptyBlackSide);
    expect(ButtonStyle.lerp(null, blackStyle, 0.5)?.side?.resolve(states), BorderSide.lerp(emptyBlackSide, blackSide, 0.5));
    expect(ButtonStyle.lerp(null, blackStyle, 1)?.side?.resolve(states), blackSide);

    expect(ButtonStyle.lerp(blackStyle, whiteStyle, 0)?.side?.resolve(states), blackSide);
    expect(ButtonStyle.lerp(blackStyle, whiteStyle, 0.5)?.side?.resolve(states), BorderSide.lerp(blackSide, whiteSide, 0.5));
    expect(ButtonStyle.lerp(blackStyle, whiteStyle, 1)?.side?.resolve(states), whiteSide);
  });
}
