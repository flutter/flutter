// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildInputDecorator({
  InputDecoration decoration: const InputDecoration(),
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

double getBorderWeight(WidgetTester tester) {
  if (!tester.any(findBorderPainter()))
    return 0.0;
  final CustomPaint customPaint = tester.widget(findBorderPainter());
  final dynamic/* _InputBorderPainter */ inputBorderPainter = customPaint.foregroundPainter;
  final dynamic/*_InputBorderTween */  inputBorderTween = inputBorderPainter.border;
  final Animation<double> animation = inputBorderPainter.borderAnimation;
  final dynamic/*_InputBorder */ border = inputBorderTween.evaluate(animation);
  return border.borderSide.width;
}

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

    // enabled: false causes the border to disappear
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

  testWidgets('InputDecorator with null border', (WidgetTester tester) async {
    // Label is visible, hint is not (opacity 0.0).
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          border: null,
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

  testWidgets('InputDecorator.toString()', (WidgetTester tester) async {
    final Widget child = const InputDecorator(
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
      "InputDecorator-[<'key'>](decoration: InputDecoration(border: UnderlineInputBorder()), baseStyle: TextStyle(<all styles inherited>), isFocused: false, isEmpty: false)",
    );
  });
}
