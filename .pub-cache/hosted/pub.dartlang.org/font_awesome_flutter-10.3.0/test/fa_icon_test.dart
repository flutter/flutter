// Tests adapted from https://github.com/flutter/flutter/blob/master/packages/flutter/test/widgets/icon_test.dart
// Copyright 2014 The Flutter Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  testWidgets('Can set opacity for an Icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: IconTheme(
          data: IconThemeData(
            color: Color(0xFF666666),
            opacity: 0.5,
          ),
          child: FaIcon(FontAwesomeIcons.accessibleIcon),
        ),
      ),
    );
    final RichText text = tester.widget(find.byType(RichText));
    expect(text.text.style!.color, const Color(0xFF666666).withOpacity(0.5));
  });

  testWidgets('Icon sizing - no theme, default size',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: FaIcon(FontAwesomeIcons.accessibleIcon),
        ),
      ),
    );

    final RenderBox renderObject = tester.renderObject(find.byType(FaIcon));
    expect(renderObject.size, equals(const Size.square(24.0)));
  });

  testWidgets('Icon sizing - no theme, explicit size',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: FaIcon(
            FontAwesomeIcons.accessibleIcon,
            size: 96.0,
          ),
        ),
      ),
    );

    final RenderBox renderObject = tester.renderObject(find.byType(FaIcon));
    expect(renderObject.size, equals(const Size.square(96.0)));
  });

  testWidgets('Icon sizing - sized theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: IconTheme(
            data: IconThemeData(size: 36.0),
            child: FaIcon(FontAwesomeIcons.accessibleIcon),
          ),
        ),
      ),
    );

    final RenderBox renderObject = tester.renderObject(find.byType(FaIcon));
    expect(renderObject.size, equals(const Size.square(36.0)));
  });

  testWidgets('Icon sizing - sized theme, explicit size',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: IconTheme(
            data: IconThemeData(size: 36.0),
            child: FaIcon(
              FontAwesomeIcons.accessibleIcon,
              size: 48.0,
            ),
          ),
        ),
      ),
    );

    final RenderBox renderObject = tester.renderObject(find.byType(FaIcon));
    expect(renderObject.size, equals(const Size.square(48.0)));
  });

  testWidgets('Icon sizing - sizeless theme, default size',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: IconTheme(
            data: IconThemeData(),
            child: FaIcon(FontAwesomeIcons.accessibleIcon),
          ),
        ),
      ),
    );

    final RenderBox renderObject = tester.renderObject(find.byType(FaIcon));
    expect(renderObject.size, equals(const Size.square(24.0)));
  });

  testWidgets("Changing semantic label from null doesn't rebuild tree ",
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: FaIcon(FontAwesomeIcons.accessibleIcon),
        ),
      ),
    );

    final Element richText1 = tester.element(find.byType(RichText));

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: FaIcon(
            FontAwesomeIcons.accessibleIcon,
            semanticLabel: 'a label',
          ),
        ),
      ),
    );

    final Element richText2 = tester.element(find.byType(RichText));

    // Compare a leaf Element in the Icon subtree before and after changing the
    // semanticLabel to make sure the subtree was not rebuilt.
    expect(richText2, same(richText1));
  });
}
