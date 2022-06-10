// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

DropdownThemeData _dropdownTheme() {
  Color getColor(Set<MaterialState> states) {
    return states.contains(MaterialState.disabled) ? Colors.black26 : Colors.blue;
  }
  return DropdownThemeData(
    dropdownColor: const Color(0xff0000ff),
    style: const TextStyle(color: Colors.red),
    iconColor: MaterialStateProperty.resolveWith(
      (Set<MaterialState> states) => getColor(states),
    ),
    focusColor: const Color(0xff00ff00),
    borderRadius: BorderRadius.circular(18.0),
    menuMaxHeight: 180.0,
    inputDecorationTheme: const InputDecorationTheme(
      floatingLabelAlignment: FloatingLabelAlignment.center,
    ),
  );
}

const List<String> menuItems = <String>['one', 'two', 'three', 'four'];

void onChanged<T>(T _) { }

Set<MaterialState> enabled = <MaterialState>{ };

Finder _iconRichText(Key iconKey) {
  return find.descendant(
    of: find.byKey(iconKey),
    matching: find.byType(RichText),
  );
}

Widget buildDropdown({
  required bool isFormField,
  Key? buttonKey,
  String? value = 'two',
  ValueChanged<String?>? onChanged,
  Widget? icon,
  TextStyle? style,
  Color? iconDisabledColor,
  Color? iconEnabledColor,
  List<String>? items = menuItems,
  FocusNode? focusNode,
  bool autofocus = false,
  Color? focusColor,
  Color? dropdownColor,
  double? menuMaxHeight,
  BorderRadius? borderRadius,
  InputDecoration? decoration,
}) {
  final List<DropdownMenuItem<String>>? listItems = items?.map<DropdownMenuItem<String>>((String item) {
    return DropdownMenuItem<String>(
      key: ValueKey<String>(item),
      value: item,
      child: Text(item, key: ValueKey<String>('${item}Text')),
    );
  }).toList();

  if (isFormField) {
    return Form(
      child: DropdownButtonFormField<String>(
        key: buttonKey,
        value: value,
        onChanged: onChanged,
        icon: icon,
        style: style,
        iconDisabledColor: iconDisabledColor,
        iconEnabledColor: iconEnabledColor,
        // No underline attribute
        focusNode: focusNode,
        autofocus: autofocus,
        focusColor: focusColor,
        dropdownColor: dropdownColor,
        items: listItems,
        menuMaxHeight: menuMaxHeight,
        borderRadius: borderRadius,
        decoration: decoration,
      ),
    );
  }
  return DropdownButton<String>(
    key: buttonKey,
    value: value,
    onChanged: onChanged,
    icon: icon,
    style: style,
    iconDisabledColor: iconDisabledColor,
    iconEnabledColor: iconEnabledColor,
    focusNode: focusNode,
    autofocus: autofocus,
    focusColor: focusColor,
    dropdownColor: dropdownColor,
    items: listItems,
    menuMaxHeight: menuMaxHeight,
    borderRadius: borderRadius,
  );
}

