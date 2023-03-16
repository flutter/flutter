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
