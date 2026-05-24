// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CardThemeData copyWith, ==, hashCode basics', () {
    expect(const CardThemeData(), const CardThemeData().copyWith());
    expect(const CardThemeData().hashCode, const CardThemeData().copyWith().hashCode);
  });

  test('CardThemeData lerp special cases', () {
    expect(CardThemeData.lerp(null, null, 0), const CardThemeData());
    const theme = CardThemeData();
    expect(identical(CardThemeData.lerp(theme, theme, 0.5), theme), true);
  });

  test('CardThemeData defaults', () {
    const cardThemeData = CardThemeData();

    expect(cardThemeData.clipBehavior, null);
    expect(cardThemeData.color, null);
    expect(cardThemeData.elevation, null);
    expect(cardThemeData.margin, null);
    expect(cardThemeData.shadowColor, null);
    expect(cardThemeData.shape, null);
    expect(cardThemeData.surfaceTintColor, null);

    const cardTheme = CardTheme(data: CardThemeData(), child: SizedBox());
    expect(cardTheme.clipBehavior, null);
    expect(cardTheme.color, null);
    expect(cardTheme.elevation, null);
    expect(cardTheme.margin, null);
    expect(cardTheme.shadowColor, null);
    expect(cardTheme.shape, null);
    expect(cardTheme.surfaceTintColor, null);
  });

  testWidgets('Default CardThemeData debugFillProperties', (WidgetTester tester) async {
    final builder = DiagnosticPropertiesBuilder();
    const CardThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('CardThemeData implements debugFillProperties', (WidgetTester tester) async {
    final builder = DiagnosticPropertiesBuilder();
    const CardThemeData(
      clipBehavior: Clip.antiAlias,
      color: Colors.amber,
      elevation: 10.5,
      margin: EdgeInsets.all(20.5),
      shadowColor: Colors.green,
      surfaceTintColor: Colors.purple,
      shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.5))),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description[0], 'clipBehavior: Clip.antiAlias');
    expect(description[1], 'color: MaterialColor(primary value: ${const Color(0xffffc107)})');
    expect(description[2], 'shadowColor: MaterialColor(primary value: ${const Color(0xff4caf50)})');
    expect(
      description[3],
      'surfaceTintColor: MaterialColor(primary value: ${const Color(0xff9c27b0)})',
    );
    expect(description[4], 'elevation: 10.5');
    expect(description[5], 'margin: EdgeInsets.all(20.5)');
    expect(
      description[6],
      'shape: BeveledRectangleBorder(BorderSide(width: 0.0, style: none), BorderRadius.circular(20.5))',
    );
  });

  testWidgets('Material3 - Passing no CardTheme returns defaults', (WidgetTester tester) async {
    final theme = ThemeData();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: Card()),
      ),
    );

    final Padding padding = _getCardPadding(tester);
    final Material material = _getCardMaterial(tester);

    expect(material.clipBehavior, Clip.none);
    expect(material.color, theme.colorScheme.surfaceContainerLow);
    expect(material.shadowColor, theme.colorScheme.shadow);
    expect(material.surfaceTintColor, Colors.transparent); // Default primary color
    expect(material.elevation, 1.0);
    expect(padding.padding, const EdgeInsets.all(4.0));
    expect(
      material.shape,
      const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
    );
  });

  testWidgets('Card uses values from CardTheme', (WidgetTester tester) async {
    final CardThemeData cardTheme = _cardTheme();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(cardTheme: cardTheme),
        home: const Scaffold(body: Card()),
      ),
    );

    final Padding padding = _getCardPadding(tester);
    final Material material = _getCardMaterial(tester);

    expect(material.clipBehavior, cardTheme.clipBehavior);
    expect(material.color, cardTheme.color);
    expect(material.shadowColor, cardTheme.shadowColor);
    expect(material.surfaceTintColor, cardTheme.surfaceTintColor);
    expect(material.elevation, cardTheme.elevation);
    expect(padding.padding, cardTheme.margin);
    expect(material.shape, cardTheme.shape);
  });

  testWidgets('InheritedWidgets can trigger RenderObject updates', (WidgetTester tester) async {
    var cardThemeData = const CardThemeData(color: Colors.white);
    late StateSetter setState;

    void expectCardToMatchTheme() {
      final RenderPhysicalShape renderShape = tester.renderObject(find.byType(ThemedCard));

      if (cardThemeData.color != null) {
        expect(renderShape.color, cardThemeData.color);
      }
      if (cardThemeData.elevation != null) {
        expect(renderShape.elevation, cardThemeData.elevation);
      }
      if (cardThemeData.shadowColor != null) {
        expect(renderShape.shadowColor, cardThemeData.shadowColor);
      }
      if (cardThemeData.shape != null) {
        final CustomClipper<Path>? clipper = renderShape.clipper;
        expect(clipper, isA<ShapeBorderClipper>());
        expect((clipper! as ShapeBorderClipper).shape, cardThemeData.shape);
      }
      if (cardThemeData.clipBehavior != null) {
        expect(renderShape.clipBehavior, cardThemeData.clipBehavior);
      }
    }

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter) {
          setState = stateSetter;
          return Theme(
            data: ThemeData(cardTheme: cardThemeData),
            child: const ThemedCard(),
          );
        },
      ),
    );
    expectCardToMatchTheme();

    setState(() {
      cardThemeData = const CardThemeData(
        shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      );
    });
    await tester.pump();
    expectCardToMatchTheme();

    setState(() {
      cardThemeData = const CardThemeData(clipBehavior: Clip.hardEdge);
    });
    await tester.pump();
    expectCardToMatchTheme();

    setState(() {
      cardThemeData = const CardThemeData(
        elevation: 5.0,
        shadowColor: Colors.blueGrey,
        shape: ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      );
    });
    await tester.pump();
    expectCardToMatchTheme();
  });

  testWidgets('Card widget properties take priority over theme', (WidgetTester tester) async {
    const Clip clip = Clip.hardEdge;
    const Color color = Colors.orange;
    const Color shadowColor = Colors.pink;
    const elevation = 7.0;
    const margin = EdgeInsets.all(3.0);
    const ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(9.0)),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: _themeData().copyWith(cardTheme: _cardTheme()),
        home: const Scaffold(
          body: Card(
            clipBehavior: clip,
            color: color,
            shadowColor: shadowColor,
            elevation: elevation,
            margin: margin,
            shape: shape,
          ),
        ),
      ),
    );

    final Padding padding = _getCardPadding(tester);
    final Material material = _getCardMaterial(tester);

    expect(material.clipBehavior, clip);
    expect(material.color, color);
    expect(material.shadowColor, shadowColor);
    expect(material.elevation, elevation);
    expect(padding.padding, margin);
    expect(material.shape, shape);
  });

  testWidgets('CardTheme properties take priority over ThemeData properties', (
    WidgetTester tester,
  ) async {
    final CardThemeData cardTheme = _cardTheme();
    final ThemeData themeData = _themeData().copyWith(cardTheme: cardTheme);

    await tester.pumpWidget(
      MaterialApp(
        theme: themeData,
        home: const Scaffold(body: Card()),
      ),
    );

    final Material material = _getCardMaterial(tester);
    expect(material.color, cardTheme.color);
  });

  testWidgets('Material3 - ThemeData properties are used when no CardTheme is set', (
    WidgetTester tester,
  ) async {
    final themeData = ThemeData();

    await tester.pumpWidget(
      MaterialApp(
        theme: themeData,
        home: const Scaffold(body: Card()),
      ),
    );

    final Material material = _getCardMaterial(tester);
    expect(material.color, themeData.colorScheme.surfaceContainerLow);
  });

  testWidgets('Material3 - CardTheme customizes shape', (WidgetTester tester) async {
    const cardTheme = CardThemeData(
      color: Colors.white,
      shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(7))),
      elevation: 1.0,
    );

    final Key painterKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(cardTheme: cardTheme),
        home: Scaffold(
          body: RepaintBoundary(
            key: painterKey,
            child: Center(
              child: Card(child: SizedBox.fromSize(size: const Size(200, 300))),
            ),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(painterKey), matchesGoldenFile('card_theme.custom_shape.png'));
  });

  testWidgets('Card properties are taken over the theme values', (WidgetTester tester) async {
    const Clip themeClipBehavior = Clip.antiAlias;
    const Color themeColor = Colors.red;
    const Color themeShadowColor = Colors.orange;
    const themeElevation = 10.0;
    const themeMargin = EdgeInsets.all(12.0);
    const ShapeBorder themeShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(15.0)),
    );

    const Clip clipBehavior = Clip.hardEdge;
    const Color color = Colors.yellow;
    const Color shadowColor = Colors.green;
    const elevation = 20.0;
    const margin = EdgeInsets.all(18.0);
    const ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(25.0)),
    );

    final themeData = ThemeData(
      cardTheme: const CardThemeData(
        clipBehavior: themeClipBehavior,
        color: themeColor,
        shadowColor: themeShadowColor,
        elevation: themeElevation,
        margin: themeMargin,
        shape: themeShape,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: themeData,
        home: const Scaffold(
          body: Card(
            clipBehavior: clipBehavior,
            color: color,
            shadowColor: shadowColor,
            elevation: elevation,
            margin: margin,
            shape: shape,
            child: SizedBox(width: 200, height: 200),
          ),
        ),
      ),
    );

    final Padding cardMargin = _getCardPadding(tester);
    final Material material = _getCardMaterial(tester);

    expect(material.clipBehavior, clipBehavior);
    expect(material.color, color);
    expect(material.shadowColor, shadowColor);
    expect(material.elevation, elevation);
    expect(material.shape, shape);
    expect(cardMargin.padding, margin);
  });

  testWidgets('Local CardTheme can override global CardTheme', (WidgetTester tester) async {
    const Clip globalClipBehavior = Clip.antiAlias;
    const Color globalColor = Colors.red;
    const Color globalShadowColor = Colors.orange;
    const globalElevation = 10.0;
    const globalMargin = EdgeInsets.all(12.0);
    const ShapeBorder globalShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(15.0)),
    );

    const Clip localClipBehavior = Clip.hardEdge;
    const Color localColor = Colors.yellow;
    const Color localShadowColor = Colors.green;
    const localElevation = 20.0;
    const localMargin = EdgeInsets.all(18.0);
    const ShapeBorder localShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(25.0)),
    );

    final themeData = ThemeData(
      cardTheme: const CardThemeData(
        clipBehavior: globalClipBehavior,
        color: globalColor,
        shadowColor: globalShadowColor,
        elevation: globalElevation,
        margin: globalMargin,
        shape: globalShape,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: themeData,
        home: const Scaffold(
          body: CardTheme(
            data: CardThemeData(
              clipBehavior: localClipBehavior,
              color: localColor,
              shadowColor: localShadowColor,
              elevation: localElevation,
              margin: localMargin,
              shape: localShape,
            ),
            child: Card(child: SizedBox(width: 200, height: 200)),
          ),
        ),
      ),
    );

    final Padding cardMargin = _getCardPadding(tester);
    final Material material = _getCardMaterial(tester);

    expect(material.clipBehavior, localClipBehavior);
    expect(material.color, localColor);
    expect(material.shadowColor, localShadowColor);
    expect(material.elevation, localElevation);
    expect(material.shape, localShape);
    expect(cardMargin.padding, localMargin);
  });

  group('Material 2', () {
    // These tests are only relevant for Material 2. Once Material 2
    // support is deprecated and the APIs are removed, these tests
    // can be deleted.

    testWidgets('Material2 - ThemeData properties are used when no CardTheme is set', (
      WidgetTester tester,
    ) async {
      final themeData = ThemeData(useMaterial3: false);

      await tester.pumpWidget(
        MaterialApp(
          theme: themeData,
          home: const Scaffold(body: Card()),
        ),
      );

      final Material material = _getCardMaterial(tester);
      expect(material.color, themeData.cardColor);
    });

    testWidgets('Material2 - Passing no CardTheme returns defaults', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: const Scaffold(body: Card()),
        ),
      );

      final Padding padding = _getCardPadding(tester);
      final Material material = _getCardMaterial(tester);

      expect(material.clipBehavior, Clip.none);
      expect(material.color, Colors.white);
      expect(material.shadowColor, Colors.black);
      expect(material.surfaceTintColor, null);
      expect(material.elevation, 1.0);
      expect(padding.padding, const EdgeInsets.all(4.0));
      expect(
        material.shape,
        const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))),
      );
    });

    testWidgets('Material2 - CardTheme customizes shape', (WidgetTester tester) async {
      const cardTheme = CardThemeData(
        color: Colors.white,
        shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(7))),
        elevation: 1.0,
      );

      final Key painterKey = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(cardTheme: cardTheme, useMaterial3: false),
          home: Scaffold(
            body: RepaintBoundary(
              key: painterKey,
              child: Center(
                child: Card(child: SizedBox.fromSize(size: const Size(200, 300))),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byKey(painterKey),
        matchesGoldenFile('card_theme.custom_shape_m2.png'),
      );
    });
  });
}

