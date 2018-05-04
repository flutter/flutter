// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

Widget buildInputDecorator({
  InputDecoration decoration: const InputDecoration(),
  InputDecorationTheme inputDecorationTheme,
  TextDirection textDirection: TextDirection.ltr,
  bool isEmpty: false,
  bool isFocused: false,
  TextStyle baseStyle,
  Widget child: const Text(
    'text',
    style: const TextStyle(fontFamily: 'Ahem', fontSize: 16.0),
  ),
}) {
  return new MaterialApp(
    home: new Material(
      child: new Builder(
        builder: (BuildContext context) {
          return new Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: inputDecorationTheme,
            ),
            child: new Align(
              alignment: Alignment.topLeft,
              child: new Directionality(
                textDirection: textDirection,
                child: new InputDecorator(
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

BorderSide getBorderSide(WidgetTester tester) {
  if (!tester.any(findBorderPainter()))
    return null;
  final CustomPaint customPaint = tester.widget(findBorderPainter());
  final dynamic/* _InputBorderPainter */ inputBorderPainter = customPaint.foregroundPainter;
  final dynamic/*_InputBorderTween */ inputBorderTween = inputBorderPainter.border;
  final Animation<double> animation = inputBorderPainter.borderAnimation;
  final dynamic/*_InputBorder */ border = inputBorderTween.evaluate(animation);
  return border.borderSide;
}

double getBorderWeight(WidgetTester tester) => getBorderSide(tester)?.width;

Color getBorderColor(WidgetTester tester) => getBorderSide(tester)?.color;

double getHintOpacity(WidgetTester tester) {
  final Opacity opacityWidget = tester.widget<Opacity>(
    find.ancestor(
      of: find.text('hint'),
      matching: find.byType(Opacity),
    ).last
  );
  return opacityWidget.opacity;
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
    expect(getHintOpacity(tester), 0.0);
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
      final double hintOpacity50ms = getHintOpacity(tester);
      expect(hintOpacity50ms, inExclusiveRange(0.0, 1.0));
      await tester.pump(const Duration(milliseconds: 50));
      final double hintOpacity100ms = getHintOpacity(tester);
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
    expect(getHintOpacity(tester), 1.0);
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
      final double hintOpacity50ms = getHintOpacity(tester);
      expect(hintOpacity50ms, inExclusiveRange(0.0, 1.0));
      await tester.pump(const Duration(milliseconds: 50));
      final double hintOpacity100ms = getHintOpacity(tester);
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
    expect(getHintOpacity(tester), 0.0);
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
    expect(getHintOpacity(tester), 0.0);
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
    expect(getHintOpacity(tester), 1.0);
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

  testWidgets('InputDecorator prefix/suffix', (WidgetTester tester) async {
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
          icon: const Icon(Icons.android),
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
          contentPadding: const EdgeInsetsDirectional.only(start: 40.0, top: 12.0, bottom: 12.0),
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
          contentPadding: const EdgeInsetsDirectional.only(start: 40.0, top: 12.0, bottom: 12.0),
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
    expect(getHintOpacity(tester), 0.0);
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
    const TextStyle style = const TextStyle(fontFamily: 'Ahem', fontSize: 10.0);
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
          labelStyle: const TextStyle(),
          hintStyle: const TextStyle(),
          errorStyle: const TextStyle(),
          helperStyle: const TextStyle(),
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

  testWidgets('InputDecorationTheme outline border', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true, // label appears, vertically centered
        // isFocused: false (default)
        inputDecorationTheme: const InputDecorationTheme(
          border: const OutlineInputBorder(),
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
          border: const OutlineInputBorder(),
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
    const TextStyle style16 = const TextStyle(fontFamily: 'Ahem', fontSize: 16.0);
    final TextStyle labelStyle = style16.merge(const TextStyle(color: Colors.red));
    final TextStyle hintStyle = style16.merge(const TextStyle(color: Colors.green));
    final TextStyle prefixStyle = style16.merge(const TextStyle(color: Colors.blue));
    final TextStyle suffixStyle = style16.merge(const TextStyle(color: Colors.purple));

    const TextStyle style12 = const TextStyle(fontFamily: 'Ahem', fontSize: 12.0);
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
        inputDecorationTheme: new InputDecorationTheme(
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
    const Widget child = const InputDecorator(
      key: const Key('key'),
      decoration: const InputDecoration(),
      baseStyle: const TextStyle(),
      textAlign: TextAlign.center,
      isFocused: false,
      isEmpty: false,
      child: const Placeholder(),
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
          icon: const Text('icon'),
          labelText: 'label',
          hintText: 'hint',
          prefixText: 'prefix',
          suffixText: 'suffix',
          prefixIcon: const Text('prefixIcon'),
          suffixIcon: const Text('suffixIcon'),
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

    final Set<Object> nodeValues = new Set<Object>.from(
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
    const TextStyle themeStyle = const TextStyle(color: Colors.green);
    const TextStyle decorationStyle = const TextStyle(color: Colors.blue);

    // InputDecorationTheme arguments define InputDecoration properties.
    InputDecoration decoration = const InputDecoration().applyDefaults(
      const InputDecorationTheme(
        labelStyle: themeStyle,
        helperStyle: themeStyle,
        hintStyle: themeStyle,
        errorStyle: themeStyle,
        isDense: true,
        contentPadding: const EdgeInsets.all(1.0),
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
      contentPadding: const EdgeInsets.all(4.0),
      prefixStyle: decorationStyle,
      suffixStyle: decorationStyle,
      counterStyle: decorationStyle,
      filled: false,
      fillColor: Colors.blue,
      border: const OutlineInputBorder(),
    ).applyDefaults(
      const InputDecorationTheme(
        labelStyle: themeStyle,
        helperStyle: themeStyle,
        hintStyle: themeStyle,
        errorStyle: themeStyle,
        errorMaxLines: 4,
        isDense: true,
        contentPadding: const EdgeInsets.all(1.0),
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
        decoration: new InputDecoration(
          filled: true,
          fillColor: const Color(0xFF00FF00),
          border: new OutlineInputBorder(
            borderRadius: new BorderRadius.circular(12.0),
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
      rrect: new RRect.fromLTRBR(0.5, 0.5, 799.5, 55.5, const Radius.circular(11.5)),
    ));
  });

  testWidgets('InputDecorator UnderlineInputBorder fillColor is clipped by border', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          filled: true,
          fillColor: const Color(0xFF00FF00),
          border: const UnderlineInputBorder(
            borderRadius: const BorderRadius.only(
              bottomLeft: const Radius.circular(12.0),
              bottomRight: const Radius.circular(12.0),
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
}
