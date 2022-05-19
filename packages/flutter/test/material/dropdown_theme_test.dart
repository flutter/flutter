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

final Type dropdownButtonType = DropdownButton<String>(
  onChanged: (_) { },
  items: const <DropdownMenuItem<String>>[],
).runtimeType;

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
  VoidCallback? onTap,
  Widget? icon,
  Color? iconDisabledColor,
  Color? iconEnabledColor,
  double iconSize = 24.0,
  bool isDense = false,
  bool isExpanded = false,
  Widget? hint,
  Widget? disabledHint,
  Widget? underline,
  List<String>? items = menuItems,
  List<Widget> Function(BuildContext)? selectedItemBuilder,
  double? itemHeight = kMinInteractiveDimension,
  AlignmentDirectional alignment = AlignmentDirectional.centerStart,
  TextDirection textDirection = TextDirection.ltr,
  Size? mediaSize,
  FocusNode? focusNode,
  bool autofocus = false,
  Color? focusColor,
  Color? dropdownColor,
  double? menuMaxHeight,
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
        hint: hint,
        disabledHint: disabledHint,
        onChanged: onChanged,
        onTap: onTap,
        icon: icon,
        iconSize: iconSize,
        iconDisabledColor: iconDisabledColor,
        iconEnabledColor: iconEnabledColor,
        isDense: isDense,
        isExpanded: isExpanded,
        // No underline attribute
        focusNode: focusNode,
        autofocus: autofocus,
        focusColor: focusColor,
        dropdownColor: dropdownColor,
        items: listItems,
        selectedItemBuilder: selectedItemBuilder,
        itemHeight: itemHeight,
        alignment: alignment,
        menuMaxHeight: menuMaxHeight,
      ),
    );
  }
  return DropdownButton<String>(
    key: buttonKey,
    value: value,
    hint: hint,
    disabledHint: disabledHint,
    onChanged: onChanged,
    onTap: onTap,
    icon: icon,
    iconSize: iconSize,
    iconDisabledColor: iconDisabledColor,
    iconEnabledColor: iconEnabledColor,
    isDense: isDense,
    isExpanded: isExpanded,
    underline: underline,
    focusNode: focusNode,
    autofocus: autofocus,
    focusColor: focusColor,
    dropdownColor: dropdownColor,
    items: listItems,
    selectedItemBuilder: selectedItemBuilder,
    itemHeight: itemHeight,
    alignment: alignment,
    menuMaxHeight: menuMaxHeight,
  );
}

Widget buildFrame({
  Key? buttonKey,
  String? value = 'two',
  ValueChanged<String?>? onChanged,
  VoidCallback? onTap,
  Widget? icon,
  Color? iconDisabledColor,
  Color? iconEnabledColor,
  double iconSize = 24.0,
  bool isDense = false,
  bool isExpanded = false,
  Widget? hint,
  Widget? disabledHint,
  Widget? underline,
  List<String>? items = menuItems,
  List<Widget> Function(BuildContext)? selectedItemBuilder,
  double? itemHeight = kMinInteractiveDimension,
  AlignmentDirectional alignment = AlignmentDirectional.centerStart,
  TextDirection textDirection = TextDirection.ltr,
  Size? mediaSize,
  FocusNode? focusNode,
  bool autofocus = false,
  Color? focusColor,
  Color? dropdownColor,
  bool isFormField = false,
  double? menuMaxHeight,
  Alignment dropdownAlignment = Alignment.center,
}) {
  return TestApp(
    textDirection: textDirection,
    mediaSize: mediaSize,
    child: Material(
      child: Align(
        alignment: dropdownAlignment,
        child: RepaintBoundary(
          child: buildDropdown(
            isFormField: isFormField,
            buttonKey: buttonKey,
            value: value,
            hint: hint,
            disabledHint: disabledHint,
            onChanged: onChanged,
            onTap: onTap,
            icon: icon,
            iconSize: iconSize,
            iconDisabledColor: iconDisabledColor,
            iconEnabledColor: iconEnabledColor,
            isDense: isDense,
            isExpanded: isExpanded,
            underline: underline,
            focusNode: focusNode,
            autofocus: autofocus,
            focusColor: focusColor,
            dropdownColor: dropdownColor,
            items: items,
            selectedItemBuilder: selectedItemBuilder,
            itemHeight: itemHeight,
            alignment: alignment,
            menuMaxHeight: menuMaxHeight,
          ),
        ),
      ),
    ),
  );
}

class TestApp extends StatefulWidget {
  const TestApp({
    super.key,
    required this.textDirection,
    required this.child,
    this.mediaSize,
  });

  final TextDirection textDirection;
  final Widget child;
  final Size? mediaSize;

  @override
  State<TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: MediaQuery(
        data: MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(size: widget.mediaSize),
        child: Directionality(
          textDirection: widget.textDirection,
          child: Navigator(
            onGenerateRoute: (RouteSettings settings) {
              assert(settings.name == '/');
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (BuildContext context) => widget.child,
              );
            },
          ),
        ),
      ),
    );
  }
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

  testWidgets('Passing no DropdownThemeData uses defaults ', (WidgetTester tester) async {
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
            autofocus: true,
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
            icon: customIcon,
            autofocus: true,
            focusNode: focusNode,
            onChanged: onChanged,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

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
            autofocus: true,
            focusNode: focusNode,
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

  testWidgets('Dropdown uses values from DropdownThemeData', (WidgetTester tester) async {
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
            autofocus: true,
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
            autofocus: true,
            focusNode: focusNode,
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
            autofocus: true,
            focusNode: focusNode,
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

  testWidgets('Dropdown uses local theme over global theme', (WidgetTester tester) async {
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
              inputDecorationTheme: const InputDecorationTheme(
                floatingLabelAlignment: FloatingLabelAlignment.center,
              ),
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
          child: buildDropdown(
            isFormField: true,
            icon: customIcon,
            autofocus: true,
            focusNode: focusNode,
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
  });
}
