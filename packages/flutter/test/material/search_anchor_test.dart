// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('SearchBar defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);
    final ColorScheme colorScheme = theme.colorScheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: SearchBar(
            hintText: 'hint text',
          )
        ),
      ),
    );

    final Finder searchBarMaterial = find.descendant(
      of: find.byType(SearchBar),
      matching: find.byType(Material),
    );

    final Material material = tester.widget<Material>(searchBarMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, colorScheme.surface);
    expect(material.elevation, 6.0);
    expect(material.shadowColor, colorScheme.shadow);
    expect(material.surfaceTintColor, colorScheme.surfaceTint);
    expect(material.shape, const StadiumBorder());

    final Text helperText = tester.widget(find.text('hint text'));
    expect(helperText.style?.color, colorScheme.onSurfaceVariant);
    expect(helperText.style?.fontSize, 16.0);
    expect(helperText.style?.fontFamily, 'Roboto');
    expect(helperText.style?.fontWeight, FontWeight.w400);

    const String input = 'entered text';
    await tester.enterText(find.byType(SearchBar), input);
    final EditableText inputText = tester.widget(find.text(input));
    expect(inputText.style.color, colorScheme.onSurface);
    expect(inputText.style.fontSize, 16.0);
    expect(helperText.style?.fontFamily, 'Roboto');
    expect(inputText.style.fontWeight, FontWeight.w400);
  });

  testWidgets('SearchBar respects controller property', (WidgetTester tester) async {
    const String defaultText = 'default text';
    final TextEditingController controller = TextEditingController(text: defaultText);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SearchBar(
            controller: controller,
          ),
        ),
      ),
    );

    expect(controller.value.text, defaultText);
    expect(find.text(defaultText), findsOneWidget);

    const String updatedText = 'updated text';
    await tester.enterText(find.byType(SearchBar), updatedText);
    expect(controller.value.text, updatedText);
    expect(find.text(defaultText), findsNothing);
    expect(find.text(updatedText), findsOneWidget);
  });

  testWidgets('SearchBar respects focusNode property', (WidgetTester tester) async {
    final FocusNode node = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SearchBar(
            focusNode: node,
          ),
        ),
      ),
    );

    expect(node.hasFocus, false);

    node.requestFocus();
    await tester.pump();
    expect(node.hasFocus, true);

    node.unfocus();
    await tester.pump();
    expect(node.hasFocus, false);
  });

  testWidgets('SearchBar has correct default layout and padding LTR', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SearchBar(
            leading: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
            trailing: <Widget>[
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {},
              )
            ],
          ),
        ),
      ),
    );

    final Rect barRect = tester.getRect(find.byType(SearchBar));
    expect(barRect.size, const Size(800.0, 56.0));
    expect(barRect, equals(const Rect.fromLTRB(0.0, 272.0, 800.0, 328.0)));

    final Rect leadingIcon = tester.getRect(find.widgetWithIcon(IconButton, Icons.search));
    // Default left padding is 8.0, and icon button has 8.0 padding, so in total the padding between
    // the edge of the bar and the icon of the button is 16.0, which matches the spec.
    expect(leadingIcon.left, equals(barRect.left + 8.0));

    final Rect textField = tester.getRect(find.byType(TextField));
    expect(textField.left, equals(leadingIcon.right + 8.0));

    final Rect trailingIcon = tester.getRect(find.widgetWithIcon(IconButton, Icons.menu));
    expect(trailingIcon.left, equals(textField.right + 8.0));
    expect(trailingIcon.right, equals(barRect.right - 8.0));
  });

  testWidgets('SearchBar has correct default layout and padding - RTL', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: SearchBar(
              leading: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
              trailing: <Widget>[
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {},
                )
              ],
            ),
          ),
        ),
      ),
    );

    final Rect barRect = tester.getRect(find.byType(SearchBar));
    expect(barRect.size, const Size(800.0, 56.0));
    expect(barRect, equals(const Rect.fromLTRB(0.0, 272.0, 800.0, 328.0)));

    // The default padding is set to 8.0 so the distance between the icon of the button
    // and the edge of the bar is 16.0, which matches the spec.
    final Rect leadingIcon = tester.getRect(find.widgetWithIcon(IconButton, Icons.search));
    expect(leadingIcon.right, equals(barRect.right - 8.0));

    final Rect textField = tester.getRect(find.byType(TextField));
    expect(textField.right, equals(leadingIcon.left - 8.0));

    final Rect trailingIcon = tester.getRect(find.widgetWithIcon(IconButton, Icons.menu));
    expect(trailingIcon.right, equals(textField.left - 8.0));
    expect(trailingIcon.left, equals(barRect.left + 8.0));
  });

  testWidgets('SearchBar respects hintText property', (WidgetTester tester) async {
    const String hintText = 'hint text';
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: SearchBar(
            hintText: hintText,
          ),
        ),
      ),
    );

    expect(find.text(hintText), findsOneWidget);
  });

  testWidgets('SearchBar respects leading property', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    final ColorScheme colorScheme = theme.colorScheme;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SearchBar(
            leading: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.widgetWithIcon(IconButton, Icons.search), findsOneWidget);
    final Color? iconColor = _iconStyle(tester, Icons.search)?.color;
    expect(iconColor, colorScheme.onSurface); // Default icon color.
  });

  testWidgets('SearchBar respects trailing property', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    final ColorScheme colorScheme = theme.colorScheme;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SearchBar(
            trailing: <Widget>[
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.widgetWithIcon(IconButton, Icons.menu), findsOneWidget);
    final Color? iconColor = _iconStyle(tester, Icons.menu)?.color;
    expect(iconColor, colorScheme.onSurfaceVariant); // Default icon color.
  });

  testWidgets('SearchBar respects onTap property', (WidgetTester tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Material(
              child: SearchBar(
                onTap: () {
                  setState(() {
                    tapCount++;
                  });
                }
              ),
            );
          }
        ),
      ),
    );
    expect(tapCount, 0);
    await tester.tap(find.byType(SearchBar));
    expect(tapCount, 1);
    await tester.tap(find.byType(SearchBar));
    expect(tapCount, 2);
  });

  testWidgets('SearchBar respects onChanged property', (WidgetTester tester) async {
    int changeCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Material(
              child: SearchBar(
                onChanged: (_) {
                  setState(() {
                    changeCount++;
                  });
                }
              ),
            );
          }
        ),
      ),
    );

    expect(changeCount, 0);
    await tester.enterText(find.byType(SearchBar), 'a');
    expect(changeCount, 1);
    await tester.enterText(find.byType(SearchBar), 'b');
    expect(changeCount, 2);
  });

  testWidgets('SearchBar respects constraints property', (WidgetTester tester) async {
    const BoxConstraints constraints = BoxConstraints(maxWidth: 350.0, minHeight: 80);
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Material(
            child: SearchBar(
              constraints: constraints,
            ),
          ),
        ),
      ),
    );

    final Rect barRect = tester.getRect(find.byType(SearchBar));
    expect(barRect.size, const Size(350.0, 80.0));
  });

  testWidgets('SearchBar respects elevation property', (WidgetTester tester) async {
    const double pressedElevation = 0.0;
    const double hoveredElevation = 1.0;
    const double focusedElevation = 2.0;
    const double defaultElevation = 3.0;
    double getElevation(Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return pressedElevation;
      }
      if (states.contains(MaterialState.hovered)) {
        return hoveredElevation;
      }
      if (states.contains(MaterialState.focused)) {
        return focusedElevation;
      }
      return defaultElevation;
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: SearchBar(
              elevation: MaterialStateProperty.resolveWith<double>(getElevation),
            ),
          ),
        ),
      ),
    );

    final Finder searchBarMaterial = find.descendant(
      of: find.byType(SearchBar),
      matching: find.byType(Material),
    );
    Material material = tester.widget<Material>(searchBarMaterial);

    // On hovered.
    final TestGesture gesture = await _pointGestureToSearchBar(tester);
    await tester.pump();
    material = tester.widget<Material>(searchBarMaterial);
    expect(material.elevation, hoveredElevation);

    // On pressed.
    await gesture.down(tester.getCenter(find.byType(SearchBar)));
    await tester.pump();
    await gesture.removePointer();

    material = tester.widget<Material>(searchBarMaterial);
    expect(material.elevation, pressedElevation);

    // On focused.
    await tester.tap(find.byType(SearchBar));
    await tester.pump();
    material = tester.widget<Material>(searchBarMaterial);
    expect(material.elevation, focusedElevation);
  });

  testWidgets('SearchBar respects backgroundColor property', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: SearchBar(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(_getColor),
            ),
          ),
        ),
      ),
    );

    final Finder searchBarMaterial = find.descendant(
      of: find.byType(SearchBar),
      matching: find.byType(Material),
    );
    Material material = tester.widget<Material>(searchBarMaterial);

    // On hovered.
    final TestGesture gesture = await _pointGestureToSearchBar(tester);
    await tester.pump();
    material = tester.widget<Material>(searchBarMaterial);
    expect(material.color, hoveredColor);

    // On pressed.
    await gesture.down(tester.getCenter(find.byType(SearchBar)));
    await tester.pump();
    await gesture.removePointer();

    material = tester.widget<Material>(searchBarMaterial);
    expect(material.color, pressedColor);

    // On focused.
    await tester.tap(find.byType(SearchBar));
    await tester.pump();
    material = tester.widget<Material>(searchBarMaterial);
    expect(material.color, focusedColor);
  });

  testWidgets('SearchBar respects shadowColor property', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: SearchBar(
              shadowColor: MaterialStateProperty.resolveWith<Color>(_getColor),
            ),
          ),
        ),
      ),
    );

    final Finder searchBarMaterial = find.descendant(
      of: find.byType(SearchBar),
      matching: find.byType(Material),
    );
    Material material = tester.widget<Material>(searchBarMaterial);

    // On hovered.
    final TestGesture gesture = await _pointGestureToSearchBar(tester);
    await tester.pump();
    material = tester.widget<Material>(searchBarMaterial);
    expect(material.shadowColor, hoveredColor);

    // On pressed.
    await gesture.down(tester.getCenter(find.byType(SearchBar)));
    await tester.pump();
    await gesture.removePointer();

    material = tester.widget<Material>(searchBarMaterial);
    expect(material.shadowColor, pressedColor);

    // On focused.
    await tester.tap(find.byType(SearchBar));
    await tester.pump();
    material = tester.widget<Material>(searchBarMaterial);
    expect(material.shadowColor, focusedColor);
  });

  testWidgets('SearchBar respects surfaceTintColor property', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: SearchBar(
              surfaceTintColor: MaterialStateProperty.resolveWith<Color>(_getColor),
            ),
          ),
        ),
      ),
    );

    final Finder searchBarMaterial = find.descendant(
      of: find.byType(SearchBar),
      matching: find.byType(Material),
    );
    Material material = tester.widget<Material>(searchBarMaterial);

    // On hovered.
    final TestGesture gesture = await _pointGestureToSearchBar(tester);
    await tester.pump();
    material = tester.widget<Material>(searchBarMaterial);
    expect(material.surfaceTintColor, hoveredColor);

    // On pressed.
    await gesture.down(tester.getCenter(find.byType(SearchBar)));
    await tester.pump();
    await gesture.removePointer();

    material = tester.widget<Material>(searchBarMaterial);
    expect(material.surfaceTintColor, pressedColor);

    // On focused.
    await tester.tap(find.byType(SearchBar));
    await tester.pump();
    material = tester.widget<Material>(searchBarMaterial);
    expect(material.surfaceTintColor, focusedColor);
  });

  testWidgets('SearchBar respects overlayColor property', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: SearchBar(
              focusNode: focusNode,
              overlayColor: MaterialStateProperty.resolveWith<Color>(_getColor),
            ),
          ),
        ),
      ),
    );

    RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');

    // On hovered.
    final TestGesture gesture = await _pointGestureToSearchBar(tester);
    await tester.pumpAndSettle();
    expect(inkFeatures, paints..rect(color: hoveredColor.withOpacity(1.0)));

    // On pressed.
    await tester.pumpAndSettle();
    await tester.startGesture(tester.getCenter(find.byType(SearchBar)));
    await tester.pumpAndSettle();
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect()..rect(color: pressedColor.withOpacity(1.0)));
    await gesture.removePointer();

    // On focused.
    await tester.pumpAndSettle();
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect()..rect(color: focusedColor.withOpacity(1.0)));
  });

  testWidgets('SearchBar respects side and shape properties', (WidgetTester tester) async {
    const BorderSide pressedSide = BorderSide(width: 2.0);
    const BorderSide hoveredSide = BorderSide(width: 3.0);
    const BorderSide focusedSide = BorderSide(width: 4.0);
    const BorderSide defaultSide = BorderSide(width: 5.0);

    const OutlinedBorder pressedShape = RoundedRectangleBorder();
    const OutlinedBorder hoveredShape = ContinuousRectangleBorder();
    const OutlinedBorder focusedShape = CircleBorder();
    const OutlinedBorder defaultShape = StadiumBorder();
    BorderSide getSide(Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return pressedSide;
      }
      if (states.contains(MaterialState.hovered)) {
        return hoveredSide;
      }
      if (states.contains(MaterialState.focused)) {
        return focusedSide;
      }
      return defaultSide;
    }
    OutlinedBorder getShape(Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return pressedShape;
      }
      if (states.contains(MaterialState.hovered)) {
        return hoveredShape;
      }
      if (states.contains(MaterialState.focused)) {
        return focusedShape;
      }
      return defaultShape;
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: SearchBar(
              side: MaterialStateProperty.resolveWith<BorderSide>(getSide),
              shape: MaterialStateProperty.resolveWith<OutlinedBorder>(getShape),
            ),
          ),
        ),
      ),
    );

    final Finder searchBarMaterial = find.descendant(
      of: find.byType(SearchBar),
      matching: find.byType(Material),
    );
    Material material = tester.widget<Material>(searchBarMaterial);

    // On hovered.
    final TestGesture gesture = await _pointGestureToSearchBar(tester);
    await tester.pump();
    material = tester.widget<Material>(searchBarMaterial);
    expect(material.shape, hoveredShape.copyWith(side: hoveredSide));

    // On pressed.
    await gesture.down(tester.getCenter(find.byType(SearchBar)));
    await tester.pump();
    await gesture.removePointer();

    material = tester.widget<Material>(searchBarMaterial);
    expect(material.shape, pressedShape.copyWith(side: pressedSide));

    // On focused.
    await tester.tap(find.byType(SearchBar));
    await tester.pump();
    material = tester.widget<Material>(searchBarMaterial);
    expect(material.shape, focusedShape.copyWith(side: focusedSide));
  });

  testWidgets('SearchBar respects padding property', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Material(
            child: SearchBar(
              leading: Icon(Icons.search),
              padding: MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.all(16.0)),
              trailing: <Widget>[
                Icon(Icons.menu),
              ]
            ),
          ),
        ),
      ),
    );

    final Rect barRect = tester.getRect(find.byType(SearchBar));
    final Rect leadingRect = tester.getRect(find.byIcon(Icons.search));
    final Rect textFieldRect = tester.getRect(find.byType(TextField));
    final Rect trailingRect = tester.getRect(find.byIcon(Icons.menu));

    expect(barRect.left, leadingRect.left - 16.0);
    expect(leadingRect.right, textFieldRect.left - 16.0);
    expect(textFieldRect.right, trailingRect.left - 16.0);
    expect(trailingRect.right, barRect.right - 16.0);
  });

  testWidgets('SearchBar respects hintStyle property', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: SearchBar(
              hintText: 'hint text',
              hintStyle: MaterialStateProperty.resolveWith<TextStyle?>(_getTextStyle),
            ),
          ),
        ),
      ),
    );

    // On hovered.
    final TestGesture gesture = await _pointGestureToSearchBar(tester);
    await tester.pump();
    final Text helperText = tester.widget(find.text('hint text'));
    expect(helperText.style?.color, hoveredColor);

    // On pressed.
    await gesture.down(tester.getCenter(find.byType(SearchBar)));
    await tester.pump();
    await gesture.removePointer();
    expect(helperText.style?.color, hoveredColor);

    // On focused.
    await tester.tap(find.byType(SearchBar));
    await tester.pump();
    expect(helperText.style?.color, hoveredColor);
  });

  testWidgets('SearchBar respects textStyle property', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: 'input text');
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: SearchBar(
              controller: controller,
              textStyle: MaterialStateProperty.resolveWith<TextStyle?>(_getTextStyle),
            ),
          ),
        ),
      ),
    );

    // On hovered.
    final TestGesture gesture = await _pointGestureToSearchBar(tester);
    await tester.pump();
    final EditableText inputText = tester.widget(find.text('input text'));
    expect(inputText.style.color, hoveredColor);

    // On pressed.
    await gesture.down(tester.getCenter(find.byType(SearchBar)));
    await tester.pump();
    await gesture.removePointer();
    expect(inputText.style.color, hoveredColor);

    // On focused.
    await tester.tap(find.byType(SearchBar));
    await tester.pump();
    expect(inputText.style.color, hoveredColor);
  });

  testWidgets('hintStyle can override textStyle for hintText', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: SearchBar(
              hintText: 'hint text',
              hintStyle: MaterialStateProperty.resolveWith<TextStyle?>(_getTextStyle),
              textStyle: const MaterialStatePropertyAll<TextStyle>(TextStyle(color: Colors.pink)),
            ),
          ),
        ),
      ),
    );

    // On hovered.
    final TestGesture gesture = await _pointGestureToSearchBar(tester);
    await tester.pump();
    final Text helperText = tester.widget(find.text('hint text'));
    expect(helperText.style?.color, hoveredColor);

    // On pressed.
    await gesture.down(tester.getCenter(find.byType(SearchBar)));
    await tester.pump();
    await gesture.removePointer();
    expect(helperText.style?.color, hoveredColor);

    // On focused.
    await tester.tap(find.byType(SearchBar));
    await tester.pump();
    expect(helperText.style?.color, hoveredColor);
  });

  testWidgets('The search view defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);
    final ColorScheme colorScheme = theme.colorScheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Material(
            child: Align(
              alignment: Alignment.topLeft,
              child: SearchAnchor(
                viewHintText: 'hint text',
                builder: (BuildContext context, SearchController controller) {
                  return const Icon(Icons.search);
                },
                suggestionsBuilder: (BuildContext context, SearchController controller) {
                  return <Widget>[];
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    final Material material = getSearchViewMaterial(tester);
    expect(material.elevation, 6.0);
    expect(material.color, colorScheme.surface);
    expect(material.surfaceTintColor, colorScheme.surfaceTint);

    final Finder findDivider = find.byType(Divider);
    final Container dividerContainer = tester.widget<Container>(find.descendant(of: findDivider, matching: find.byType(Container)).first);
    final BoxDecoration decoration = dividerContainer.decoration! as BoxDecoration;
    expect(decoration.border!.bottom.color, colorScheme.outline);

    // Default search view has a leading back button on the start of the header.
    expect(find.widgetWithIcon(IconButton, Icons.arrow_back), findsOneWidget);

    // Default search view has a trailing close button on the end of the header.
    // It is used to clear the input in the text field.
    expect(find.widgetWithIcon(IconButton, Icons.close), findsOneWidget);

    final Text helperText = tester.widget(find.text('hint text'));
    expect(helperText.style?.color, colorScheme.onSurfaceVariant);
    expect(helperText.style?.fontSize, 16.0);
    expect(helperText.style?.fontFamily, 'Roboto');
    expect(helperText.style?.fontWeight, FontWeight.w400);

    const String input = 'entered text';
    await tester.enterText(find.byType(SearchBar), input);
    final EditableText inputText = tester.widget(find.text(input));
    expect(inputText.style.color, colorScheme.onSurface);
    expect(inputText.style.fontSize, 16.0);
    expect(inputText.style.fontFamily, 'Roboto');
    expect(inputText.style.fontWeight, FontWeight.w400);
  });

  testWidgets('The search view default size on different platforms', (WidgetTester tester) async {
    // The search view should be is full-screen on mobile platforms,
    // and have a size of (360, 2/3 screen height) on other platforms
    Widget buildSearchAnchor(TargetPlatform platform) {
      return MaterialApp(
        theme: ThemeData(platform: platform),
        home: Scaffold(
          body: SafeArea(
            child: Material(
              child: Align(
                alignment: Alignment.topLeft,
                child: SearchAnchor(
                  builder: (BuildContext context, SearchController controller) {
                    return const Icon(Icons.search);
                  },
                  suggestionsBuilder: (BuildContext context, SearchController controller) {
                    return <Widget>[];
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (final TargetPlatform platform in <TargetPlatform>[ TargetPlatform.iOS, TargetPlatform.android, TargetPlatform.fuchsia ]) {
      await tester.pumpWidget(Container());
      await tester.pumpWidget(buildSearchAnchor(platform));
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      final SizedBox sizedBox = tester.widget<SizedBox>(find.descendant(of: findViewContent(), matching: find.byType(SizedBox)).first);
      expect(sizedBox.width, 800.0);
      expect(sizedBox.height, 600.0);
    }

    for (final TargetPlatform platform in <TargetPlatform>[ TargetPlatform.linux, TargetPlatform.windows ]) {
      await tester.pumpWidget(Container());
      await tester.pumpWidget(buildSearchAnchor(platform));
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      final SizedBox sizedBox = tester.widget<SizedBox>(find.descendant(of: findViewContent(), matching: find.byType(SizedBox)).first);
      expect(sizedBox.width, 360.0);
      expect(sizedBox.height, 400.0);
    }
  });

  testWidgets('SearchAnchor respects isFullScreen property', (WidgetTester tester) async {
    Widget buildSearchAnchor(TargetPlatform platform) {
      return MaterialApp(
        theme: ThemeData(platform: platform),
        home: Scaffold(
          body: SafeArea(
            child: Material(
              child: Align(
                alignment: Alignment.topLeft,
                child: SearchAnchor(
                  isFullScreen: true,
                  builder: (BuildContext context, SearchController controller) {
                    return const Icon(Icons.search);
                  },
                  suggestionsBuilder: (BuildContext context, SearchController controller) {
                    return <Widget>[];
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (final TargetPlatform platform in <TargetPlatform>[ TargetPlatform.linux, TargetPlatform.windows ]) {
      await tester.pumpWidget(Container());
      await tester.pumpWidget(buildSearchAnchor(platform));
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      final SizedBox sizedBox = tester.widget<SizedBox>(find.descendant(of: findViewContent(), matching: find.byType(SizedBox)).first);
      expect(sizedBox.width, 800.0);
      expect(sizedBox.height, 600.0);
    }
  });

  testWidgets('SearchAnchor respects controller property', (WidgetTester tester) async {
    const String defaultText = 'initial text';
    final SearchController controller = SearchController();
    controller.text = defaultText;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SearchAnchor(
            searchController: controller,
            builder: (BuildContext context, SearchController controller) {
              return IconButton(icon: const Icon(Icons.search), onPressed: () {
                controller.openView();
              },);
            },
            suggestionsBuilder: (BuildContext context, SearchController controller) {
              return <Widget>[];
            },
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    expect(controller.value.text, defaultText);
    expect(find.text(defaultText), findsOneWidget);

    const String updatedText = 'updated text';
    await tester.enterText(find.byType(SearchBar), updatedText);
    expect(controller.value.text, updatedText);
    expect(find.text(defaultText), findsNothing);
    expect(find.text(updatedText), findsOneWidget);
  });

  testWidgets('SearchAnchor respects viewBuilder property', (WidgetTester tester) async {
    Widget buildAnchor({ViewBuilder? viewBuilder}) {
      return MaterialApp(
        home: Material(
          child: SearchAnchor(
            viewBuilder: viewBuilder,
            builder: (BuildContext context, SearchController controller) {
              return IconButton(icon: const Icon(Icons.search), onPressed: () {
                controller.openView();
              },);
            },
            suggestionsBuilder: (BuildContext context, SearchController controller) {
              return <Widget>[];
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildAnchor());
    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    // Default is a ListView.
    expect(find.byType(ListView), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pumpWidget(buildAnchor(viewBuilder: (Iterable<Widget> suggestions)
      => GridView.count(crossAxisCount: 5, children: suggestions.toList(),)
    ));
    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('SearchAnchor respects viewLeading property', (WidgetTester tester) async {
    Widget buildAnchor({Widget? viewLeading}) {
      return MaterialApp(
        home: Material(
          child: SearchAnchor(
            viewLeading: viewLeading,
            builder: (BuildContext context, SearchController controller) {
              return IconButton(icon: const Icon(Icons.search), onPressed: () {
                controller.openView();
              },);
            },
            suggestionsBuilder: (BuildContext context, SearchController controller) {
              return <Widget>[];
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildAnchor());
    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    // Default is a icon button with arrow_back.
    expect(find.widgetWithIcon(IconButton, Icons.arrow_back), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pumpWidget(buildAnchor(viewLeading: const Icon(Icons.history)));
    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byIcon(Icons.history), findsOneWidget);
  });

  testWidgets('SearchAnchor respects viewTrailing property', (WidgetTester tester) async {
    Widget buildAnchor({Iterable<Widget>? viewTrailing}) {
      return MaterialApp(
        home: Material(
          child: SearchAnchor(
            viewTrailing: viewTrailing,
            builder: (BuildContext context, SearchController controller) {
              return IconButton(icon: const Icon(Icons.search), onPressed: () {
                controller.openView();
              },);
            },
            suggestionsBuilder: (BuildContext context, SearchController controller) {
              return <Widget>[];
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildAnchor());
    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    // Default is a icon button with close icon.
    expect(find.widgetWithIcon(IconButton, Icons.close), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pumpWidget(buildAnchor(viewTrailing: <Widget>[const Icon(Icons.history)]));
    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.history), findsOneWidget);
  });

  testWidgets('SearchAnchor respects viewHintText property', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: SearchAnchor(
          viewHintText: 'hint text',
          builder: (BuildContext context, SearchController controller) {
            return IconButton(icon: const Icon(Icons.search), onPressed: () {
              controller.openView();
            },);
          },
          suggestionsBuilder: (BuildContext context, SearchController controller) {
            return <Widget>[];
          },
        ),
      ),
    ));
    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    expect(find.text('hint text'), findsOneWidget);
  });

  testWidgets('SearchAnchor respects viewBackgroundColor property', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: SearchAnchor(
          viewBackgroundColor: Colors.purple,
          builder: (BuildContext context, SearchController controller) {
            return IconButton(icon: const Icon(Icons.search), onPressed: () {
              controller.openView();
            },);
          },
          suggestionsBuilder: (BuildContext context, SearchController controller) {
            return <Widget>[];
          },
        ),
      ),
    ));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    expect(getSearchViewMaterial(tester).color, Colors.purple);
  });

  testWidgets('SearchAnchor respects viewElevation property', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: SearchAnchor(
          viewElevation: 3.0,
          builder: (BuildContext context, SearchController controller) {
            return IconButton(icon: const Icon(Icons.search), onPressed: () {
              controller.openView();
            },);
          },
          suggestionsBuilder: (BuildContext context, SearchController controller) {
            return <Widget>[];
          },
        ),
      ),
    ));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    expect(getSearchViewMaterial(tester).elevation, 3.0);
  });

  testWidgets('SearchAnchor respects viewSurfaceTint property', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: SearchAnchor(
          viewSurfaceTintColor: Colors.purple,
          builder: (BuildContext context, SearchController controller) {
            return IconButton(icon: const Icon(Icons.search), onPressed: () {
              controller.openView();
            },);
          },
          suggestionsBuilder: (BuildContext context, SearchController controller) {
            return <Widget>[];
          },
        ),
      ),
    ));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    expect(getSearchViewMaterial(tester).surfaceTintColor, Colors.purple);
  });

  testWidgets('SearchAnchor respects viewSide property', (WidgetTester tester) async {
    const BorderSide side = BorderSide(color: Colors.purple, width: 5.0);
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: SearchAnchor(
          isFullScreen: false,
          viewSide: side,
          builder: (BuildContext context, SearchController controller) {
            return IconButton(icon: const Icon(Icons.search), onPressed: () {
              controller.openView();
            },);
          },
          suggestionsBuilder: (BuildContext context, SearchController controller) {
            return <Widget>[];
          },
        ),
      ),
    ));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    expect(getSearchViewMaterial(tester).shape, RoundedRectangleBorder(side: side, borderRadius: BorderRadius.circular(28.0)));
  });

  testWidgets('SearchAnchor respects viewShape property', (WidgetTester tester) async {
    const BorderSide side = BorderSide(color: Colors.purple, width: 5.0);
    const OutlinedBorder shape = StadiumBorder(side: side);

    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: SearchAnchor(
          isFullScreen: false,
          viewShape: shape,
          builder: (BuildContext context, SearchController controller) {
            return IconButton(icon: const Icon(Icons.search), onPressed: () {
              controller.openView();
            },);
          },
          suggestionsBuilder: (BuildContext context, SearchController controller) {
            return <Widget>[];
          },
        ),
      ),
    ));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    expect(getSearchViewMaterial(tester).shape, shape);
  });

  testWidgets('SearchAnchor respects headerTextStyle property', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: SearchAnchor(
          headerTextStyle: theme.textTheme.bodyLarge?.copyWith(color: Colors.red),
          builder: (BuildContext context, SearchController controller) {
            return IconButton(icon: const Icon(Icons.search), onPressed: () {
              controller.openView();
            },);
          },
          suggestionsBuilder: (BuildContext context, SearchController controller) {
            return <Widget>[];
          },
        ),
      ),
    ));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'input text');
    await tester.pumpAndSettle();

    final EditableText inputText = tester.widget(find.text('input text'));
    expect(inputText.style.color, Colors.red);
  });

  testWidgets('SearchAnchor respects headerHintStyle property', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: SearchAnchor(
          viewHintText: 'hint text',
          headerHintStyle: theme.textTheme.bodyLarge?.copyWith(color: Colors.orange),
          builder: (BuildContext context, SearchController controller) {
            return IconButton(icon: const Icon(Icons.search), onPressed: () {
              controller.openView();
            },);
          },
          suggestionsBuilder: (BuildContext context, SearchController controller) {
            return <Widget>[];
          },
        ),
      ),
    ));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();

    final Text inputText = tester.widget(find.text('hint text'));
    expect(inputText.style?.color, Colors.orange);
  });

  testWidgets('SearchAnchor respects dividerColor property', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: SearchAnchor(
          dividerColor: Colors.red,
          builder: (BuildContext context, SearchController controller) {
            return IconButton(icon: const Icon(Icons.search), onPressed: () {
              controller.openView();
            },);
          },
          suggestionsBuilder: (BuildContext context, SearchController controller) {
            return <Widget>[];
          },
        ),
      ),
    ));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();

    final Finder findDivider = find.byType(Divider);
    final Container dividerContainer = tester.widget<Container>(find.descendant(of: findDivider, matching: find.byType(Container)).first);
    final BoxDecoration decoration = dividerContainer.decoration! as BoxDecoration;
    expect(decoration.border!.bottom.color, Colors.red);
  });

  testWidgets('SearchAnchor respects viewConstraints property', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Center(
          child: SearchAnchor(
            isFullScreen: false,
            viewConstraints: BoxConstraints.tight(const Size(280.0, 390.0)),
            builder: (BuildContext context, SearchController controller) {
              return IconButton(icon: const Icon(Icons.search), onPressed: () {
                controller.openView();
              },);
            },
            suggestionsBuilder: (BuildContext context, SearchController controller) {
              return <Widget>[];
            },
          ),
        ),
      ),
    ));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();

    final SizedBox sizedBox = tester.widget<SizedBox>(find.descendant(of: findViewContent(), matching: find.byType(SizedBox)).first);
    expect(sizedBox.width, 280.0);
    expect(sizedBox.height, 390.0);
  });

  testWidgets('SearchAnchor respects builder property - LTR', (WidgetTester tester) async {
    Widget buildAnchor({required SearchAnchorChildBuilder builder}) {
      return MaterialApp(
        home: Material(
          child: Align(
            alignment: Alignment.topCenter,
            child: SearchAnchor(
              isFullScreen: false,
              builder: builder,
              suggestionsBuilder: (BuildContext context, SearchController controller) {
                return <Widget>[];
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildAnchor(
      builder: (BuildContext context, SearchController controller)
        => const Icon(Icons.search)
    ));
    final Rect anchorRect = tester.getRect(find.byIcon(Icons.search));
    expect(anchorRect.size, const Size(24.0, 24.0));
    expect(anchorRect, equals(const Rect.fromLTRB(388.0, 0.0, 412.0, 24.0)));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    final Rect searchViewRect = tester.getRect(find.descendant(of: findViewContent(), matching: find.byType(SizedBox)).first);
    expect(searchViewRect, equals(const Rect.fromLTRB(388.0, 0.0, 748.0, 400.0)));

    // Search view top left should be the same as the anchor top left
    expect(searchViewRect.topLeft, anchorRect.topLeft);
  });

  testWidgets('SearchAnchor respects builder property - RTL', (WidgetTester tester) async {
    Widget buildAnchor({required SearchAnchorChildBuilder builder}) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Material(
            child: Align(
              alignment: Alignment.topCenter,
              child: SearchAnchor(
                isFullScreen: false,
                builder: builder,
                suggestionsBuilder: (BuildContext context, SearchController controller) {
                  return <Widget>[];
                },
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildAnchor(builder: (BuildContext context, SearchController controller)
    => const Icon(Icons.search)));
    final Rect anchorRect = tester.getRect(find.byIcon(Icons.search));
    expect(anchorRect.size, const Size(24.0, 24.0));
    expect(anchorRect, equals(const Rect.fromLTRB(388.0, 0.0, 412.0, 24.0)));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    final Rect searchViewRect = tester.getRect(find.descendant(of: findViewContent(), matching: find.byType(SizedBox)).first);
    expect(searchViewRect, equals(const Rect.fromLTRB(52.0, 0.0, 412.0, 400.0)));

    // Search view top right should be the same as the anchor top right
    expect(searchViewRect.topRight, anchorRect.topRight);
  });

  testWidgets('SearchAnchor respects suggestionsBuilder property', (WidgetTester tester) async {
    final SearchController controller = SearchController();
    const String suggestion = 'suggestion text';

    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Material(
            child: Align(
              alignment: Alignment.topCenter,
              child: SearchAnchor(
                searchController: controller,
                builder: (BuildContext context, SearchController controller) {
                  return const Icon(Icons.search);
                },
                suggestionsBuilder: (BuildContext context, SearchController controller) {
                  return <Widget>[
                    ListTile(
                      title: const Text(suggestion),
                      onTap: () {
                        setState(() {
                          controller.closeView(suggestion);
                        });
                    }),
                  ];
                },
              ),
            ),
          );
        }
      ),
    ));
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    final Finder listTile = find.widgetWithText(ListTile, suggestion);
    expect(listTile, findsOneWidget);
    await tester.tap(listTile);
    await tester.pumpAndSettle();

    expect(controller.isOpen, false);
    expect(controller.value.text, suggestion);
  });

  testWidgets('SearchAnchor.bar has a default search bar as the anchor', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Align(
          alignment: Alignment.topLeft,
          child: SearchAnchor.bar(
            isFullScreen: false,
            suggestionsBuilder: (BuildContext context, SearchController controller) {
              return <Widget>[];
            },
          ),
        ),
      ),),
    );

    expect(find.byType(SearchBar), findsOneWidget);
    final Rect anchorRect = tester.getRect(find.byType(SearchBar));
    expect(anchorRect.size, const Size(800.0, 56.0));
    expect(anchorRect, equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 56.0)));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    final Rect searchViewRect = tester.getRect(find.descendant(of: findViewContent(), matching: find.byType(SizedBox)).first);
    expect(searchViewRect, equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 400.0)));

    // Search view has same width with the default anchor(search bar).
    expect(searchViewRect.width, anchorRect.width);
  });

  testWidgets('SearchController can open/close view', (WidgetTester tester) async {
    final SearchController controller = SearchController();
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: SearchAnchor.bar(
          searchController: controller,
          isFullScreen: false,
          suggestionsBuilder: (BuildContext context, SearchController controller) {
            return <Widget>[
              ListTile(
                title: const Text('item 0'),
                onTap: () {
                  controller.closeView('item 0');
                },
              )
            ];
          },
        ),
      ),),
    );

    expect(controller.isOpen, false);
    await tester.tap(find.byType(SearchBar));
    await tester.pumpAndSettle();

    expect(controller.isOpen, true);
    await tester.tap(find.widgetWithText(ListTile, 'item 0'));
    await tester.pumpAndSettle();
    expect(controller.isOpen, false);
    controller.openView();
    expect(controller.isOpen, true);
  });

  testWidgets('Search view does not go off the screen - LTR', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Align(
          // Put the search anchor on the bottom-right corner of the screen to test
          // if the search view goes off the window.
          alignment: Alignment.bottomRight,
          child: SearchAnchor(
            isFullScreen: false,
            builder: (BuildContext context, SearchController controller) {
              return IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  controller.openView();
                },
              );
            },
            suggestionsBuilder: (BuildContext context, SearchController controller) {
              return <Widget>[];
            },
          ),
        ),
      ),),
    );

    final Finder findIconButton = find.widgetWithIcon(IconButton, Icons.search);
    final Rect iconButton = tester.getRect(findIconButton);
    // Icon button has a size of (48.0, 48.0) and the screen size is (800.0, 600.0).
    expect(iconButton, equals(const Rect.fromLTRB(752.0, 552.0, 800.0, 600.0)));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    final Rect searchViewRect = tester.getRect(find.descendant(of: findViewContent(), matching: find.byType(SizedBox)).first);
    expect(searchViewRect, equals(const Rect.fromLTRB(440.0, 200.0, 800.0, 600.0)));
  });

  testWidgets('Search view does not go off the screen - RTL', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          child: Align(
            // Put the search anchor on the bottom-left corner of the screen to test
            // if the search view goes off the window when the text direction is right-to-left.
            alignment: Alignment.bottomLeft,
            child: SearchAnchor(
              isFullScreen: false,
              builder: (BuildContext context, SearchController controller) {
                return IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    controller.openView();
                  },
                );
              },
              suggestionsBuilder: (BuildContext context, SearchController controller) {
                return <Widget>[];
              },
            ),
          ),
        ),
      ),),
    );

    final Finder findIconButton = find.widgetWithIcon(IconButton, Icons.search);
    final Rect iconButton = tester.getRect(findIconButton);
    expect(iconButton, equals(const Rect.fromLTRB(0.0, 552.0, 48.0, 600.0)));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    final Rect searchViewRect = tester.getRect(find.descendant(of: findViewContent(), matching: find.byType(SizedBox)).first);
    expect(searchViewRect, equals(const Rect.fromLTRB(0.0, 200.0, 360.0, 600.0)));
  });

  testWidgets('Search view becomes smaller if the window size is smaller than the view size', (WidgetTester tester) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(200.0, 200.0);
    tester.view.devicePixelRatio = 1.0;

    Widget buildSearchAnchor({TextDirection textDirection = TextDirection.ltr}) {
      return MaterialApp(
        home: Directionality(
          textDirection: textDirection,
          child: Material(
            child: SearchAnchor(
              isFullScreen: false,
              builder: (BuildContext context, SearchController controller) {
                return Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      controller.openView();
                    },
                  ),
                );
              },
              suggestionsBuilder: (BuildContext context, SearchController controller) {
                return <Widget>[];
              },
            ),
          ),
        ),);
    }

    // Test LTR text direction.
    await tester.pumpWidget(buildSearchAnchor());

    final Finder findIconButton = find.widgetWithIcon(IconButton, Icons.search);
    final Rect iconButton = tester.getRect(findIconButton);
    // The icon button size is (48.0, 48.0), and the screen size is (200.0, 200.0)
    expect(iconButton, equals(const Rect.fromLTRB(152.0, 152.0, 200.0, 200.0)));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    final Rect searchViewRect = tester.getRect(find.descendant(of: findViewContent(), matching: find.byType(SizedBox)).first);
    expect(searchViewRect, equals(const Rect.fromLTRB(0.0, 0.0, 200.0, 200.0)));

    // Test RTL text direction.
    await tester.pumpWidget(Container());
    await tester.pumpWidget(buildSearchAnchor(textDirection: TextDirection.rtl));

    final Finder findIconButtonRTL = find.widgetWithIcon(IconButton, Icons.search);
    final Rect iconButtonRTL = tester.getRect(findIconButtonRTL);
    // The icon button size is (48.0, 48.0), and the screen size is (200.0, 200.0)
    expect(iconButtonRTL, equals(const Rect.fromLTRB(152.0, 152.0, 200.0, 200.0)));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    final Rect searchViewRectRTL = tester.getRect(find.descendant(of: findViewContent(), matching: find.byType(SizedBox)).first);
    expect(searchViewRectRTL, equals(const Rect.fromLTRB(0.0, 0.0, 200.0, 200.0)));
  });
}