CardThemeData _cardTheme() {
  return const CardThemeData(
    clipBehavior: Clip.antiAlias,
    color: Colors.green,
    shadowColor: Colors.red,
    surfaceTintColor: Colors.purple,
    elevation: 6.0,
    margin: EdgeInsets.all(7.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0))),
  );
}

ThemeData _themeData() {
  return ThemeData(cardColor: Colors.pink);
}

class ThemedCard extends SingleChildRenderObjectWidget {
  const ThemedCard({super.key}) : super(child: const SizedBox.expand());

  @override
  RenderPhysicalShape createRenderObject(BuildContext context) {
    final CardThemeData cardTheme = CardTheme.of(context);

    return RenderPhysicalShape(
      clipper: ShapeBorderClipper(shape: cardTheme.shape ?? const RoundedRectangleBorder()),
      clipBehavior: cardTheme.clipBehavior ?? Clip.antiAlias,
      color: cardTheme.color ?? Colors.white,
      elevation: cardTheme.elevation ?? 0.0,
      shadowColor: cardTheme.shadowColor ?? Colors.black,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPhysicalShape renderObject) {
    final CardThemeData cardTheme = CardTheme.of(context);

    renderObject
      ..clipper = ShapeBorderClipper(shape: cardTheme.shape ?? const RoundedRectangleBorder())
      ..clipBehavior = cardTheme.clipBehavior ?? Clip.antiAlias
      ..color = cardTheme.color ?? Colors.white
      ..elevation = cardTheme.elevation ?? 0.0
      ..shadowColor = cardTheme.shadowColor ?? Colors.black;
  }
}

Material _getCardMaterial(WidgetTester tester) {
  return tester.widget<Material>(
    find.descendant(of: find.byType(Card), matching: find.byType(Material)),
  );
}

Padding _getCardPadding(WidgetTester tester) {
  return tester.widget<Padding>(
    find.descendant(of: find.byType(Card), matching: find.byType(Padding)),
  );
}
