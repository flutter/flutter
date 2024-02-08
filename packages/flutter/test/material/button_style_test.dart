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

  test('ButtonStyle lerp special cases', () {
    expect(ButtonStyle.lerp(null, null, 0), null);
    const ButtonStyle data = ButtonStyle();
    expect(identical(ButtonStyle.lerp(data, data, 0.5), data), true);
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
    expect(style.iconColor, null);
    expect(style.iconSize, null);
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
      textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(fontSize: 10.0)),
      backgroundColor: WidgetStatePropertyAll<Color>(Color(0xfffffff1)),
      foregroundColor: WidgetStatePropertyAll<Color>(Color(0xfffffff2)),
      overlayColor: WidgetStatePropertyAll<Color>(Color(0xfffffff3)),
      shadowColor: WidgetStatePropertyAll<Color>(Color(0xfffffff4)),
      surfaceTintColor: WidgetStatePropertyAll<Color>(Color(0xfffffff5)),
      elevation: WidgetStatePropertyAll<double>(1.5),
      padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.all(1.0)),
      minimumSize: WidgetStatePropertyAll<Size>(Size(1.0, 2.0)),
      side: WidgetStatePropertyAll<BorderSide>(BorderSide(width: 4.0, color: Color(0xfffffff6))),
      maximumSize: WidgetStatePropertyAll<Size>(Size(100.0, 200.0)),
      iconColor: WidgetStatePropertyAll<Color>(Color(0xfffffff6)),
      iconSize: WidgetStatePropertyAll<double>(48.1),
      shape: WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
      mouseCursor: WidgetStatePropertyAll<MouseCursor>(SystemMouseCursors.forbidden),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      animationDuration: Duration(seconds: 1),
      enableFeedback: true,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[
      'textStyle: WidgetStatePropertyAll(TextStyle(inherit: true, size: 10.0))',
      'backgroundColor: WidgetStatePropertyAll(Color(0xfffffff1))',
      'foregroundColor: WidgetStatePropertyAll(Color(0xfffffff2))',
      'overlayColor: WidgetStatePropertyAll(Color(0xfffffff3))',
      'shadowColor: WidgetStatePropertyAll(Color(0xfffffff4))',
      'surfaceTintColor: WidgetStatePropertyAll(Color(0xfffffff5))',
      'elevation: WidgetStatePropertyAll(1.5)',
      'padding: WidgetStatePropertyAll(EdgeInsets.all(1.0))',
      'minimumSize: WidgetStatePropertyAll(Size(1.0, 2.0))',
      'maximumSize: WidgetStatePropertyAll(Size(100.0, 200.0))',
      'iconColor: WidgetStatePropertyAll(Color(0xfffffff6))',
      'iconSize: WidgetStatePropertyAll(48.1)',
      'side: WidgetStatePropertyAll(BorderSide(color: Color(0xfffffff6), width: 4.0))',
      'shape: WidgetStatePropertyAll(StadiumBorder(BorderSide(width: 0.0, style: none)))',
      'mouseCursor: WidgetStatePropertyAll(SystemMouseCursor(forbidden))',
      'tapTargetSize: shrinkWrap',
      'animationDuration: 0:00:01.000000',
      'enableFeedback: true',
    ]);
  });

  testWidgets('ButtonStyle copyWith, merge', (WidgetTester tester) async {
    const WidgetStateProperty<TextStyle> textStyle = WidgetStatePropertyAll<TextStyle>(TextStyle(fontSize: 10));
    const WidgetStateProperty<Color> backgroundColor = WidgetStatePropertyAll<Color>(Color(0xfffffff1));
    const WidgetStateProperty<Color> foregroundColor = WidgetStatePropertyAll<Color>(Color(0xfffffff2));
    const WidgetStateProperty<Color> overlayColor = WidgetStatePropertyAll<Color>(Color(0xfffffff3));
    const WidgetStateProperty<Color> shadowColor =  WidgetStatePropertyAll<Color>(Color(0xfffffff4));
    const WidgetStateProperty<Color> surfaceTintColor = WidgetStatePropertyAll<Color>(Color(0xfffffff5));
    const WidgetStateProperty<double> elevation = WidgetStatePropertyAll<double>(1);
    const WidgetStateProperty<EdgeInsets> padding = WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.all(1));
    const WidgetStateProperty<Size> minimumSize = WidgetStatePropertyAll<Size>(Size(1, 2));
    const WidgetStateProperty<Size> fixedSize = WidgetStatePropertyAll<Size>(Size(3, 4));
    const WidgetStateProperty<Size> maximumSize = WidgetStatePropertyAll<Size>(Size(5, 6));
    const WidgetStateProperty<Color> iconColor = WidgetStatePropertyAll<Color>(Color(0xfffffff6));
    const WidgetStateProperty<double> iconSize = WidgetStatePropertyAll<double>(48.0);
    const WidgetStateProperty<BorderSide> side = WidgetStatePropertyAll<BorderSide>(BorderSide());
    const WidgetStateProperty<OutlinedBorder> shape = WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder());
    const WidgetStateProperty<MouseCursor> mouseCursor = WidgetStatePropertyAll<MouseCursor>(SystemMouseCursors.forbidden);
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
      iconColor: iconColor,
      iconSize: iconSize,
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
        iconColor: iconColor,
        iconSize: iconSize,
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

    const ButtonStyle blackStyle = ButtonStyle(side: WidgetStatePropertyAll<BorderSide>(blackSide));
    const ButtonStyle whiteStyle = ButtonStyle(side: WidgetStatePropertyAll<BorderSide>(whiteSide));

    // WidgetState.all<Foo>(value) properties resolve to value
    // for any set of WidgetStates.
    const Set<WidgetState> states = <WidgetState>{ };

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
