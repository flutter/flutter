// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

class TestIcon extends StatefulWidget {
  const TestIcon({ super.key });

  @override
  TestIconState createState() => TestIconState();
}

class TestIconState extends State<TestIcon> {
  late IconThemeData iconTheme;

  @override
  Widget build(BuildContext context) {
    iconTheme = IconTheme.of(context);
    return const Icon(Icons.add);
  }
}

class TestText extends StatefulWidget {
  const TestText(this.text, { super.key });

  final String text;

  @override
  TestTextState createState() => TestTextState();
}

class TestTextState extends State<TestText> {
  late TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    textStyle = DefaultTextStyle.of(context).style;
    return Text(widget.text);
  }
}

void main() {
  test('ListTileThemeData copyWith, ==, hashCode basics', () {
    expect(const ListTileThemeData(), const ListTileThemeData().copyWith());
    expect(const ListTileThemeData().hashCode, const ListTileThemeData().copyWith().hashCode);
  });

  test('ListTileThemeData defaults', () {
    const ListTileThemeData themeData = ListTileThemeData();
    expect(themeData.dense, null);
    expect(themeData.shape, null);
    expect(themeData.style, null);
    expect(themeData.selectedColor, null);
    expect(themeData.iconColor, null);
    expect(themeData.textColor, null);
    expect(themeData.contentPadding, null);
    expect(themeData.tileColor, null);
    expect(themeData.selectedTileColor, null);
    expect(themeData.horizontalTitleGap, null);
    expect(themeData.minVerticalPadding, null);
    expect(themeData.minLeadingWidth, null);
    expect(themeData.enableFeedback, null);
    expect(themeData.mouseCursor, null);
    expect(themeData.visualDensity, null);
  });

  testWidgets('Default ListTileThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ListTileThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  testWidgets('ListTileThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ListTileThemeData(
      dense: true,
      shape: StadiumBorder(),
      style: ListTileStyle.drawer,
      selectedColor: Color(0x00000001),
      iconColor: Color(0x00000002),
      textColor: Color(0x00000003),
      contentPadding: EdgeInsets.all(100),
      tileColor: Color(0x00000004),
      selectedTileColor: Color(0x00000005),
      horizontalTitleGap: 200,
      minVerticalPadding: 300,
      minLeadingWidth: 400,
      enableFeedback: true,
      mouseCursor: MaterialStateMouseCursor.clickable,
      visualDensity: VisualDensity.comfortable,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description[0], 'dense: true');
    expect(description[1], 'shape: StadiumBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none))');
    expect(description[2], 'style: drawer');
    expect(description[3], 'selectedColor: Color(0x00000001)');
    expect(description[4], 'iconColor: Color(0x00000002)');
    expect(description[5], 'textColor: Color(0x00000003)');
    expect(description[6], 'contentPadding: EdgeInsets.all(100.0)');
    expect(description[7], 'tileColor: Color(0x00000004)');
    expect(description[8], 'selectedTileColor: Color(0x00000005)');
    expect(description[9], 'horizontalTitleGap: 200.0');
    expect(description[10], 'minVerticalPadding: 300.0');
    expect(description[11], 'minLeadingWidth: 400.0');
    expect(description[12], 'enableFeedback: true');
    expect(description[13], 'mouseCursor: MaterialStateMouseCursor(clickable)');
    expect(
      description[14],
      equalsIgnoringHashCodes('visualDensity: VisualDensity#00000(h: -1.0, v: -1.0)(horizontal: -1.0, vertical: -1.0)'),
    );
  });

  testWidgets('ListTileTheme backwards compatibility constructor', (WidgetTester tester) async {
    late ListTileThemeData theme;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListTileTheme(
            dense: true,
            shape: const StadiumBorder(),
            style: ListTileStyle.drawer,
            selectedColor: const Color(0x00000001),
            iconColor: const Color(0x00000002),
            textColor: const Color(0x00000003),
            contentPadding: const EdgeInsets.all(100),
            tileColor: const Color(0x00000004),
            selectedTileColor: const Color(0x00000005),
            horizontalTitleGap: 200,
            minVerticalPadding: 300,
            minLeadingWidth: 400,
            enableFeedback: true,
            mouseCursor: MaterialStateMouseCursor.clickable,
            child: Center(
              child: Builder(
                builder: (BuildContext context) {
                  theme = ListTileTheme.of(context);
                  return const Placeholder();
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(theme.dense, true);
    expect(theme.shape, const StadiumBorder());
    expect(theme.style, ListTileStyle.drawer);
    expect(theme.selectedColor, const Color(0x00000001));
    expect(theme.iconColor, const Color(0x00000002));
    expect(theme.textColor, const Color(0x00000003));
    expect(theme.contentPadding, const EdgeInsets.all(100));
    expect(theme.tileColor, const Color(0x00000004));
    expect(theme.selectedTileColor, const Color(0x00000005));
    expect(theme.horizontalTitleGap, 200);
    expect(theme.minVerticalPadding, 300);
    expect(theme.minLeadingWidth, 400);
    expect(theme.enableFeedback, true);
    expect(theme.mouseCursor, MaterialStateMouseCursor.clickable);
  });

  testWidgets('ListTileTheme', (WidgetTester tester) async {
    final Key listTileKey = UniqueKey();
    final Key titleKey = UniqueKey();
    final Key subtitleKey = UniqueKey();
    final Key leadingKey = UniqueKey();
    final Key trailingKey = UniqueKey();
    late ThemeData theme;

    Widget buildFrame({
      bool enabled = true,
      bool dense = false,
      bool selected = false,
      ShapeBorder? shape,
      Color? selectedColor,
      Color? iconColor,
      Color? textColor,
    }) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: ListTileTheme(
              data: ListTileThemeData(
                dense: dense,
                shape: shape,
                selectedColor: selectedColor,
                iconColor: iconColor,
                textColor: textColor,
                mouseCursor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled)) {
                    return SystemMouseCursors.forbidden;
                  }

                  return SystemMouseCursors.click;
                }),
                visualDensity: VisualDensity.compact,
              ),
              child: Builder(
                builder: (BuildContext context) {
                  theme = Theme.of(context);
                  return ListTile(
                    key: listTileKey,
                    enabled: enabled,
                    selected: selected,
                    leading: TestIcon(key: leadingKey),
                    trailing: TestIcon(key: trailingKey),
                    title: TestText('title', key: titleKey),
                    subtitle: TestText('subtitle', key: subtitleKey),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    const Color green = Color(0xFF00FF00);
    const Color red = Color(0xFFFF0000);
    const ShapeBorder roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
    );

    Color iconColor(Key key) => tester.state<TestIconState>(find.byKey(key)).iconTheme.color!;
    Color textColor(Key key) => tester.state<TestTextState>(find.byKey(key)).textStyle.color!;
    ShapeBorder inkWellBorder() => tester.widget<InkWell>(find.descendant(of: find.byType(ListTile), matching: find.byType(InkWell))).customBorder!;

    // A selected ListTile's leading, trailing, and text get the primary color by default
    await tester.pumpWidget(buildFrame(selected: true));
    await tester.pump(const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), theme.primaryColor);
    expect(iconColor(trailingKey), theme.primaryColor);
    expect(textColor(titleKey), theme.primaryColor);
    expect(textColor(subtitleKey), theme.primaryColor);

    // A selected ListTile's leading, trailing, and text get the ListTileTheme's selectedColor
    await tester.pumpWidget(buildFrame(selected: true, selectedColor: green));
    await tester.pump(const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), green);
    expect(iconColor(trailingKey), green);
    expect(textColor(titleKey), green);
    expect(textColor(subtitleKey), green);

    // An unselected ListTile's leading and trailing get the ListTileTheme's iconColor
    // An unselected ListTile's title texts get the ListTileTheme's textColor
    await tester.pumpWidget(buildFrame(iconColor: red, textColor: green));
    await tester.pump(const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), red);
    expect(iconColor(trailingKey), red);
    expect(textColor(titleKey), green);
    expect(textColor(subtitleKey), green);

    // If the item is disabled it's rendered with the theme's disabled color.
    await tester.pumpWidget(buildFrame(enabled: false));
    await tester.pump(const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), theme.disabledColor);
    expect(iconColor(trailingKey), theme.disabledColor);
    expect(textColor(titleKey), theme.disabledColor);
    expect(textColor(subtitleKey), theme.disabledColor);

    // If the item is disabled it's rendered with the theme's disabled color.
    // Even if it's selected.
    await tester.pumpWidget(buildFrame(enabled: false, selected: true));
    await tester.pump(const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), theme.disabledColor);
    expect(iconColor(trailingKey), theme.disabledColor);
    expect(textColor(titleKey), theme.disabledColor);
    expect(textColor(subtitleKey), theme.disabledColor);

    // A selected ListTile's InkWell gets the ListTileTheme's shape
    await tester.pumpWidget(buildFrame(selected: true, shape: roundedShape));
    expect(inkWellBorder(), roundedShape);

    // Cursor updates when hovering disabled ListTile
    await tester.pumpWidget(buildFrame(enabled: false));
    final Offset listTile = tester.getCenter(find.byKey(titleKey));
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(listTile);
    await tester.pumpAndSettle();
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.forbidden);

    // VisualDensity is respected
    final RenderBox box = tester.renderObject(find.byKey(listTileKey));
    expect(box.size, equals(const Size(800, 64.0)));
  });

  testWidgets('ListTileTheme colors are applied to leading and trailing text widgets', (WidgetTester tester) async {
    final Key leadingKey = UniqueKey();
    final Key trailingKey = UniqueKey();

    const Color selectedColor = Colors.orange;
    const Color defaultColor = Colors.black;

    late ThemeData theme;
    Widget buildFrame({
      bool enabled = true,
      bool selected = false,
    }) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: ListTileTheme(
              data: const ListTileThemeData(
                selectedColor: selectedColor,
                textColor: defaultColor,
              ),
              child: Builder(
                builder: (BuildContext context) {
                  theme = Theme.of(context);
                  return ListTile(
                    enabled: enabled,
                    selected: selected,
                    leading: TestText('leading', key: leadingKey),
                    title: const TestText('title'),
                    trailing: TestText('trailing', key: trailingKey),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    Color textColor(Key key) => tester.state<TestTextState>(find.byKey(key)).textStyle.color!;

    await tester.pumpWidget(buildFrame());
    // Enabled color should use ListTileTheme.textColor.
    expect(textColor(leadingKey), defaultColor);
    expect(textColor(trailingKey), defaultColor);

    await tester.pumpWidget(buildFrame(selected: true));
    // Wait for text color to animate.
    await tester.pumpAndSettle();
    // Selected color should use ListTileTheme.selectedColor.
    expect(textColor(leadingKey), selectedColor);
    expect(textColor(trailingKey), selectedColor);

    await tester.pumpWidget(buildFrame(enabled: false));
    // Wait for text color to animate.
    await tester.pumpAndSettle();
    // Disabled color should be ThemeData.disabledColor.
    expect(textColor(leadingKey), theme.disabledColor);
    expect(textColor(trailingKey), theme.disabledColor);
  });

  testWidgets("ListTile respects ListTileTheme's tileColor & selectedTileColor", (WidgetTester tester) async {
    late ListTileThemeData theme;
    bool isSelected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListTileTheme(
            data: ListTileThemeData(
              tileColor: Colors.green.shade500,
              selectedTileColor: Colors.red.shade500,
            ),
            child: Center(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  theme = ListTileTheme.of(context);
                  return ListTile(
                    selected: isSelected,
                    onTap: () {
                      setState(()=> isSelected = !isSelected);
                    },
                    title: const Text('Title'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Material), paints..path(color: theme.tileColor));

    // Tap on tile to change isSelected.
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    expect(find.byType(Material), paints..path(color: theme.selectedTileColor));
  });

  testWidgets("ListTileTheme's tileColor & selectedTileColor are overridden by ListTile properties", (WidgetTester tester) async {
    bool isSelected = false;
    final Color tileColor = Colors.green.shade500;
    final Color selectedTileColor = Colors.red.shade500;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListTileTheme(
            data: const ListTileThemeData(
              selectedTileColor: Colors.green,
              tileColor: Colors.red,
            ),
            child: Center(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return ListTile(
                    tileColor: tileColor,
                    selectedTileColor: selectedTileColor,
                    selected: isSelected,
                    onTap: () {
                      setState(()=> isSelected = !isSelected);
                    },
                    title: const Text('Title'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Material), paints..path(color: tileColor));

    // Tap on tile to change isSelected.
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    expect(find.byType(Material), paints..path(color: selectedTileColor));
  });

  testWidgets('ListTile uses ListTileTheme shape in a drawer', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/106303

    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final ShapeBorder shapeBorder =  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0));

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        listTileTheme: ListTileThemeData(shape: shapeBorder),
      ),
      home: Scaffold(
        key: scaffoldKey,
        drawer: const Drawer(
          child: ListTile(),
        ),
        body: Container(),
      ),
    ));
    await tester.pumpAndSettle();

    scaffoldKey.currentState!.openDrawer();
    // Start drawer animation.
    await tester.pump();

    final ShapeBorder? inkWellBorder = tester.widget<InkWell>(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.byType(InkWell),
    )).customBorder;
    // Test shape.
    expect(inkWellBorder, shapeBorder);
  });
}
