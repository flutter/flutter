// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

Widget buildInputDecorator({
  InputDecoration decoration = const InputDecoration(),
  InputDecorationTheme inputDecorationTheme,
  TextDirection textDirection = TextDirection.ltr,
  bool isEmpty = false,
  bool isFocused = false,
  TextStyle baseStyle,
  Widget child = const Text(
    'text',
    style: TextStyle(fontFamily: 'Ahem', fontSize: 16.0),
  ),
}) {
  return MaterialApp(
    home: Material(
      child: Builder(
        builder: (BuildContext context) {
          return Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: inputDecorationTheme,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Directionality(
                textDirection: textDirection,
                child: InputDecorator(
                  decoration: decoration,
                  isEmpty: isEmpty,
                  isFocused: isFocused,
                  baseStyle: baseStyle,
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

Finder findBorderPainter() {
  return find.descendant(
    of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_BorderContainer'),
    matching: find.byWidgetPredicate((Widget w) => w is CustomPaint),
  );
}

double getBorderBottom(WidgetTester tester) {
  final RenderBox box = InputDecorator.containerOf(tester.element(findBorderPainter()));
  return box.size.height;
}

InputBorder getBorder(WidgetTester tester) {
  if (!tester.any(findBorderPainter()))
    return null;
  final CustomPaint customPaint = tester.widget(findBorderPainter());
  final dynamic/*_InputBorderPainter*/ inputBorderPainter = customPaint.foregroundPainter;
  final dynamic/*_InputBorderTween*/ inputBorderTween = inputBorderPainter.border;
  final Animation<double> animation = inputBorderPainter.borderAnimation;
  final dynamic/*_InputBorder*/ border = inputBorderTween.evaluate(animation);
  return border;
}

BorderSide getBorderSide(WidgetTester tester) {
  return getBorder(tester)?.borderSide;
}

BorderRadius getBorderRadius(WidgetTester tester) {
  final InputBorder border = getBorder(tester);
  if (border is UnderlineInputBorder) {
    return border.borderRadius;
  }
  return null;
}

double getBorderWeight(WidgetTester tester) => getBorderSide(tester)?.width;

Color getBorderColor(WidgetTester tester) => getBorderSide(tester)?.color;

double getOpacity(WidgetTester tester, String textValue) {
  final FadeTransition opacityWidget = tester.widget<FadeTransition>(
    find.ancestor(
      of: find.text(textValue),
      matching: find.byType(FadeTransition),
    ).first
  );
  return opacityWidget.opacity.value;
}

void main() {
  testWidgets('InputDecorator input/label layout', (WidgetTester tester) async {
    // The label appears above the input text
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
        ),
      ),
    );

    // Overall height for this InputDecorator is 56dps:
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);

    // isFocused: true increases the border's weight from 1.0 to 2.0
    // but does not change the overall height.
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        isFocused: true,
        decoration: const InputDecoration(
          labelText: 'label',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 2.0);

    // isEmpty: true causes the label to be aligned with the input text
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: false,
        decoration: const InputDecoration(
          labelText: 'label',
        ),
      ),
    );

    // The label animates downwards from it's initial position
    // above the input text. The animation's duration is 200ms.
    {
      await tester.pump(const Duration(milliseconds: 50));
      final double labelY50ms = tester.getTopLeft(find.text('label')).dy;
      expect(labelY50ms, inExclusiveRange(12.0, 20.0));
      await tester.pump(const Duration(milliseconds: 50));
      final double labelY100ms = tester.getTopLeft(find.text('label')).dy;
      expect(labelY100ms, inExclusiveRange(labelY50ms, 20.0));
    }
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);

    // isFocused: true causes the label to move back up above the input text.
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: true,
        decoration: const InputDecoration(
          labelText: 'label',
        ),
      ),
    );

    // The label animates upwards from it's initial position
    // above the input text. The animation's duration is 200ms.
    {
      await tester.pump(const Duration(milliseconds: 50));
      final double labelY50ms = tester.getTopLeft(find.text('label')).dy;
      expect(labelY50ms, inExclusiveRange(12.0, 28.0));
      await tester.pump(const Duration(milliseconds: 50));
      final double labelY100ms = tester.getTopLeft(find.text('label')).dy;
      expect(labelY100ms, inExclusiveRange(12.0, labelY50ms));
    }

    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 2.0);

    // enabled: false produces a hairline border if filled: false (the default)
    // The widget's size and layout is the same as for enabled: true.
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: false,
        decoration: const InputDecoration(
          labelText: 'label',
          enabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderWeight(tester), 0.0);

    // enabled: false produces a transparent border if filled: true.
    // The widget's size and layout is the same as for enabled: true.
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: false,
        decoration: const InputDecoration(
          labelText: 'label',
          enabled: false,
          filled: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderColor(tester), Colors.transparent);
  });

  // Overall height for this InputDecorator is 40.0dps
  //   12 - top padding
  //   16 - input text (ahem font size 16dps)
  //   12 - bottom padding
  testWidgets('InputDecorator input/hint layout', (WidgetTester tester) async {
    // The hint aligns with the input text
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          hintText: 'hint',
        ),
      ),
    );

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 40.0));
    expect(tester.getTopLeft(find.text('text')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 28.0);
    expect(tester.getTopLeft(find.text('hint')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('hint')).dy, 28.0);
    expect(getBorderBottom(tester), 40.0);
    expect(getBorderWeight(tester), 1.0);

    expect(tester.getSize(find.text('hint')).width, tester.getSize(find.text('text')).width);
  });

  testWidgets('InputDecorator input/label/hint layout', (WidgetTester tester) async {
    // Label is visible, hint is not (opacity 0.0).
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
        ),
      ),
    );

    // Overall height for this InputDecorator is 56dps. When the
    // label is "floating" (empty input or no focus) the layout is:
    //
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding
    //
    // When the label is not floating, it's vertically centered.
    //
    //   20 - top padding
    //   16 - label (ahem font size 16dps)
    //   20 - bottom padding (empty input text still appears here)


    // The label is not floating so it's vertically centered.
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getOpacity(tester, 'hint'), 0.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);

    // Label moves upwards, hint is visible (opacity 1.0).
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: true,
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
        ),
      ),
    );

    // The hint's opacity animates from 0.0 to 1.0.
    // The animation's duration is 200ms.
    {
      await tester.pump(const Duration(milliseconds: 50));
      final double hintOpacity50ms = getOpacity(tester, 'hint');
      expect(hintOpacity50ms, inExclusiveRange(0.0, 1.0));
      await tester.pump(const Duration(milliseconds: 50));
      final double hintOpacity100ms = getOpacity(tester, 'hint');
      expect(hintOpacity100ms, inExclusiveRange(hintOpacity50ms, 1.0));
    }

    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(tester.getTopLeft(find.text('hint')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('hint')).dy, 44.0);
    expect(getOpacity(tester, 'hint'), 1.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 2.0);

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: false,
        isFocused: true,
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
        ),
      ),
    );

    // The hint's opacity animates from 1.0 to 0.0.
    // The animation's duration is 200ms.
    {
      await tester.pump(const Duration(milliseconds: 50));
      final double hintOpacity50ms = getOpacity(tester, 'hint');
      expect(hintOpacity50ms, inExclusiveRange(0.0, 1.0));
      await tester.pump(const Duration(milliseconds: 50));
      final double hintOpacity100ms = getOpacity(tester, 'hint');
      expect(hintOpacity100ms, inExclusiveRange(0.0, hintOpacity50ms));
    }

    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(tester.getTopLeft(find.text('hint')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('hint')).dy, 44.0);
    expect(getOpacity(tester, 'hint'), 0.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 2.0);
  });

  testWidgets('InputDecorator input/label/hint dense layout', (WidgetTester tester) async {
    // Label is visible, hint is not (opacity 0.0).
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
          isDense: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 48dps. When the
    // label is "floating" (empty input or no focus) the layout is:
    //
    //    8 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //    8 - bottom padding
    //
    // When the label is not floating, it's vertically centered.
    //
    //   16 - top padding
    //   16 - label (ahem font size 16dps)
    //   16 - bottom padding (empty input text still appears here)

    // The label is not floating so it's vertically centered.
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 48.0));
    expect(tester.getTopLeft(find.text('text')).dy, 24.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 40.0);
    expect(tester.getTopLeft(find.text('label')).dy, 16.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 32.0);
    expect(getOpacity(tester, 'hint'), 0.0);
    expect(getBorderBottom(tester), 48.0);
    expect(getBorderWeight(tester), 1.0);

    // Label is visible, hint is not (opacity 0.0).
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: true,
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
          isDense: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 48.0));
    expect(tester.getTopLeft(find.text('text')).dy, 24.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 40.0);
    expect(tester.getTopLeft(find.text('label')).dy, 8.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 20.0);
    expect(getOpacity(tester, 'hint'), 1.0);
    expect(getBorderBottom(tester), 48.0);
    expect(getBorderWeight(tester), 2.0);
  });

  testWidgets('InputDecorator with no input border', (WidgetTester tester) async {
    // Label is visible, hint is not (opacity 0.0).
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
      ),
    );
    expect(getBorderWeight(tester), 0.0);
  });

  testWidgets('InputDecorator error/helper/counter layout', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: 'helper',
          counterText: 'counter',
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 76dps. When the label is
    // floating the layout is:
    //
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding
    //    8 - below the border padding
    //   12 - help/error/counter text (ahem font size 12dps)
    //
    // When the label is not floating, it's vertically centered in the space
    // above the subtext:
    //
    //   20 - top padding
    //   16 - label (ahem font size 16dps)
    //   20 - bottom padding (empty input text still appears here)
    //    8 - below the border padding
    //   12 - help/error/counter text (ahem font size 12dps)

    // isEmpty: true, the label is not floating
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 76.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);
    expect(tester.getTopLeft(find.text('helper')), const Offset(12.0, 64.0));
    expect(tester.getTopRight(find.text('counter')), const Offset(788.0, 64.0));

    // If errorText is specified then the helperText isn't shown
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          errorText: 'error',
          helperText: 'helper',
          counterText: 'counter',
          filled: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // isEmpty: false, the label _is_ floating
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 76.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);
    expect(tester.getTopLeft(find.text('error')), const Offset(12.0, 64.0));
    expect(tester.getTopRight(find.text('counter')), const Offset(788.0, 64.0));
    expect(find.text('helper'), findsNothing);

    // Overall height for this dense layout InputDecorator is 68dps. When the
    // label is floating the layout is:
    //
    //    8 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //    8 - bottom padding
    //    8 - below the border padding
    //   12 - help/error/counter text (ahem font size 12dps)
    //
    // When the label is not floating, it's vertically centered in the space
    // above the subtext:
    //
    //   16 - top padding
    //   16 - label (ahem font size 16dps)
    //   16 - bottom padding (empty input text still appears here)
    //    8 - below the border padding
    //   12 - help/error/counter text (ahem font size 12dps)
    // The layout of the error/helper/counter subtext doesn't change for dense layout.
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          isDense: true,
          labelText: 'label',
          errorText: 'error',
          helperText: 'helper',
          counterText: 'counter',
          filled: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // isEmpty: false, the label _is_ floating
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 68.0));
    expect(tester.getTopLeft(find.text('text')).dy, 24.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 40.0);
    expect(tester.getTopLeft(find.text('label')).dy, 8.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 20.0);
    expect(getBorderBottom(tester), 48.0);
    expect(getBorderWeight(tester), 1.0);
    expect(tester.getTopLeft(find.text('error')), const Offset(12.0, 56.0));
    expect(tester.getTopRight(find.text('counter')), const Offset(788.0, 56.0));

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          isDense: true,
          labelText: 'label',
          errorText: 'error',
          helperText: 'helper',
          counterText: 'counter',
          filled: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // isEmpty: false, the label is not floating
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 68.0));
    expect(tester.getTopLeft(find.text('text')).dy, 24.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 40.0);
    expect(tester.getTopLeft(find.text('label')).dy, 16.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 32.0);
    expect(getBorderBottom(tester), 48.0);
    expect(getBorderWeight(tester), 1.0);
    expect(tester.getTopLeft(find.text('error')), const Offset(12.0, 56.0));
    expect(tester.getTopRight(find.text('counter')), const Offset(788.0, 56.0));
  });

  testWidgets('InputDecoration errorMaxLines', (WidgetTester tester) async {
    const String kError1 = 'e0';
    const String kError2 = 'e0\ne1';
    const String kError3 = 'e0\ne1\ne2';

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: 'helper',
          errorText: kError3,
          errorMaxLines: 3,
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 100dps:
    //
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding
    //    8 - below the border padding
    //   36 - error text (3 lines, ahem font size 12dps)

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 100.0));
    expect(tester.getTopLeft(find.text(kError3)), const Offset(12.0, 64.0));
    expect(tester.getBottomLeft(find.text(kError3)), const Offset(12.0, 100.0));

    // Overall height for this InputDecorator is 12 less than the first
    // one, 88dps, because errorText only occupies two lines.

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: 'helper',
          errorText: kError2,
          errorMaxLines: 3,
          filled: true,
        ),
      ),
    );

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 88.0));
    expect(tester.getTopLeft(find.text(kError2)), const Offset(12.0, 64.0));
    expect(tester.getBottomLeft(find.text(kError2)), const Offset(12.0, 88.0));

    // Overall height for this InputDecorator is 24 less than the first
    // one, 88dps, because errorText only occupies one line.

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: 'helper',
          errorText: kError1,
          errorMaxLines: 3,
          filled: true,
        ),
      ),
    );

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 76.0));
    expect(tester.getTopLeft(find.text(kError1)), const Offset(12.0, 64.0));
    expect(tester.getBottomLeft(find.text(kError1)), const Offset(12.0, 76.0));
  });

  testWidgets('InputDecorator prefix/suffix texts', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          prefixText: 'p',
          suffixText: 's',
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 40dps:
    //   12 - top padding
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding
    //
    // The prefix and suffix wrap the input text and are left and right justified
    // respectively. They should have the same height as the input text (16).

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 40.0));
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getSize(find.text('p')).height, 16.0);
    expect(tester.getSize(find.text('s')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 12.0);
    expect(tester.getTopLeft(find.text('p')).dy, 12.0);
    expect(tester.getTopLeft(find.text('p')).dx, 12.0);
    expect(tester.getTopLeft(find.text('s')).dy, 12.0);
    expect(tester.getTopRight(find.text('s')).dx, 788.0);

    // layout is a row: [p text s]
    expect(tester.getTopLeft(find.text('p')).dx, 12.0);
    expect(tester.getTopRight(find.text('p')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('text')).dx));
    expect(tester.getTopRight(find.text('text')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('s')).dx));
  });

  testWidgets('InputDecorator icon/prefix/suffix', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          prefixText: 'p',
          suffixText: 's',
          icon: Icon(Icons.android),
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 40dps:
    //   12 - top padding
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 40.0));
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getSize(find.text('p')).height, 16.0);
    expect(tester.getSize(find.text('s')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 12.0);
    expect(tester.getTopLeft(find.text('p')).dy, 12.0);
    expect(tester.getTopLeft(find.text('s')).dy, 12.0);
    expect(tester.getTopRight(find.text('s')).dx, 788.0);
    expect(tester.getSize(find.byType(Icon)).height, 24.0);

    // The 24dps high icon is centered on the 16dps high input line
    expect(tester.getTopLeft(find.byType(Icon)).dy, 8.0);

    // layout is a row: [icon, p text s]
    expect(tester.getTopLeft(find.byType(Icon)).dx, 0.0);
    expect(tester.getTopRight(find.byType(Icon)).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('p')).dx));
    expect(tester.getTopRight(find.text('p')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('text')).dx));
    expect(tester.getTopRight(find.text('text')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('s')).dx));
  });

  testWidgets('InputDecorator prefix/suffix widgets', (WidgetTester tester) async {
    const Key pKey = Key('p');
    const Key sKey = Key('s');
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          prefix: Padding(
            key: pKey,
            padding: EdgeInsets.all(4.0),
            child: Text('p'),
          ),
          suffix: Padding(
            key: sKey,
            padding: EdgeInsets.all(4.0),
            child: Text('s'),
          ),
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 48dps because
    // the prefix and the suffix widget is surrounded with padding:
    //   12 - top padding
    //    4 - top prefix/suffix padding
    //   16 - input text (ahem font size 16dps)
    //    4 - bottom prefix/suffix padding
    //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 48.0));
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getSize(find.byKey(pKey)).height, 24.0);
    expect(tester.getSize(find.text('p')).height, 16.0);
    expect(tester.getSize(find.byKey(sKey)).height, 24.0);
    expect(tester.getSize(find.text('s')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 16.0);
    expect(tester.getTopLeft(find.byKey(pKey)).dy, 12.0);
    expect(tester.getTopLeft(find.text('p')).dy, 16.0);
    expect(tester.getTopLeft(find.byKey(sKey)).dy, 12.0);
    expect(tester.getTopLeft(find.text('s')).dy, 16.0);
    expect(tester.getTopRight(find.byKey(sKey)).dx, 788.0);
    expect(tester.getTopRight(find.text('s')).dx, 784.0);

    // layout is a row: [prefix text suffix]
    expect(tester.getTopLeft(find.byKey(pKey)).dx, 12.0);
    expect(tester.getTopRight(find.byKey(pKey)).dx, tester.getTopLeft(find.text('text')).dx);
    expect(tester.getTopRight(find.text('text')).dx, lessThanOrEqualTo(tester.getTopRight(find.byKey(sKey)).dx));
  });

  testWidgets('InputDecorator prefixIcon/suffixIcon', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.pages),
          suffixIcon: Icon(Icons.satellite),
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 48dps because the prefix icon's minimum size
    // is 48x48 and the rest of the elements only require 40dps:
     //   12 - top padding
     //   16 - input text (ahem font size 16dps)
     //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 48.0));
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getSize(find.byIcon(Icons.pages)).height, 48.0);
    expect(tester.getSize(find.byIcon(Icons.satellite)).height, 48.0);
    expect(tester.getTopLeft(find.text('text')).dy, 12.0);
    expect(tester.getTopLeft(find.byIcon(Icons.pages)).dy, 0.0);
    expect(tester.getTopLeft(find.byIcon(Icons.satellite)).dy, 0.0);
    expect(tester.getTopRight(find.byIcon(Icons.satellite)).dx, 800.0);


    // layout is a row: [icon text icon]
    expect(tester.getTopLeft(find.byIcon(Icons.pages)).dx, 0.0);
    expect(tester.getTopRight(find.byIcon(Icons.pages)).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('text')).dx));
    expect(tester.getTopRight(find.text('text')).dx, lessThanOrEqualTo(tester.getTopLeft(find.byIcon(Icons.satellite)).dx));
  });

  testWidgets('prefix/suffix icons are centered when smaller than 48 by 48', (WidgetTester tester) async {
    const Key prefixKey = Key('prefix');
    await tester.pumpWidget(
      buildInputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(width: 8.0, height: 8.0, key: prefixKey),
          ),
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 48dps because the prefix icon's minimum size
     // is 48x48 and the rest of the elements only require 40dps:
     //   12 - top padding
     //   16 - input text (ahem font size 16dps)
     //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 48.0));
    expect(tester.getSize(find.byKey(prefixKey)).height, 16.0);
    expect(tester.getTopLeft(find.byKey(prefixKey)).dy, 16.0);
  });

  testWidgets('prefix/suffix icons increase height of decoration when larger than 48 by 48', (WidgetTester tester) async {
    const Key prefixKey = Key('prefix');
    await tester.pumpWidget(
      buildInputDecorator(
        decoration: const InputDecoration(
          prefixIcon: SizedBox(width: 100.0, height: 100.0, key: prefixKey),
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 100dps because the prefix icon's  size
    // is 100x100 and the rest of the elements only require 40dps:
     //   12 - top padding
     //   16 - input text (ahem font size 16dps)
     //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 100.0));
    expect(tester.getSize(find.byKey(prefixKey)).height, 100.0);
    expect(tester.getTopLeft(find.byKey(prefixKey)).dy, 0.0);
  });


  testWidgets('counter text has correct right margin - LTR, not dense', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          counterText: 'test',
          filled: true,
        ),
      ),
    );

    // Margin for text decoration is 12 when filled
    // (dx) - 12 = (text offset)x.
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 60.0));
    final double dx = tester.getRect(find.byType(InputDecorator)).right;
    expect(tester.getRect(find.text('test')).right, dx - 12.0);
  });

  testWidgets('counter text has correct right margin - RTL, not dense', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        textDirection: TextDirection.rtl,
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          counterText: 'test',
          filled: true,
        ),
      ),
    );

    // Margin for text decoration is 12 when filled and top left offset is (0, 0)
    // 0 + 12 = 12.
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 60.0));
    expect(tester.getRect(find.text('test')).left, 12.0);
  });

    testWidgets('counter text has correct right margin - LTR, dense', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          counterText: 'test',
          filled: true,
          isDense: true,
        ),
      ),
    );

    // Margin for text decoration is 12 when filled
    // (dx) - 12 = (text offset)x.
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 52.0));
    final double dx = tester.getRect(find.byType(InputDecorator)).right;
    expect(tester.getRect(find.text('test')).right, dx - 12.0);
  });

  testWidgets('counter text has correct right margin - RTL, dense', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        textDirection: TextDirection.rtl,
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          counterText: 'test',
          filled: true,
          isDense: true,
        ),
      ),
    );

    // Margin for text decoration is 12 when filled and top left offset is (0, 0)
    // 0 + 12 = 12.
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 52.0));
    expect(tester.getRect(find.text('test')).left, 12.0);
  });

  testWidgets('InputDecorator error/helper/counter RTL layout', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        textDirection: TextDirection.rtl,
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: 'helper',
          counterText: 'counter',
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 76dps:
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding
    //    8 - below the border padding
    //   12 - [counter helper/error] (ahem font size 12dps)

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 76.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);
    expect(tester.getTopLeft(find.text('counter')), const Offset(12.0, 64.0));
    expect(tester.getTopRight(find.text('helper')), const Offset(788.0, 64.0));

    // If both error and helper are specified, show the error
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        textDirection: TextDirection.rtl,
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: 'helper',
          errorText: 'error',
          counterText: 'counter',
          filled: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('counter')), const Offset(12.0, 64.0));
    expect(tester.getTopRight(find.text('error')), const Offset(788.0, 64.0));
    expect(find.text('helper'), findsNothing);
  });

  testWidgets('InputDecorator prefix/suffix RTL', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        textDirection: TextDirection.rtl,
        decoration: const InputDecoration(
          prefixText: 'p',
          suffixText: 's',
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 40dps:
    //   12 - top padding
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 40.0));
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getSize(find.text('p')).height, 16.0);
    expect(tester.getSize(find.text('s')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 12.0);
    expect(tester.getTopLeft(find.text('p')).dy, 12.0);
    expect(tester.getTopLeft(find.text('s')).dy, 12.0);

    // layout is a row: [s text p]
    expect(tester.getTopLeft(find.text('s')).dx, 12.0);
    expect(tester.getTopRight(find.text('s')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('text')).dx));
    expect(tester.getTopRight(find.text('text')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('p')).dx));
  });

  testWidgets('InputDecorator contentPadding RTL layout', (WidgetTester tester) async {
    // LTR: content left edge is contentPadding.start: 40.0
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        textDirection: TextDirection.ltr,
        decoration: const InputDecoration(
          contentPadding: EdgeInsetsDirectional.only(start: 40.0, top: 12.0, bottom: 12.0),
          labelText: 'label',
          hintText: 'hint',
          filled: true,
        ),
      ),
    );
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dx, 40.0);
    expect(tester.getTopLeft(find.text('label')).dx, 40.0);
    expect(tester.getTopLeft(find.text('hint')).dx, 40.0);

    // RTL: content right edge is 800 - contentPadding.start: 760.0.
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        isFocused: true, // label is floating, still adjusted for contentPadding
        textDirection: TextDirection.rtl,
        decoration: const InputDecoration(
          contentPadding: EdgeInsetsDirectional.only(start: 40.0, top: 12.0, bottom: 12.0),
          labelText: 'label',
          hintText: 'hint',
          filled: true,
        ),
      ),
    );
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopRight(find.text('text')).dx, 760.0);
    expect(tester.getTopRight(find.text('label')).dx, 760.0);
    expect(tester.getTopRight(find.text('hint')).dx, 760.0);
  });

  testWidgets('InputDecorator prefix/suffix dense layout', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        isFocused: true,
        decoration: const InputDecoration(
          isDense: true,
          prefixText: 'p',
          suffixText: 's',
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 32dps:
    //    8 - top padding
    //   16 - input text (ahem font size 16dps)
    //    8 - bottom padding
    //
    // The only difference from normal layout for this case is that the
    // padding above and below the prefix, input text, suffix, is 8 instead of 12.

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 32.0));
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getSize(find.text('p')).height, 16.0);
    expect(tester.getSize(find.text('s')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 8.0);
    expect(tester.getTopLeft(find.text('p')).dy, 8.0);
    expect(tester.getTopLeft(find.text('p')).dx, 12.0);
    expect(tester.getTopLeft(find.text('s')).dy, 8.0);
    expect(tester.getTopRight(find.text('s')).dx, 788.0);

    // layout is a row: [p text s]
    expect(tester.getTopLeft(find.text('p')).dx, 12.0);
    expect(tester.getTopRight(find.text('p')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('text')).dx));
    expect(tester.getTopRight(find.text('text')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('s')).dx));

    expect(getBorderBottom(tester), 32.0);
    expect(getBorderWeight(tester), 2.0);
  });

  testWidgets('InputDecorator with empty InputDecoration', (WidgetTester tester) async {
    await tester.pumpWidget(buildInputDecorator());

    // Overall height for this InputDecorator is 40dps:
    //   12 - top padding
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 40.0));
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 12.0);
    expect(getBorderBottom(tester), 40.0);
    expect(getBorderWeight(tester), 1.0);
  });

  testWidgets('InputDecorator.collapsed', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default),
        // isFocused: false (default)
        decoration: const InputDecoration.collapsed(
          hintText: 'hint',
        ),
      ),
    );

    // Overall height for this InputDecorator is 16dps:
    //   16 - input text (ahem font size 16dps)

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 16.0));
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 0.0);
    expect(getOpacity(tester, 'hint'), 0.0);
    expect(getBorderWeight(tester), 0.0);

    // The hint should appear
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: true,
        decoration: const InputDecoration.collapsed(
          hintText: 'hint',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 16.0));
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 0.0);
    expect(tester.getSize(find.text('hint')).height, 16.0);
    expect(tester.getTopLeft(find.text('hint')).dy, 0.0);
    expect(getBorderWeight(tester), 0.0);
  });

  testWidgets('InputDecorator with baseStyle', (WidgetTester tester) async {
    // Setting the baseStyle of the InputDecoration and the style of the input
    // text child to a smaller font reduces the InputDecoration's vertical size.
    const TextStyle style = TextStyle(fontFamily: 'Ahem', fontSize: 10.0);
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: false,
        baseStyle: style,
        decoration: const InputDecoration(
          hintText: 'hint',
          labelText: 'label',
        ),
        child: const Text('text', style: style),
      ),
    );

    // Overall height for this InputDecorator is 45.5dps. When the label is
    // floating the layout is:
    //
    //    12  - top padding
    //    7.5 - floating label (ahem font size 10dps * 0.75 = 7.5)
    //    4   - floating label / input text gap
    //   10   - input text (ahem font size 10dps)
    //   12   - bottom padding
    //
    // When the label is not floating, it's vertically centered.
    //
    //   17.75 - top padding
    //      10 - label (ahem font size 10dps)
    //   17.75 - bottom padding (empty input text still appears here)

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 45.5));
    expect(tester.getSize(find.text('hint')).height, 10.0);
    expect(tester.getSize(find.text('label')).height, 10.0);
    expect(tester.getSize(find.text('text')).height, 10.0);
    expect(tester.getTopLeft(find.text('hint')).dy, 23.5);
    expect(tester.getTopLeft(find.text('label')).dy, 17.75);
    expect(tester.getTopLeft(find.text('text')).dy, 23.5);
  });

  testWidgets('InputDecorator with empty style overrides', (WidgetTester tester) async {
    // Same as not specifying any style overrides
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
          helperText: 'helper',
          counterText: 'counter',
          labelStyle: TextStyle(),
          hintStyle: TextStyle(),
          errorStyle: TextStyle(),
          helperStyle: TextStyle(),
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 76dps. When the label is
    // floating the layout is:
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding
    //    8 - below the border padding
    //   12 - help/error/counter text (ahem font size 12dps)

    // Label is floating because isEmpty is false.
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 76.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);
    expect(tester.getTopLeft(find.text('helper')), const Offset(12.0, 64.0));
    expect(tester.getTopRight(find.text('counter')), const Offset(788.0, 64.0));
  });

  testWidgets('InputDecoration outline shape with no border and no floating placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
      // isFocused: false (default)
      isEmpty: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(borderSide: BorderSide.none),
        hasFloatingPlaceholder: false,
        labelText: 'label',
        ),
      ),
    );

    // Overall height for this InputDecorator is 56dps. Layout is:
    //   20 - top padding
    //   16 - label (ahem font size 16dps)
    //   20 - bottom padding
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 0.0);
  });

  testWidgets('InputDecoration outline shape with no border and no floating placeholder not empty', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          hasFloatingPlaceholder: false,
          labelText: 'label',
        ),
      ),
    );

    // Overall height for this InputDecorator is 56dps. Layout is:
    //   20 - top padding
    //   16 - label (ahem font size 16dps)
    //   20 - bottom padding
    //    expect(tester.widget<Text>(find.text('prefix')).style.color, prefixStyle.color);
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 0.0);

    // The label should not be seen.
    expect(getOpacity(tester, 'label'), 0.0);
  });

  testWidgets('InputDecorationTheme outline border', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true, // label appears, vertically centered
        // isFocused: false (default)
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        decoration: const InputDecoration(
          labelText: 'label',
        ),
      ),
    );

    // Overall height for this InputDecorator is 56dps. Layout is:
    //   20 - top padding
    //   16 - label (ahem font size 16dps)
    //   20 - bottom padding
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);
  });

  testWidgets('InputDecorationTheme outline border, dense layout', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true, // label appears, vertically centered
        // isFocused: false (default)
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
        ),
      ),
    );

    // Overall height for this InputDecorator is 56dps. Layout is:
    //   16 - top padding
    //   16 - label (ahem font size 16dps)
    //   16 - bottom padding
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 48.0));
    expect(tester.getTopLeft(find.text('label')).dy, 16.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 32.0);
    expect(getBorderBottom(tester), 48.0);
    expect(getBorderWeight(tester), 1.0);
  });

  testWidgets('InputDecorationTheme style overrides', (WidgetTester tester) async {
    const TextStyle style16 = TextStyle(fontFamily: 'Ahem', fontSize: 16.0);
    final TextStyle labelStyle = style16.merge(const TextStyle(color: Colors.red));
    final TextStyle hintStyle = style16.merge(const TextStyle(color: Colors.green));
    final TextStyle prefixStyle = style16.merge(const TextStyle(color: Colors.blue));
    final TextStyle suffixStyle = style16.merge(const TextStyle(color: Colors.purple));

    const TextStyle style12 = TextStyle(fontFamily: 'Ahem', fontSize: 12.0);
    final TextStyle helperStyle = style12.merge(const TextStyle(color: Colors.orange));
    final TextStyle counterStyle = style12.merge(const TextStyle(color: Colors.orange));

    // This test also verifies that the default InputDecorator provides a
    // "small concession to backwards compatibility" by not padding on
    // the left and right. If filled is true or an outline border is
    // provided then the horizontal padding is included.

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true, // label appears, vertically centered
        // isFocused: false (default)
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: labelStyle,
          hintStyle: hintStyle,
          prefixStyle: prefixStyle,
          suffixStyle: suffixStyle,
          helperStyle: helperStyle,
          counterStyle: counterStyle,
          // filled: false (default) - don't pad by left/right 12dps
        ),
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
          prefixText: 'prefix',
          suffixText: 'suffix',
          helperText: 'helper',
          counterText: 'counter',
        ),
      ),
    );

    // Overall height for this InputDecorator is 76dps. Layout is:
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - prefix/hint/input/suffix text (ahem font size 16dps)
    //   12 - bottom padding
    //    8 - below the border padding
    //   12 - help/error/counter text (ahem font size 12dps)
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 76.0));
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);
    expect(tester.getTopLeft(find.text('helper')), const Offset(0.0, 64.0));
    expect(tester.getTopRight(find.text('counter')), const Offset(800.0, 64.0));

    // Verify that the styles were passed along
    expect(tester.widget<Text>(find.text('prefix')).style.color, prefixStyle.color);
    expect(tester.widget<Text>(find.text('suffix')).style.color, suffixStyle.color);
    expect(tester.widget<Text>(find.text('helper')).style.color, helperStyle.color);
    expect(tester.widget<Text>(find.text('counter')).style.color, counterStyle.color);

    TextStyle getLabelStyle() {
      return tester.firstWidget<AnimatedDefaultTextStyle>(
        find.ancestor(
          of: find.text('label'),
          matching: find.byType(AnimatedDefaultTextStyle)
        )
      ).style;
    }
    expect(getLabelStyle().color, labelStyle.color);
  });

  testWidgets('InputDecorator.toString()', (WidgetTester tester) async {
    const Widget child = InputDecorator(
      key: Key('key'),
      decoration: InputDecoration(),
      baseStyle: TextStyle(),
      textAlign: TextAlign.center,
      isFocused: false,
      isEmpty: false,
      child: Placeholder(),
    );
    expect(
      child.toString(),
      "InputDecorator-[<'key'>](decoration: InputDecoration(), baseStyle: TextStyle(<all styles inherited>), isFocused: false, isEmpty: false)",
    );
  });

  testWidgets('InputDecorator.debugDescribeChildren', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        decoration: const InputDecoration(
          icon: Text('icon'),
          labelText: 'label',
          hintText: 'hint',
          prefixText: 'prefix',
          suffixText: 'suffix',
          prefixIcon: Text('prefixIcon'),
          suffixIcon: Text('suffixIcon'),
          helperText: 'helper',
          counterText: 'counter',
        ),
        child: const Text('text'),
      ),
    );

    final RenderObject renderer = tester.renderObject(find.byType(InputDecorator));
    final Iterable<String> nodeNames = renderer.debugDescribeChildren()
      .map((DiagnosticsNode node) => node.name);
    expect(nodeNames, unorderedEquals(<String>[
      'container',
      'counter',
      'helperError',
      'hint',
      'icon',
      'input',
      'label',
      'prefix',
      'prefixIcon',
      'suffix',
      'suffixIcon',
    ]));

    final Set<Object> nodeValues = Set<Object>.from(
      renderer.debugDescribeChildren().map<Object>((DiagnosticsNode node) => node.value)
    );
    expect(nodeValues.length, 11);
  });

  testWidgets('InputDecorator with empty border and label', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/14165
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          border: InputBorder.none,
        ),
      ),
    );

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(getBorderWeight(tester), 0.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
  });

  testWidgets('InputDecorationTheme.inputDecoration', (WidgetTester tester) async {
    const TextStyle themeStyle = TextStyle(color: Colors.green);
    const TextStyle decorationStyle = TextStyle(color: Colors.blue);

    // InputDecorationTheme arguments define InputDecoration properties.
    InputDecoration decoration = const InputDecoration().applyDefaults(
      const InputDecorationTheme(
        labelStyle: themeStyle,
        helperStyle: themeStyle,
        hintStyle: themeStyle,
        errorStyle: themeStyle,
        isDense: true,
        contentPadding: EdgeInsets.all(1.0),
        prefixStyle: themeStyle,
        suffixStyle: themeStyle,
        counterStyle: themeStyle,
        filled: true,
        fillColor: Colors.red,
        border: InputBorder.none,
      )
    );

    expect(decoration.labelStyle, themeStyle);
    expect(decoration.helperStyle, themeStyle);
    expect(decoration.hintStyle, themeStyle);
    expect(decoration.errorStyle, themeStyle);
    expect(decoration.isDense, true);
    expect(decoration.contentPadding, const EdgeInsets.all(1.0));
    expect(decoration.prefixStyle, themeStyle);
    expect(decoration.suffixStyle, themeStyle);
    expect(decoration.counterStyle, themeStyle);
    expect(decoration.filled, true);
    expect(decoration.fillColor, Colors.red);
    expect(decoration.border, InputBorder.none);

    // InputDecoration (baseDecoration) defines InputDecoration properties
    decoration = const InputDecoration(
      labelStyle: decorationStyle,
      helperStyle: decorationStyle,
      hintStyle: decorationStyle,
      errorStyle: decorationStyle,
      isDense: false,
      contentPadding: EdgeInsets.all(4.0),
      prefixStyle: decorationStyle,
      suffixStyle: decorationStyle,
      counterStyle: decorationStyle,
      filled: false,
      fillColor: Colors.blue,
      border: OutlineInputBorder(),
    ).applyDefaults(
      const InputDecorationTheme(
        labelStyle: themeStyle,
        helperStyle: themeStyle,
        hintStyle: themeStyle,
        errorStyle: themeStyle,
        errorMaxLines: 4,
        isDense: true,
        contentPadding: EdgeInsets.all(1.0),
        prefixStyle: themeStyle,
        suffixStyle: themeStyle,
        counterStyle: themeStyle,
        filled: true,
        fillColor: Colors.red,
        border: InputBorder.none,
      ),
    );

    expect(decoration.labelStyle, decorationStyle);
    expect(decoration.helperStyle, decorationStyle);
    expect(decoration.hintStyle, decorationStyle);
    expect(decoration.errorStyle, decorationStyle);
    expect(decoration.errorMaxLines, 4);
    expect(decoration.isDense, false);
    expect(decoration.contentPadding, const EdgeInsets.all(4.0));
    expect(decoration.prefixStyle, decorationStyle);
    expect(decoration.suffixStyle, decorationStyle);
    expect(decoration.counterStyle, decorationStyle);
    expect(decoration.filled, false);
    expect(decoration.fillColor, Colors.blue);
    expect(decoration.border, const OutlineInputBorder());
  });

  testWidgets('InputDecorator OutlineInputBorder fillColor is clipped by border', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/15742

    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF00FF00),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(InputDecorator));

    // Fill is the border's outer path, a rounded rectangle
    expect(box, paints..path(
      style: PaintingStyle.fill,
      color: const Color(0xFF00FF00),
      includes: <Offset>[const Offset(800.0/2.0, 56/2.0)],
      excludes: <Offset>[
        const Offset(1.0, 6.0), // outside the rounded corner, top left
        const Offset(800.0 - 1.0, 6.0), // top right
        const Offset(1.0, 56.0 - 6.0), // bottom left
        const Offset(800 - 1.0, 56.0 - 6.0), // bottom right
      ],
    ));

    // Border outline. The rrect is the -center- of the 1.0 stroked outline.
    expect(box, paints..rrect(
      style: PaintingStyle.stroke,
      strokeWidth: 1.0,
      rrect: RRect.fromLTRBR(0.5, 0.5, 799.5, 55.5, const Radius.circular(11.5)),
    ));
  });

  testWidgets('InputDecorator UnderlineInputBorder fillColor is clipped by border', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          filled: true,
          fillColor: Color(0xFF00FF00),
          border: UnderlineInputBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12.0),
              bottomRight: Radius.circular(12.0),
            ),
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(InputDecorator));

    // Fill is the border's outer path, a rounded rectangle
    expect(box, paints..path(
      style: PaintingStyle.fill,
      color: const Color(0xFF00FF00),
      includes: <Offset>[const Offset(800.0/2.0, 56/2.0)],
      excludes: <Offset>[
        const Offset(1.0, 56.0 - 6.0), // bottom left
        const Offset(800 - 1.0, 56.0 - 6.0), // bottom right
      ],
    ));
  });

  testWidgets('InputDecorator constrained to 0x0', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/17710
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: UnconstrainedBox(child: ConstrainedBox(
            constraints: BoxConstraints.tight(Size.zero),
            child: const InputDecorator(
              decoration: InputDecoration(
                labelText: 'XP',
                border: OutlineInputBorder(),
              ),
            ),
          )),
        ),
      ),
    );
  });

  testWidgets(
    'InputDecorator OutlineBorder focused label with icon',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/18111

      Widget buildFrame(TextDirection textDirection) {
        return MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.center,
              child: Directionality(
                textDirection: textDirection,
                child: const RepaintBoundary(
                  child: InputDecorator(
                    isFocused: true,
                    isEmpty: true,
                    decoration: InputDecoration(
                      icon: Icon(Icons.insert_link),
                      labelText: 'primaryLink',
                      hintText: 'Primary link to story',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildFrame(TextDirection.ltr));
      await expectLater(
        find.byType(InputDecorator),
        matchesGoldenFile('input_decorator.outline_icon_label.ltr.png'),
        skip: !Platform.isLinux,
      );

      await tester.pumpWidget(buildFrame(TextDirection.rtl));
      await expectLater(
        find.byType(InputDecorator),
        matchesGoldenFile('input_decorator.outline_icon_label.rtl.png'),
        skip: !Platform.isLinux,
      );
    },
    skip: !Platform.isLinux,
  );

  testWidgets('InputDecorationTheme.toString()', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/19305
    expect(
      const InputDecorationTheme(
        contentPadding: EdgeInsetsDirectional.only(start: 5.0),
      ).toString(),
      contains('contentPadding: EdgeInsetsDirectional(5.0, 0.0, 0.0, 0.0)'),
    );

    // Regression test for https://github.com/flutter/flutter/issues/20374
    expect(
      const InputDecorationTheme(
        contentPadding: EdgeInsets.only(left: 5.0),
      ).toString(),
      contains('contentPadding: EdgeInsets(5.0, 0.0, 0.0, 0.0)'),
    );

    // Verify that the toString() method succeeds.
    final String debugString = const InputDecorationTheme(
      labelStyle: TextStyle(height: 1.0),
      helperStyle: TextStyle(height: 2.0),
      hintStyle: TextStyle(height: 3.0),
      errorStyle: TextStyle(height: 4.0),
      errorMaxLines: 5,
      isDense: true,
      contentPadding: EdgeInsets.only(right: 6.0),
      isCollapsed: true,
      prefixStyle: TextStyle(height: 7.0),
      suffixStyle: TextStyle(height: 8.0),
      counterStyle: TextStyle(height: 9.0),
      filled: true,
      fillColor: Color(10),
      errorBorder: UnderlineInputBorder(),
      focusedBorder: OutlineInputBorder(),
      focusedErrorBorder: UnderlineInputBorder(),
      disabledBorder: OutlineInputBorder(),
      enabledBorder: UnderlineInputBorder(),
      border: OutlineInputBorder(),
    ).toString();

    // Spot check
    expect(debugString, contains('labelStyle: TextStyle(inherit: true, height: 1.0x)'));
    expect(debugString, contains('isDense: true'));
    expect(debugString, contains('fillColor: Color(0x0000000a)'));
    expect(debugString, contains('errorBorder: UnderlineInputBorder()'));
    expect(debugString, contains('focusedBorder: OutlineInputBorder()'));
  });

  testWidgets('InputDecoration borders', (WidgetTester tester) async {
    const InputBorder errorBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 1.5),
    );
    const InputBorder focusedBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.green, width: 4.0),
    );
    const InputBorder focusedErrorBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.teal, width: 5.0),
    );
    const InputBorder disabledBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey, width: 0.0),
    );
    const InputBorder enabledBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blue, width: 2.5),
    );

    await tester.pumpWidget(
      buildInputDecorator(
        // isFocused: false (default)
        decoration: const InputDecoration(
          // errorText: null (default)
          // enabled: true (default)
          errorBorder: errorBorder,
          focusedBorder: focusedBorder,
          focusedErrorBorder: focusedErrorBorder,
          disabledBorder: disabledBorder,
          enabledBorder: enabledBorder,
        ),
      ),
    );
    expect(getBorder(tester), enabledBorder);

    await tester.pumpWidget(
      buildInputDecorator(
        isFocused: true,
        decoration: const InputDecoration(
          // errorText: null (default)
          // enabled: true (default)
          errorBorder: errorBorder,
          focusedBorder: focusedBorder,
          focusedErrorBorder: focusedErrorBorder,
          disabledBorder: disabledBorder,
          enabledBorder: enabledBorder,
        ),
      ),
    );
    await tester.pumpAndSettle(); // border changes are animated
    expect(getBorder(tester), focusedBorder);

    await tester.pumpWidget(
      buildInputDecorator(
        isFocused: true,
        decoration: const InputDecoration(
          errorText: 'error',
          // enabled: true (default)
          errorBorder: errorBorder,
          focusedBorder: focusedBorder,
          focusedErrorBorder: focusedErrorBorder,
          disabledBorder: disabledBorder,
          enabledBorder: enabledBorder,
        ),
      ),
    );
    await tester.pumpAndSettle(); // border changes are animated
    expect(getBorder(tester), focusedErrorBorder);

    await tester.pumpWidget(
      buildInputDecorator(
        // isFocused: false (default)
        decoration: const InputDecoration(
          errorText: 'error',
          // enabled: true (default)
          errorBorder: errorBorder,
          focusedBorder: focusedBorder,
          focusedErrorBorder: focusedErrorBorder,
          disabledBorder: disabledBorder,
          enabledBorder: enabledBorder,
        ),
      ),
    );
    await tester.pumpAndSettle(); // border changes are animated
    expect(getBorder(tester), errorBorder);

    await tester.pumpWidget(
      buildInputDecorator(
        // isFocused: false (default)
        decoration: const InputDecoration(
          errorText: 'error',
          enabled: false,
          errorBorder: errorBorder,
          focusedBorder: focusedBorder,
          focusedErrorBorder: focusedErrorBorder,
          disabledBorder: disabledBorder,
          enabledBorder: enabledBorder,
        ),
      ),
    );
    await tester.pumpAndSettle(); // border changes are animated
    expect(getBorder(tester), errorBorder);

    await tester.pumpWidget(
      buildInputDecorator(
        // isFocused: false (default)
        decoration: const InputDecoration(
          // errorText: false (default)
          enabled: false,
          errorBorder: errorBorder,
          focusedBorder: focusedBorder,
          focusedErrorBorder: focusedErrorBorder,
          disabledBorder: disabledBorder,
          enabledBorder: enabledBorder,
        ),
      ),
    );
    await tester.pumpAndSettle(); // border changes are animated
    expect(getBorder(tester), disabledBorder);

    await tester.pumpWidget(
      buildInputDecorator(
        isFocused: true,
        decoration: const InputDecoration(
          // errorText: null (default)
          enabled: false,
          errorBorder: errorBorder,
          focusedBorder: focusedBorder,
          focusedErrorBorder: focusedErrorBorder,
          disabledBorder: disabledBorder,
          enabledBorder: enabledBorder,
        ),
      ),
    );
    await tester.pumpAndSettle(); // border changes are animated
    expect(getBorder(tester), disabledBorder);
  });

  testWidgets('OutlineInputBorder radius carries over when lerping', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/23982
    const Key key = Key('textField');

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              key: key,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // TextField has the given border
    expect(getBorderRadius(tester), BorderRadius.zero);

    // Focusing does not change the border
    await tester.tap(find.byKey(key));
    await tester.pump();
    expect(getBorderRadius(tester), BorderRadius.zero);
    await tester.pump(const Duration(milliseconds: 100));
    expect(getBorderRadius(tester), BorderRadius.zero);
    await tester.pumpAndSettle();
    expect(getBorderRadius(tester), BorderRadius.zero);
  });

  test('InputBorder equality', () {
    // OutlineInputBorder's equality is defined by the borderRadius, borderSide, & gapPadding
    const OutlineInputBorder outlineInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(9.0)),
      borderSide: BorderSide(color: Colors.blue),
      gapPadding: 32.0,
    );
    expect(outlineInputBorder, const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blue),
      borderRadius: BorderRadius.all(Radius.circular(9.0)),
      gapPadding: 32.0,
    ));
    expect(outlineInputBorder, isNot(const OutlineInputBorder()));

    // UnderlineInputBorder's equality is defined only by the borderSide
    const UnderlineInputBorder underlineInputBorder = UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue));
    expect(underlineInputBorder, const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)));
    expect(underlineInputBorder, isNot(const UnderlineInputBorder()));
  });


  test('InputBorder hashCodes', () {
    // OutlineInputBorder's hashCode is defined by the borderRadius, borderSide, & gapPadding
    const OutlineInputBorder outlineInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(9.0)),
      borderSide: BorderSide(color: Colors.blue),
      gapPadding: 32.0,
    );
    expect(outlineInputBorder.hashCode, const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blue),
      borderRadius: BorderRadius.all(Radius.circular(9.0)),
      gapPadding: 32.0,
    ).hashCode);
    expect(outlineInputBorder.hashCode, isNot(const OutlineInputBorder().hashCode));

    // UnderlineInputBorder's hashCode is defined only by the borderSide
    const UnderlineInputBorder underlineInputBorder = UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue));
    expect(underlineInputBorder.hashCode, const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)).hashCode);
    expect(underlineInputBorder.hashCode, isNot(const UnderlineInputBorder().hashCode));
  });
}