void main() {
  test('DropdownThemeData copyWith, ==, hashCode basics', () {
    expect(const DropdownThemeData(), const DropdownThemeData().copyWith());
    expect(const DropdownThemeData().hashCode, const DropdownThemeData().copyWith().hashCode);
  });

  test('DropdownThemeData defaults', () {
    const DropdownThemeData theme = DropdownThemeData();
    expect(theme.dropdownColor, null);
    expect(theme.style, null);
    expect(theme.iconColor, null);
    expect(theme.focusColor, null);
    expect(theme.menuMaxHeight, null);
    expect(theme.borderRadius, null);
    expect(theme.inputDecorationTheme, null);
  });

  testWidgets('Default DropdownThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const DropdownThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('DropdownThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
     DropdownThemeData(
      dropdownColor: const Color(0xff00ff00),
      style: const TextStyle(color: Color(0xff000000)),
      iconColor: const MaterialStatePropertyAll<Color>(Color(0xff000000)),
      focusColor: const Color(0xff0000ff),
      menuMaxHeight: 200.0,
      borderRadius: BorderRadius.circular(20.0),
      inputDecorationTheme: const InputDecorationTheme(floatingLabelAlignment: FloatingLabelAlignment.center),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description[0], 'dropdownColor: Color(0xff00ff00)');
    expect(description[1], 'style: TextStyle(inherit: true, color: Color(0xff000000))');
    expect(description[2], 'iconColor: MaterialStatePropertyAll(Color(0xff000000))');
    expect(description[3], 'focusColor: Color(0xff0000ff)');
    expect(description[4], 'menuMaxHeight: 200.0');
    expect(description[5], 'borderRadius: BorderRadius.circular(20.0)');
    expect(
      description[6],
      equalsIgnoringHashCodes('inputDecorationTheme: InputDecorationTheme#00000(floatingLabelAlignment: FloatingLabelAlignment.center)'),
    );
  });

  testWidgets('Dropdown default properties', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    final Key iconKey = UniqueKey();
    final Icon customIcon = Icon(Icons.assessment, key: iconKey);
    final FocusNode focusNode = FocusNode(debugLabel: 'DropdownButton');
    const String value = 'two';

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: buildDropdown(
            isFormField: false,
            icon: customIcon,
            focusNode: focusNode,
            onChanged: onChanged,
          ),
        ),
      ),
    ));

    WidgetsBinding.instance.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    // Test `focusColor`.
    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: const Color(0x1f000000)));

    // Test `style`.
    Color textColor(String text) {
      return tester.renderObject<RenderParagraph>(find.text(text)).text.style!.color!;
    }
    expect(textColor('two'), const Color(0xdd000000));

    // Test enabled `iconColor`.
    final RichText enabledIconRichText = tester.widget<RichText>(_iconRichText(iconKey));
    expect(enabledIconRichText.text.style!.color, Colors.grey.shade700);

    await tester.tap(find.text(value));
    await tester.pumpAndSettle();

    // Test `menuMaxHeight` and `borderRadius`.
    expect(
      find.ancestor(
        of: find.text(value).last,
        matching: find.byType(CustomPaint),
      ).at(2),
      paints
        ..save()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect(rrect: const RRect.fromLTRBXY(0.0, 0.0, 144.0, 208.0, 2.0, 2.0)),
    );

    // Test `dropdownColor`.
    expect(
      find.ancestor(
        of: find.text(value).last,
        matching: find.byType(CustomPaint),
      ).at(2),
      paints
        ..save()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect(color: Colors.grey[50], hasMaskFilter: false),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: buildDropdown(
            isFormField: true,
            onChanged: onChanged,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Test `decoration`.
    final InputDecoration inputDecoration = tester.widget<InputDecorator>(
      find.byType(InputDecorator)
    ).decoration;
    expect(inputDecoration.floatingLabelAlignment, FloatingLabelAlignment.start);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: buildDropdown(
            isFormField: false,
            icon: customIcon,
            items: null,
            onChanged: onChanged,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Test disabled `iconColor`.
    final RichText disabledIconRichText = tester.widget<RichText>(_iconRichText(iconKey));
    expect(disabledIconRichText.text.style!.color, Colors.grey.shade400);
  });

  testWidgets('Dropdown can be customized using DropdownThemeData', (WidgetTester tester) async {
    final Key iconKey = UniqueKey();
    final Icon customIcon = Icon(Icons.assessment, key: iconKey);
    const String value = 'two';
    final FocusNode focusNode = FocusNode(debugLabel: 'DropdownButton');

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(dropdownTheme: _dropdownTheme()),
      home: Scaffold(
        body: Center(
          child: buildDropdown(
            isFormField: false,
            icon: customIcon,
            focusNode: focusNode,
            onChanged: onChanged,
          ),
        ),
      ),
    ));

    WidgetsBinding.instance.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    focusNode.requestFocus();
    await tester.pumpAndSettle();

    // Test `focusColor`.
    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: const Color(0xff00ff00)));

    // Test `style`.
    Color textColor(String text) {
      return tester.renderObject<RenderParagraph>(find.text(text)).text.style!.color!;
    }
    expect(textColor('two'), Colors.red);

    // Test `iconColor`.
    final RichText enabledIconRichText = tester.widget<RichText>(_iconRichText(iconKey));
    expect(enabledIconRichText.text.style!.color, Colors.blue);

    await tester.tap(find.text(value));
    await tester.pumpAndSettle();

    // Test `menuMaxHeight` and `borderRadius`.
    expect(
      find.ancestor(
        of: find.text(value).last,
        matching: find.byType(CustomPaint),
      ).at(2),
      paints
        ..save()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect(rrect: const RRect.fromLTRBXY(0.0, 0.0, 134.0, 180.0, 18.0, 18.0)),
    );

    // Test `dropdownColor`.
    expect(
      find.ancestor(
        of: find.text(value).last,
        matching: find.byType(CustomPaint),
      ).at(2),
      paints
        ..save()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect(color: const Color(0xff0000ff), hasMaskFilter: false),
    );

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(dropdownTheme: _dropdownTheme()),
      home: Scaffold(
        body: Center(
          child: buildDropdown(
            isFormField: true,
            icon: customIcon,
            onChanged: onChanged,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final InputDecoration inputDecoration = tester.widget<InputDecorator>(
      find.byType(InputDecorator)
    ).decoration;
    expect(inputDecoration.floatingLabelAlignment, FloatingLabelAlignment.center);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(dropdownTheme: _dropdownTheme()),
      home: Scaffold(
        body: Center(
          child: buildDropdown(
            isFormField: false,
            icon: customIcon,
            items: null,
            onChanged: onChanged,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Test disabled `iconColor`.
    final RichText disabledIconRichText = tester.widget<RichText>(_iconRichText(iconKey));
    expect(disabledIconRichText.text.style!.color, Colors.black26);
  });

  testWidgets('Local DropdownTheme overrides global DropdownTheme', (WidgetTester tester) async {
    final Key iconKey = UniqueKey();
    final Icon customIcon = Icon(Icons.assessment, key: iconKey);
    const String value = 'two';
    final FocusNode focusNode = FocusNode(debugLabel: 'DropdownButton');

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(dropdownTheme: _dropdownTheme()),
      home: Scaffold(
        body: Center(
          child: DropdownTheme(
            data: DropdownThemeData(
              dropdownColor: const Color(0xffff0000),
              style: const TextStyle(color: Colors.green),
              iconColor: MaterialStateProperty.resolveWith(
                (Set<MaterialState> states) {
                  return states.contains(MaterialState.disabled)
                    ? Colors.grey[200]
                    : Colors.purple;
                },
              ),
              focusColor: const Color(0xffedef00),
              borderRadius: BorderRadius.circular(24.0),
              menuMaxHeight: 150.0,
            ),
            child: buildDropdown(
              isFormField: false,
              icon: customIcon,
              autofocus: true,
              focusNode: focusNode,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ));

    WidgetsBinding.instance.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    focusNode.requestFocus();
    await tester.pumpAndSettle();

    // Test `focusColor`.
    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: const Color(0xffedef00)));

    // Test `style`.
    Color textColor(String text) {
      return tester.renderObject<RenderParagraph>(find.text(text)).text.style!.color!;
    }
    expect(textColor('two'), Colors.green);

    // Test `iconColor`.
    final RichText enabledIconRichText = tester.widget<RichText>(_iconRichText(iconKey));
    expect(enabledIconRichText.text.style!.color, Colors.purple);

    await tester.tap(find.text(value));
    await tester.pumpAndSettle();

    // Test `menuMaxHeight` and `borderRadius`.
    expect(
      find.ancestor(
        of: find.text(value).last,
        matching: find.byType(CustomPaint),
      ).at(2),
      paints
        ..save()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect(rrect: const RRect.fromLTRBXY(0.0, 0.0, 134.0, 150.0, 24.0, 24.0)),
    );

    // Test `dropdownColor`.
    expect(
      find.ancestor(
        of: find.text(value).last,
        matching: find.byType(CustomPaint),
      ).at(2),
      paints
        ..save()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect(color: const Color(0xffff0000), hasMaskFilter: false),
    );

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(dropdownTheme: _dropdownTheme()),
      home: Scaffold(
        body: Center(
          child: DropdownTheme(
            data: const DropdownThemeData(
              inputDecorationTheme: InputDecorationTheme()
            ),
            child: buildDropdown(
              isFormField: true,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final InputDecoration inputDecoration = tester.widget<InputDecorator>(
      find.byType(InputDecorator)
    ).decoration;
    expect(inputDecoration.floatingLabelAlignment, FloatingLabelAlignment.start);
  });

  testWidgets('Dropdown properties override DropdownThemeData properties', (WidgetTester tester) async {
    final Key iconKey = UniqueKey();
    final Icon customIcon = Icon(Icons.assessment, key: iconKey);
    const String value = 'two';
    final FocusNode focusNode = FocusNode(debugLabel: 'DropdownButton');
    const Color dropdownColor = Color(0xff00ffff);
    const TextStyle textStyle = TextStyle(color: Color(0xff124356));
    final MaterialStateProperty<Color> iconColor = MaterialStateProperty.all<Color>(
      const Color(0xff212121),
    );
    const Color focusColor = Color(0xff8012ff);
    final BorderRadius borderRadius = BorderRadius.circular(30.0);
    const double menuMaxHeight = 160.0;
    const InputDecoration inputDecoration = InputDecoration(
      floatingLabelAlignment: FloatingLabelAlignment.start,
    );

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(dropdownTheme: _dropdownTheme()),
      home: Scaffold(
        body: Center(
          child: buildDropdown(
            isFormField: false,
            autofocus: true,
            icon: customIcon,
            focusNode: focusNode,
            dropdownColor: dropdownColor,
            style: textStyle,
            iconEnabledColor: iconColor.resolve(enabled),
            focusColor: focusColor,
            borderRadius: borderRadius,
            menuMaxHeight: menuMaxHeight,
            onChanged: onChanged,
          ),
        ),
      ),
    ));

    WidgetsBinding.instance.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    focusNode.requestFocus();
    await tester.pumpAndSettle();

    // Test `focusColor`.
    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: focusColor));

    // Test `style`.
    Color textColor(String text) {
      return tester.renderObject<RenderParagraph>(find.text(text)).text.style!.color!;
    }
    expect(textColor('two'), textStyle.color);

    // Test `iconColor`.
    final RichText enabledIconRichText = tester.widget<RichText>(_iconRichText(iconKey));
    expect(enabledIconRichText.text.style!.color, iconColor.resolve(enabled));

    await tester.tap(find.text(value));
    await tester.pumpAndSettle();

    // Test `menuMaxHeight` and `borderRadius`.
    expect(
      find.ancestor(
        of: find.text(value).last,
        matching: find.byType(CustomPaint),
      ).at(2),
      paints
        ..save()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect(rrect: const RRect.fromLTRBXY(
          0.0,
          0.0,
          134.0,
          menuMaxHeight,
          30.0,
          30.0,
        )),
    );

    // Test `dropdownColor`.
    expect(
      find.ancestor(
        of: find.text(value).last,
        matching: find.byType(CustomPaint),
      ).at(2),
      paints
        ..save()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect(color: dropdownColor, hasMaskFilter: false),
    );

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(dropdownTheme: _dropdownTheme()),
      home: Scaffold(
        body: Center(
          child: buildDropdown(
            isFormField: true,
            decoration: inputDecoration,
            onChanged: onChanged,
          ),
        ),
      ),
    ));

    final InputDecoration decoration = tester.widget<InputDecorator>(
      find.byType(InputDecorator)
    ).decoration;
    expect(decoration.floatingLabelAlignment, inputDecoration.floatingLabelAlignment);
  });
}