TextStyle? _iconStyle(WidgetTester tester, IconData icon) {
  final RichText iconRichText = tester.widget<RichText>(
    find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
  );
  return iconRichText.text.style;
}

const Color pressedColor = Colors.red;
const Color hoveredColor = Colors.orange;
const Color focusedColor = Colors.yellow;
const Color defaultColor = Colors.green;

Color _getColor(Set<MaterialState> states) {
  if (states.contains(MaterialState.pressed)) {
    return pressedColor;
  }
  if (states.contains(MaterialState.hovered)) {
    return hoveredColor;
  }
  if (states.contains(MaterialState.focused)) {
    return focusedColor;
  }
  return defaultColor;
}

final ThemeData theme = ThemeData();
final TextStyle? pressedStyle = theme.textTheme.bodyLarge?.copyWith(color: pressedColor);
final TextStyle? hoveredStyle = theme.textTheme.bodyLarge?.copyWith(color: hoveredColor);
final TextStyle? focusedStyle = theme.textTheme.bodyLarge?.copyWith(color: focusedColor);

TextStyle? _getTextStyle(Set<MaterialState> states) {
  if (states.contains(MaterialState.pressed)) {
    return pressedStyle;
  }
  if (states.contains(MaterialState.hovered)) {
    return hoveredStyle;
  }
  if (states.contains(MaterialState.focused)) {
    return focusedStyle;
  }
  return null;
}

Future<TestGesture> _pointGestureToSearchBar(WidgetTester tester) async {
  final Offset center = tester.getCenter(find.byType(SearchBar));
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );

  // On hovered.
  await gesture.addPointer();
  await gesture.moveTo(center);
  return gesture;
}
Finder findViewContent() {
  return find.byWidgetPredicate((Widget widget) {
    return widget.runtimeType.toString() == '_ViewContent';
  });
}

Material getSearchViewMaterial(WidgetTester tester) {
  return tester.widget<Material>(find.descendant(of: findViewContent(), matching: find.byType(Material)).first);
}
