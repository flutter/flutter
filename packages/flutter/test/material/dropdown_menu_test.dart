// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String longText = 'one two three four five six seven eight nine ten eleven twelve';
  final List<DropdownMenuEntry<TestMenu>> menuChildren = <DropdownMenuEntry<TestMenu>>[];

  for (final TestMenu value in TestMenu.values) {
    final DropdownMenuEntry<TestMenu> entry = DropdownMenuEntry<TestMenu>(value: value, label: value.label);
    menuChildren.add(entry);
  }

  Widget buildTest<T extends Enum>(ThemeData themeData, List<DropdownMenuEntry<T>> entries,
      {double? width, double? menuHeight, Widget? leadingIcon, Widget? label}) {
    return MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: DropdownMenu<T>(
          label: label,
          leadingIcon: leadingIcon,
          width: width,
          menuHeight: menuHeight,
          dropdownMenuEntries: entries,
        ),
      ),
    );
  }

  testWidgets('DropdownMenu defaults', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(buildTest(themeData, menuChildren));

    final EditableText editableText = tester.widget(find.byType(EditableText));
    expect(editableText.style.color, themeData.textTheme.bodyLarge!.color);
    expect(editableText.style.background, themeData.textTheme.bodyLarge!.background);
    expect(editableText.style.shadows, themeData.textTheme.bodyLarge!.shadows);
    expect(editableText.style.decoration, themeData.textTheme.bodyLarge!.decoration);
    expect(editableText.style.locale, themeData.textTheme.bodyLarge!.locale);
    expect(editableText.style.wordSpacing, themeData.textTheme.bodyLarge!.wordSpacing);
    expect(editableText.style.fontSize, 16.0);
    expect(editableText.style.height, 1.5);

    final TextField textField = tester.widget(find.byType(TextField));
    expect(textField.decoration?.border, const OutlineInputBorder());
    expect(textField.style?.fontSize, 16.0);
    expect(textField.style?.height, 1.5);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_drop_down).first);
    await tester.pump();
    expect(find.byType(MenuAnchor), findsOneWidget);

    final Finder menuMaterial = find.ancestor(
      of: find.widgetWithText(TextButton, TestMenu.mainMenu0.label),
      matching: find.byType(Material),
    ).last;
    Material material = tester.widget<Material>(menuMaterial);
    expect(material.color, themeData.colorScheme.surface);
    expect(material.shadowColor, themeData.colorScheme.shadow);
    expect(material.surfaceTintColor, themeData.colorScheme.surfaceTint);
    expect(material.elevation, 3.0);
    expect(material.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))));

    final Finder buttonMaterial = find.descendant(
      of: find.byType(TextButton),
      matching: find.byType(Material),
    ).last;

    material = tester.widget<Material>(buttonMaterial);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shape, const RoundedRectangleBorder());
    expect(material.textStyle?.color, themeData.colorScheme.onSurface);
    expect(material.textStyle?.fontSize, 14.0);
    expect(material.textStyle?.height, 1.43);
  });

  testWidgets('DropdownMenu can be disabled', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(
      MaterialApp(
        theme: themeData,
        home: Scaffold(
          body: SafeArea(
            child: DropdownMenu<TestMenu>(
              enabled: false,
              dropdownMenuEntries: menuChildren,
            ),
          ),
        ),
      ),
    );

    final TextField textField = tester.widget(find.byType(TextField));
    expect(textField.decoration?.enabled, false);
    final Finder menuMaterial = find.ancestor(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Material),
    );
    expect(menuMaterial, findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    final Finder updatedMenuMaterial = find.ancestor(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Material),
    );
    expect(updatedMenuMaterial, findsNothing);
  });

  testWidgets('Material2 - The width of the text field should always be the same as the menu view',
    (WidgetTester tester) async {

    final ThemeData themeData = ThemeData(useMaterial3: false);
    await tester.pumpWidget(
      MaterialApp(
        theme: themeData,
        home: Scaffold(
          body: SafeArea(
            child: DropdownMenu<TestMenu>(
              dropdownMenuEntries: menuChildren,
            ),
          ),
        ),
      )
    );

    final Finder textField = find.byType(TextField);
    final Size anchorSize = tester.getSize(textField);
    expect(anchorSize, const Size(180.0, 56.0));

    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pumpAndSettle();

    final Finder menuMaterial = find.ancestor(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Material),
    );
    final Size menuSize = tester.getSize(menuMaterial);
    expect(menuSize, const Size(180.0, 304.0));

    // The text field should have same width as the menu
    // when the width property is not null.
    await tester.pumpWidget(buildTest(themeData, menuChildren, width: 200.0));

    final Finder anchor = find.byType(TextField);
    final double width = tester.getSize(anchor).width;
    expect(width, 200.0);

    await tester.tap(anchor);
    await tester.pumpAndSettle();

    final Finder updatedMenu = find.ancestor(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Material),
    );
    final double updatedMenuWidth = tester.getSize(updatedMenu).width;
    expect(updatedMenuWidth, 200.0);
  });

  testWidgets('Material3 - The width of the text field should always be the same as the menu view',
    (WidgetTester tester) async {
    final ThemeData themeData = ThemeData(useMaterial3: true);
    await tester.pumpWidget(
        MaterialApp(
          theme: themeData,
          home: Scaffold(
            body: SafeArea(
              child: DropdownMenu<TestMenu>(
                dropdownMenuEntries: menuChildren,
              ),
            ),
          ),
        )
    );

    final Finder textField = find.byType(TextField);
    final double anchorWidth = tester.getSize(textField).width;
    expect(anchorWidth, closeTo(180.5, 0.1));

    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pumpAndSettle();

    final Finder menuMaterial = find.ancestor(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Material),
    );
    final double menuWidth = tester.getSize(menuMaterial).width;
    expect(menuWidth, closeTo(180.5, 0.1));

    // The text field should have same width as the menu
    // when the width property is not null.
    await tester.pumpWidget(buildTest(themeData, menuChildren, width: 200.0));

    final Finder anchor = find.byType(TextField);
    final double width = tester.getSize(anchor).width;
    expect(width, 200.0);

    await tester.tap(anchor);
    await tester.pumpAndSettle();

    final Finder updatedMenu = find.ancestor(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Material),
    );
    final double updatedMenuWidth = tester.getSize(updatedMenu).width;
    expect(updatedMenuWidth, 200.0);
  });

  testWidgets('The width property can customize the width of the dropdown menu', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    final List<DropdownMenuEntry<ShortMenu>> shortMenuItems = <DropdownMenuEntry<ShortMenu>>[];

    for (final ShortMenu value in ShortMenu.values) {
      final DropdownMenuEntry<ShortMenu> entry = DropdownMenuEntry<ShortMenu>(value: value, label: value.label);
      shortMenuItems.add(entry);
    }

    const double customBigWidth = 250.0;
    await tester.pumpWidget(buildTest(themeData, shortMenuItems, width: customBigWidth));
    RenderBox box = tester.firstRenderObject(find.byType(DropdownMenu<ShortMenu>));
    expect(box.size.width, customBigWidth);

    await tester.tap(find.byType(DropdownMenu<ShortMenu>));
    await tester.pump();
    expect(find.byType(MenuItemButton), findsNWidgets(6));
    Size buttonSize = tester.getSize(find.widgetWithText(MenuItemButton, 'I0').last);
    expect(buttonSize.width, customBigWidth);

    // reset test
    await tester.pumpWidget(Container());
    const double customSmallWidth = 100.0;
    await tester.pumpWidget(buildTest(themeData, shortMenuItems, width: customSmallWidth));
    box = tester.firstRenderObject(find.byType(DropdownMenu<ShortMenu>));
    expect(box.size.width, customSmallWidth);

    await tester.tap(find.byType(DropdownMenu<ShortMenu>));
    await tester.pump();
    expect(find.byType(MenuItemButton), findsNWidgets(6));
    buttonSize = tester.getSize(find.widgetWithText(MenuItemButton, 'I0').last);
    expect(buttonSize.width, customSmallWidth);
  });

  testWidgets('The width property update test', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/120567
    final ThemeData themeData = ThemeData();
    final List<DropdownMenuEntry<ShortMenu>> shortMenuItems = <DropdownMenuEntry<ShortMenu>>[];

    for (final ShortMenu value in ShortMenu.values) {
      final DropdownMenuEntry<ShortMenu> entry = DropdownMenuEntry<ShortMenu>(value: value, label: value.label);
      shortMenuItems.add(entry);
    }

    double customWidth = 250.0;
    await tester.pumpWidget(buildTest(themeData, shortMenuItems, width: customWidth));
    RenderBox box = tester.firstRenderObject(find.byType(DropdownMenu<ShortMenu>));
    expect(box.size.width, customWidth);

    // Update width
    customWidth = 400.0;
    await tester.pumpWidget(buildTest(themeData, shortMenuItems, width: customWidth));
    box = tester.firstRenderObject(find.byType(DropdownMenu<ShortMenu>));
    expect(box.size.width, customWidth);
  });

  testWidgets('The width of MenuAnchor respects MenuAnchor.expandedInsets', (WidgetTester tester) async {
    const double parentWidth = 500.0;
    final List<DropdownMenuEntry<ShortMenu>> shortMenuItems = <DropdownMenuEntry<ShortMenu>>[];
    for (final ShortMenu value in ShortMenu.values) {
      final DropdownMenuEntry<ShortMenu> entry = DropdownMenuEntry<ShortMenu>(value: value, label: value.label);
      shortMenuItems.add(entry);
    }
    Widget buildMenuAnchor({EdgeInsets? expandedInsets}) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: parentWidth,
            height: parentWidth,
            child: DropdownMenu<ShortMenu>(
              expandedInsets: expandedInsets,
              dropdownMenuEntries: shortMenuItems,
            ),
          ),
        ),
      );
    }

    // By default, the width of the text field is determined by the menu children.
    await tester.pumpWidget(buildMenuAnchor());
    RenderBox box = tester.firstRenderObject(find.byType(TextField));
    expect(box.size.width, 136.0);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    Size buttonSize = tester.getSize(find.widgetWithText(MenuItemButton, 'I0').hitTestable());
    expect(buttonSize.width, 136.0);

    // If expandedInsets is EdgeInsets.zero, the width should be the same as its parent.
    await tester.pumpWidget(Container());
    await tester.pumpWidget(buildMenuAnchor(expandedInsets: EdgeInsets.zero));
    box = tester.firstRenderObject(find.byType(TextField));
    expect(box.size.width, parentWidth);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    buttonSize = tester.getSize(find.widgetWithText(MenuItemButton, 'I0'));
    expect(buttonSize.width, parentWidth);

    // If expandedInsets is not zero, the width of the text field should be adjusted
    // based on the EdgeInsets.left and EdgeInsets.right. The top and bottom values
    // will be ignored.
    await tester.pumpWidget(Container());
    await tester.pumpWidget(buildMenuAnchor(expandedInsets: const EdgeInsets.only(left: 35.0, top: 50.0, right: 20.0)));
    box = tester.firstRenderObject(find.byType(TextField));
    expect(box.size.width, parentWidth - 35.0 - 20.0);
    final Rect containerRect = tester.getRect(find.byType(SizedBox).first);
    final Rect dropdownMenuRect = tester.getRect(find.byType(TextField));
    expect(dropdownMenuRect.top, containerRect.top);


    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    buttonSize = tester.getSize(find.widgetWithText(MenuItemButton, 'I0'));
    expect(buttonSize.width, parentWidth - 35.0 - 20.0);
  });

  testWidgets('Material2 - The menuHeight property can be used to show a shorter scrollable menu list instead of the complete list',
    (WidgetTester tester) async {
    final ThemeData themeData = ThemeData(useMaterial3: false);
    await tester.pumpWidget(buildTest(themeData, menuChildren));

    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pumpAndSettle();

    final Element firstItem = tester.element(find.widgetWithText(MenuItemButton, 'Item 0').last);
    final RenderBox firstBox = firstItem.renderObject! as RenderBox;
    final Offset topLeft = firstBox.localToGlobal(firstBox.size.topLeft(Offset.zero));
    final Element lastItem = tester.element(find.widgetWithText(MenuItemButton, 'Item 5').last);
    final RenderBox lastBox = lastItem.renderObject! as RenderBox;
    final Offset bottomRight = lastBox.localToGlobal(lastBox.size.bottomRight(Offset.zero));
    // height = height of MenuItemButton * 6 = 48 * 6
    expect(bottomRight.dy - topLeft.dy, 288.0);

    final Finder menuView = find.ancestor(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Padding),
    ).first;
    final Size menuViewSize = tester.getSize(menuView);
    expect(menuViewSize, const Size(180.0, 304.0)); // 304 = 288 + vertical padding(2 * 8)

    // Constrains the menu height.
    await tester.pumpWidget(Container());
    await tester.pumpWidget(buildTest(themeData, menuChildren, menuHeight: 100));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pumpAndSettle();

    final Finder updatedMenu = find.ancestor(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Padding),
    ).first;

    final Size updatedMenuSize = tester.getSize(updatedMenu);
    expect(updatedMenuSize, const Size(180.0, 100.0));
  });

  testWidgets('Material3 - The menuHeight property can be used to show a shorter scrollable menu list instead of the complete list',
    (WidgetTester tester) async {
  final ThemeData themeData = ThemeData(useMaterial3: true);
  await tester.pumpWidget(buildTest(themeData, menuChildren));

  await tester.tap(find.byType(DropdownMenu<TestMenu>));
  await tester.pumpAndSettle();

  final Element firstItem = tester.element(find.widgetWithText(MenuItemButton, 'Item 0').last);
  final RenderBox firstBox = firstItem.renderObject! as RenderBox;
  final Offset topLeft = firstBox.localToGlobal(firstBox.size.topLeft(Offset.zero));
  final Element lastItem = tester.element(find.widgetWithText(MenuItemButton, 'Item 5').last);
  final RenderBox lastBox = lastItem.renderObject! as RenderBox;
  final Offset bottomRight = lastBox.localToGlobal(lastBox.size.bottomRight(Offset.zero));
  // height = height of MenuItemButton * 6 = 48 * 6
  expect(bottomRight.dy - topLeft.dy, 288.0);

  final Finder menuView = find.ancestor(
    of: find.byType(SingleChildScrollView),
    matching: find.byType(Padding),
  ).first;
  final Size menuViewSize = tester.getSize(menuView);
  expect(menuViewSize.width, closeTo(180.6, 0.1));
  expect(menuViewSize.height, equals(304.0)); // 304 = 288 + vertical padding(2 * 8)

  // Constrains the menu height.
  await tester.pumpWidget(Container());
  await tester.pumpWidget(buildTest(themeData, menuChildren, menuHeight: 100));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(DropdownMenu<TestMenu>));
  await tester.pumpAndSettle();

  final Finder updatedMenu = find.ancestor(
    of: find.byType(SingleChildScrollView),
    matching: find.byType(Padding),
  ).first;

  final Size updatedMenuSize = tester.getSize(updatedMenu);
  expect(updatedMenuSize.width, closeTo(180.6, 0.1));
  expect(updatedMenuSize.height, equals(100.0));
});

  testWidgets('The text in the menu button should be aligned with the text of '
    'the text field - LTR', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    // Default text field (without leading icon).
    await tester.pumpWidget(buildTest(themeData, menuChildren, label: const Text('label')));

    final Finder label = find.text('label');
    final Offset labelTopLeft = tester.getTopLeft(label);

    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pumpAndSettle();
    final Finder itemText = find.text('Item 0').last;
    final Offset itemTextTopLeft = tester.getTopLeft(itemText);

    expect(labelTopLeft.dx, equals(itemTextTopLeft.dx));

    // Test when the text field has a leading icon.
    await tester.pumpWidget(Container());
    await tester.pumpWidget(buildTest(themeData, menuChildren,
      leadingIcon: const Icon(Icons.search),
      label: const Text('label'),
    ));

    final Finder leadingIcon = find.widgetWithIcon(Container, Icons.search);
    final double iconWidth = tester.getSize(leadingIcon).width;
    final Finder updatedLabel = find.text('label');
    final Offset updatedLabelTopLeft = tester.getTopLeft(updatedLabel);

    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pumpAndSettle();
    final Finder updatedItemText = find.text('Item 0').last;
    final Offset updatedItemTextTopLeft = tester.getTopLeft(updatedItemText);


    expect(updatedLabelTopLeft.dx, equals(updatedItemTextTopLeft.dx));
    expect(updatedLabelTopLeft.dx, equals(iconWidth));

    // Test when then leading icon is a widget with a bigger size.
    await tester.pumpWidget(Container());
    await tester.pumpWidget(buildTest(themeData, menuChildren,
      leadingIcon: const SizedBox(
        width: 75.0,
        child: Icon(Icons.search)),
      label: const Text('label'),
    ));

    final Finder largeLeadingIcon = find.widgetWithIcon(Container, Icons.search);
    final double largeIconWidth = tester.getSize(largeLeadingIcon).width;
    final Finder updatedLabel1 = find.text('label');
    final Offset updatedLabelTopLeft1 = tester.getTopLeft(updatedLabel1);

    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pumpAndSettle();
    final Finder updatedItemText1 = find.text('Item 0').last;
    final Offset updatedItemTextTopLeft1 = tester.getTopLeft(updatedItemText1);


    expect(updatedLabelTopLeft1.dx, equals(updatedItemTextTopLeft1.dx));
    expect(updatedLabelTopLeft1.dx, equals(largeIconWidth));
  });

  testWidgets('The text in the menu button should be aligned with the text of '
      'the text field - RTL', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    // Default text field (without leading icon).
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: DropdownMenu<TestMenu>(
            label: const Text('label'),
            dropdownMenuEntries: menuChildren,
          ),
        ),
      ),
    ));

    final Finder label = find.text('label');
    final Offset labelTopRight = tester.getTopRight(label);

    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pumpAndSettle();
    final Finder itemText = find.text('Item 0').last;
    final Offset itemTextTopRight = tester.getTopRight(itemText);

    expect(labelTopRight.dx, equals(itemTextTopRight.dx));

    // Test when the text field has a leading icon.
    await tester.pumpWidget(Container());
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: DropdownMenu<TestMenu>(
            leadingIcon: const Icon(Icons.search),
            label: const Text('label'),
            dropdownMenuEntries: menuChildren,
          ),
        ),
      ),
    ));
    await tester.pump();

    final Finder leadingIcon = find.widgetWithIcon(Container, Icons.search);
    final double iconWidth = tester.getSize(leadingIcon).width;
    final Offset dropdownMenuTopRight = tester.getTopRight(find.byType(DropdownMenu<TestMenu>));
    final Finder updatedLabel = find.text('label');
    final Offset updatedLabelTopRight = tester.getTopRight(updatedLabel);

    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pumpAndSettle();
    final Finder updatedItemText = find.text('Item 0').last;
    final Offset updatedItemTextTopRight = tester.getTopRight(updatedItemText);


    expect(updatedLabelTopRight.dx, equals(updatedItemTextTopRight.dx));
    expect(updatedLabelTopRight.dx, equals(dropdownMenuTopRight.dx - iconWidth));

    // Test when then leading icon is a widget with a bigger size.
    await tester.pumpWidget(Container());
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: DropdownMenu<TestMenu>(
            leadingIcon: const SizedBox(width: 75.0, child: Icon(Icons.search)),
            label: const Text('label'),
            dropdownMenuEntries: menuChildren,
          ),
        ),
      ),
    ));
    await tester.pump();

    final Finder largeLeadingIcon = find.widgetWithIcon(Container, Icons.search);
    final double largeIconWidth = tester.getSize(largeLeadingIcon).width;
    final Offset updatedDropdownMenuTopRight = tester.getTopRight(find.byType(DropdownMenu<TestMenu>));
    final Finder updatedLabel1 = find.text('label');
    final Offset updatedLabelTopRight1 = tester.getTopRight(updatedLabel1);

    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pumpAndSettle();
    final Finder updatedItemText1 = find.text('Item 0').last;
    final Offset updatedItemTextTopRight1 = tester.getTopRight(updatedItemText1);


    expect(updatedLabelTopRight1.dx, equals(updatedItemTextTopRight1.dx));
    expect(updatedLabelTopRight1.dx, equals(updatedDropdownMenuTopRight.dx - largeIconWidth));
  });

  testWidgets('DropdownMenu has default trailing icon button', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(buildTest(themeData, menuChildren));
    await tester.pump();

    final Finder iconButton = find.widgetWithIcon(IconButton, Icons.arrow_drop_down).first;
    expect(iconButton, findsOneWidget);

    await tester.tap(iconButton);
    await tester.pump();

    final Finder menuMaterial = find.ancestor(
      of: find.widgetWithText(MenuItemButton, TestMenu.mainMenu0.label),
      matching: find.byType(Material),
    ).last;
    expect(menuMaterial, findsOneWidget);
  });

  testWidgets('Leading IconButton status test', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData(useMaterial3: true);
    await tester.pumpWidget(buildTest(themeData, menuChildren, width: 100.0, menuHeight: 100.0));
    await tester.pump();

    Finder iconButton = find.widgetWithIcon(IconButton, Icons.arrow_drop_up);
    expect(iconButton, findsNothing);
    iconButton = find.widgetWithIcon(IconButton, Icons.arrow_drop_down).first;
    expect(iconButton, findsOneWidget);

    await tester.tap(iconButton);
    await tester.pump();

    iconButton = find.widgetWithIcon(IconButton, Icons.arrow_drop_up).first;
    expect(iconButton, findsOneWidget);
    iconButton = find.widgetWithIcon(IconButton, Icons.arrow_drop_down);
    expect(iconButton, findsNothing);

    // Tap outside
    await tester.tapAt(const Offset(500.0, 500.0));
    await tester.pump();

    iconButton = find.widgetWithIcon(IconButton, Icons.arrow_drop_up);
    expect(iconButton, findsNothing);
    iconButton = find.widgetWithIcon(IconButton, Icons.arrow_drop_down).first;
    expect(iconButton, findsOneWidget);
  });

  testWidgets('Do not crash when resize window during menu opening', (WidgetTester tester) async {
    addTearDown(tester.view.reset);
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState){
            return DropdownMenu<TestMenu>(
              width: MediaQuery.of(context).size.width,
              dropdownMenuEntries: menuChildren,
            );
          },
        ),
      ),
    ));

    final Finder iconButton = find.widgetWithIcon(IconButton, Icons.arrow_drop_down).first;
    expect(iconButton, findsOneWidget);

    await tester.tap(iconButton);
    await tester.pump();

    final Finder menuMaterial = find.ancestor(
      of: find.widgetWithText(MenuItemButton, TestMenu.mainMenu0.label),
      matching: find.byType(Material),
    ).last;
    expect(menuMaterial, findsOneWidget);

    // didChangeMetrics
    tester.view.physicalSize = const Size(700.0, 700.0);
    await tester.pump();

    // Go without throw.
  });

  testWidgets('DropdownMenu can customize trailing icon button', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: DropdownMenu<TestMenu>(
          trailingIcon: const Icon(Icons.ac_unit),
          dropdownMenuEntries: menuChildren,
        ),
      ),
    ));
    await tester.pump();

    final Finder iconButton = find.widgetWithIcon(IconButton, Icons.ac_unit).first;
    expect(iconButton, findsOneWidget);

    await tester.tap(iconButton);
    await tester.pump();

    final Finder menuMaterial = find.ancestor(
      of: find.widgetWithText(MenuItemButton, TestMenu.mainMenu0.label),
      matching: find.byType(Material),
    ).last;
    expect(menuMaterial, findsOneWidget);
  });

  testWidgets('Down key can highlight the menu item on desktop platforms', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: DropdownMenu<TestMenu>(
          trailingIcon: const Icon(Icons.ac_unit),
          dropdownMenuEntries: menuChildren,
        ),
      ),
    ));

    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pump();

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    Finder button0Material = find.descendant(
      of: find.widgetWithText(MenuItemButton, 'Item 0').last,
      matching: find.byType(Material),
    );

    Material item0material = tester.widget<Material>(button0Material);
    expect(item0material.color, themeData.colorScheme.onSurface.withOpacity(0.12));

    // Press down key one more time, the highlight should move to the next item.
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final Finder button1Material = find.descendant(
      of: find.widgetWithText(MenuItemButton, 'Menu 1').last,
      matching: find.byType(Material),
    );
    final Material item1material = tester.widget<Material>(button1Material);
    expect(item1material.color, themeData.colorScheme.onSurface.withOpacity(0.12));
    button0Material = find.descendant(
      of: find.widgetWithText(MenuItemButton, 'Item 0').last,
      matching: find.byType(Material),
    );
    item0material = tester.widget<Material>(button0Material);
    expect(item0material.color, Colors.transparent); // the previous item should not be highlighted.
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('Up key can highlight the menu item on desktop platforms', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: DropdownMenu<TestMenu>(
          dropdownMenuEntries: menuChildren,
        ),
      ),
    ));

    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pump();

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    Finder button5Material = find.descendant(
      of: find.widgetWithText(MenuItemButton, 'Item 5').last,
      matching: find.byType(Material),
    );

    Material item5material = tester.widget<Material>(button5Material);
    expect(item5material.color, themeData.colorScheme.onSurface.withOpacity(0.12));

    // Press up key one more time, the highlight should move up to the item 4.
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    final Finder button4Material = find.descendant(
      of: find.widgetWithText(MenuItemButton, 'Item 4').last,
      matching: find.byType(Material),
    );
    final Material item4material = tester.widget<Material>(button4Material);
    expect(item4material.color, themeData.colorScheme.onSurface.withOpacity(0.12));
    button5Material = find.descendant(
      of: find.widgetWithText(MenuItemButton, 'Item 5').last,
      matching: find.byType(Material),
    );

    item5material = tester.widget<Material>(button5Material);
    expect(item5material.color, Colors.transparent); // the previous item should not be highlighted.
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('The text input should match the label of the menu item '
      'while pressing down key on desktop platforms', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: DropdownMenu<TestMenu>(
          dropdownMenuEntries: menuChildren,
        ),
      ),
    ));

    // Open the menu
    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pump();

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Item 0'), findsOneWidget);

    // Press down key one more time to the next item.
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Menu 1'), findsOneWidget);

    // Press down to the next item.
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Item 2'), findsOneWidget);
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('The text input should match the label of the menu item '
      'while pressing up key on desktop platforms', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: DropdownMenu<TestMenu>(
          dropdownMenuEntries: menuChildren,
        ),
      ),
    ));

    // Open the menu
    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pump();

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Item 5'), findsOneWidget);

    // Press up key one more time to the upper item.
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Item 4'), findsOneWidget);

    // Press up to the upper item.
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Item 3'), findsOneWidget);
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('Disabled button will be skipped while pressing up/down key on desktop platforms', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    final List<DropdownMenuEntry<TestMenu>> menuWithDisabledItems = <DropdownMenuEntry<TestMenu>>[
      const DropdownMenuEntry<TestMenu>(value: TestMenu.mainMenu0, label: 'Item 0'),
      const DropdownMenuEntry<TestMenu>(value: TestMenu.mainMenu1, label: 'Item 1', enabled: false),
      const DropdownMenuEntry<TestMenu>(value: TestMenu.mainMenu2, label: 'Item 2', enabled: false),
      const DropdownMenuEntry<TestMenu>(value: TestMenu.mainMenu3, label: 'Item 3'),
      const DropdownMenuEntry<TestMenu>(value: TestMenu.mainMenu4, label: 'Item 4'),
      const DropdownMenuEntry<TestMenu>(value: TestMenu.mainMenu5, label: 'Item 5', enabled: false),
    ];
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: DropdownMenu<TestMenu>(
          dropdownMenuEntries: menuWithDisabledItems,
        ),
      ),
    ));
    await tester.pump();

    // Open the menu
    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pumpAndSettle();

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final Finder button0Material = find.descendant(
      of: find.widgetWithText(MenuItemButton, 'Item 0').last,
      matching: find.byType(Material),
    );
    final Material item0Material = tester.widget<Material>(button0Material);
    expect(item0Material.color, themeData.colorScheme.onSurface.withOpacity(0.12)); // first item can be highlighted as it's enabled.

    // Continue to press down key. Item 3 should be highlighted as Menu 1 and Item 2 are both disabled.
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final Finder button3Material = find.descendant(
      of: find.widgetWithText(MenuItemButton, 'Item 3').last,
      matching: find.byType(Material),
    );
    final Material item3Material = tester.widget<Material>(button3Material);
    expect(item3Material.color, themeData.colorScheme.onSurface.withOpacity(0.12));
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('Searching is enabled by default on mobile platforms if initialSelection is non null', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: DropdownMenu<TestMenu>(
          initialSelection: TestMenu.mainMenu1,
          dropdownMenuEntries: menuChildren,
        ),
      ),
    ));

    // Open the menu
    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pump();
    final Finder buttonMaterial = find.descendant(
      of: find.widgetWithText(MenuItemButton, 'Menu 1').last,
      matching: find.byType(Material),
    );
    final Material itemMaterial = tester.widget<Material>(buttonMaterial);
    expect(itemMaterial.color, themeData.colorScheme.onSurface.withOpacity(0.12)); // Menu 1 button is highlighted.
  }, variant: TargetPlatformVariant.mobile());

  testWidgets('Searching is enabled by default on desktop platform', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: DropdownMenu<TestMenu>(
          dropdownMenuEntries: menuChildren,
        ),
      ),
    ));

    // Open the menu
    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Menu 1');
    await tester.pumpAndSettle();
    final Finder buttonMaterial = find.descendant(
      of: find.widgetWithText(MenuItemButton, 'Menu 1').last,
      matching: find.byType(Material),
    );
    final Material itemMaterial = tester.widget<Material>(buttonMaterial);
    expect(itemMaterial.color, themeData.colorScheme.onSurface.withOpacity(0.12)); // Menu 1 button is highlighted.
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('Highlight can move up/down starting from the searching result on desktop platforms', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: DropdownMenu<TestMenu>(
          dropdownMenuEntries: menuChildren,
        ),
      ),
    ));

    // Open the menu
    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Menu 1');
    await tester.pumpAndSettle();
    final Finder buttonMaterial = find.descendant(
      of: find.widgetWithText(MenuItemButton, 'Menu 1').last,
      matching: find.byType(Material),
    );
    final Material itemMaterial = tester.widget<Material>(buttonMaterial);
    expect(itemMaterial.color, themeData.colorScheme.onSurface.withOpacity(0.12));

    // Press up to the upper item (Item 0).
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Item 0'), findsOneWidget);
    final Finder button0Material = find.descendant(
      of: find.widgetWithText(MenuItemButton, 'Item 0').last,
      matching: find.byType(Material),
    );
    final Material item0Material = tester.widget<Material>(button0Material);
    expect(item0Material.color, themeData.colorScheme.onSurface.withOpacity(0.12)); // Move up, the 'Item 0' is highlighted.

    // Continue to move up to the last item (Item 5).
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Item 5'), findsOneWidget);
    final Finder button5Material = find.descendant(
      of: find.widgetWithText(MenuItemButton, 'Item 5').last,
      matching: find.byType(Material),
    );
    final Material item5Material = tester.widget<Material>(button5Material);
    expect(item5Material.color, themeData.colorScheme.onSurface.withOpacity(0.12));
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('Filtering is disabled by default', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: DropdownMenu<TestMenu>(
          requestFocusOnTap: true,
          dropdownMenuEntries: menuChildren,
        ),
      ),
    ));

    // Open the menu
    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Menu 1');
    await tester.pumpAndSettle();
    for (final TestMenu menu in TestMenu.values) {
      // One is layout for the _DropdownMenuBody, the other one is the real button item in the menu.
      expect(find.widgetWithText(MenuItemButton, menu.label), findsNWidgets(2));
    }
  });

  testWidgets('Enable filtering', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: DropdownMenu<TestMenu>(
          requestFocusOnTap: true,
          enableFilter: true,
          dropdownMenuEntries: menuChildren,
        ),
      ),
    ));

    // Open the menu
    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pump();

    await tester.enterText(find
        .byType(TextField)
        .first, 'Menu 1');
    await tester.pumpAndSettle();
    for (final TestMenu menu in TestMenu.values) {
      // 'Menu 1' should be 2, other items should only find one.
      if (menu.label == TestMenu.mainMenu1.label) {
        expect(find.widgetWithText(MenuItemButton, menu.label), findsNWidgets(2));
      } else {
        expect(find.widgetWithText(MenuItemButton, menu.label), findsOneWidget);
      }
    }
  });

  testWidgets('The controller can access the value in the input field', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    final TextEditingController controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Scaffold(
            body: DropdownMenu<TestMenu>(
              requestFocusOnTap: true,
              enableFilter: true,
              dropdownMenuEntries: menuChildren,
              controller: controller,
            ),
          );
        }
      ),
    ));

    // Open the menu
    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pump();
    final Finder item3 = find.widgetWithText(MenuItemButton, 'Item 3').last;
    await tester.tap(item3);
    await tester.pumpAndSettle();

    expect(controller.text, 'Item 3');

    await tester.enterText(find.byType(TextField).first, 'New Item');
    expect(controller.text, 'New Item');
  });

  testWidgets('The menu should be closed after text editing is complete', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    final TextEditingController controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: DropdownMenu<TestMenu>(
          requestFocusOnTap: true,
          enableFilter: true,
          dropdownMenuEntries: menuChildren,
          controller: controller,
        ),
      ),
    ));
    // Access the MenuAnchor
    final MenuAnchor menuAnchor = tester.widget<MenuAnchor>(find.byType(MenuAnchor));

    // Open the menu
    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pumpAndSettle();
    expect(menuAnchor.controller!.isOpen, true);

    // Simulate `TextInputAction.done` on textfield
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(menuAnchor.controller!.isOpen, false);
  });

  testWidgets('The onSelected gets called only when a selection is made', (WidgetTester tester) async {
    int selectionCount = 0;

    final ThemeData themeData = ThemeData();
    final List<DropdownMenuEntry<TestMenu>> menuWithDisabledItems = <DropdownMenuEntry<TestMenu>>[
      const DropdownMenuEntry<TestMenu>(value: TestMenu.mainMenu0, label: 'Item 0'),
      const DropdownMenuEntry<TestMenu>(value: TestMenu.mainMenu0, label: 'Item 1', enabled: false),
      const DropdownMenuEntry<TestMenu>(value: TestMenu.mainMenu0, label: 'Item 2'),
      const DropdownMenuEntry<TestMenu>(value: TestMenu.mainMenu0, label: 'Item 3'),
    ];
    final TextEditingController controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: DropdownMenu<TestMenu>(
                dropdownMenuEntries: menuWithDisabledItems,
                controller: controller,
                onSelected: (_) {
                  setState(() {
                    selectionCount++;
                  });
                },
              ),
            );
          }
      ),
    ));

    // Open the menu
    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pump();

    late final bool isMobile;
    switch (themeData.platform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        isMobile = true;
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        isMobile = false;
    }
    int expectedCount = isMobile ? 0 : 1;

    // Test onSelected on key press
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(selectionCount, expectedCount);
    // The desktop platform closed the menu when a completion action is pressed. So we need to reopen it.
    if (!isMobile) {
      await tester.tap(find.byType(DropdownMenu<TestMenu>));
      await tester.pump();
    }

    // Disabled item doesn't trigger onSelected callback.
    final Finder item1 = find.widgetWithText(MenuItemButton, 'Item 1').last;
    await tester.tap(item1);
    await tester.pumpAndSettle();

    expect(controller.text, isMobile ? '' : 'Item 0');
    expect(selectionCount, expectedCount);

    final Finder item2 = find.widgetWithText(MenuItemButton, 'Item 2').last;
    await tester.tap(item2);
    await tester.pumpAndSettle();

    expect(controller.text, 'Item 2');
    expect(selectionCount, ++expectedCount);

    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pump();
    final Finder item3 = find.widgetWithText(MenuItemButton, 'Item 3').last;
    await tester.tap(item3);
    await tester.pumpAndSettle();

    expect(controller.text, 'Item 3');
    expect(selectionCount, ++expectedCount);

    // On desktop platforms, when typing something in the text field without selecting any of the options,
    // the onSelected should not be called.
    if (!isMobile) {
      await tester.enterText(find.byType(TextField).first, 'New Item');
      expect(controller.text, 'New Item');
      expect(selectionCount, expectedCount);
      expect(find.widgetWithText(TextField, 'New Item'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '');
      expect(selectionCount, expectedCount);
      expect(controller.text.isEmpty, true);
    }
  }, variant: TargetPlatformVariant.all());


  testWidgets('The selectedValue gives an initial text and highlights the according item', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    final TextEditingController controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: DropdownMenu<TestMenu>(
                initialSelection: TestMenu.mainMenu3,
                dropdownMenuEntries: menuChildren,
                controller: controller,
              ),
            );
          }
      ),
    ));

    expect(find.widgetWithText(TextField, 'Item 3'), findsOneWidget);

    // Open the menu
    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pump();

    final Finder buttonMaterial = find.descendant(
      of: find.widgetWithText(MenuItemButton, 'Item 3'),
      matching: find.byType(Material),
    ).last;

    // Validate the item 3 is highlighted.
    final Material itemMaterial = tester.widget<Material>(buttonMaterial);
    expect(itemMaterial.color, themeData.colorScheme.onSurface.withOpacity(0.12));
  });

  testWidgets('The default text input field should not be focused on mobile platforms '
      'when it is tapped', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();

    Widget buildDropdownMenu() => MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: Column(
          children: <Widget>[
            DropdownMenu<TestMenu>(
              dropdownMenuEntries: menuChildren,
            ),
          ],
        ),
      ),
    );

    // Test default condition.
    await tester.pumpWidget(buildDropdownMenu());
    await tester.pump();

    final Finder textFieldFinder = find.byType(TextField);
    final TextField result = tester.widget<TextField>(textFieldFinder);
    expect(result.canRequestFocus, false);
  }, variant: TargetPlatformVariant.mobile());

  testWidgets('The text input field should be focused on desktop platforms '
      'when it is tapped', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();

    Widget buildDropdownMenu() => MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: Column(
          children: <Widget>[
            DropdownMenu<TestMenu>(
              dropdownMenuEntries: menuChildren,
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(buildDropdownMenu());
    await tester.pump();

    final Finder textFieldFinder = find.byType(TextField);
    final TextField result = tester.widget<TextField>(textFieldFinder);
    expect(result.canRequestFocus, true);
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('If requestFocusOnTap is true, the text input field can request focus, '
    'otherwise it cannot request focus', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();

    Widget buildDropdownMenu({required bool requestFocusOnTap}) => MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: Column(
          children: <Widget>[
            DropdownMenu<TestMenu>(
              requestFocusOnTap: requestFocusOnTap,
              dropdownMenuEntries: menuChildren,
            ),
          ],
        ),
      ),
    );

    // Set requestFocusOnTap to true.
    await tester.pumpWidget(buildDropdownMenu(requestFocusOnTap: true));
    await tester.pump();

    final Finder textFieldFinder = find.byType(TextField);
    final TextField textField = tester.widget<TextField>(textFieldFinder);
    expect(textField.canRequestFocus, true);
    // Open the dropdown menu.
    await tester.tap(textFieldFinder);
    await tester.pump();
    // Make a selection.
    await tester.tap(find.widgetWithText(MenuItemButton, 'Item 0').last);
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Item 0'), findsOneWidget);

    // Set requestFocusOnTap to false.
    await tester.pumpWidget(Container());
    await tester.pumpWidget(buildDropdownMenu(requestFocusOnTap: false));
    await tester.pumpAndSettle();

    final Finder textFieldFinder1 = find.byType(TextField);
    final TextField textField1 = tester.widget<TextField>(textFieldFinder1);
    expect(textField1.canRequestFocus, false);
    // Open the dropdown menu.
    await tester.tap(textFieldFinder1);
    await tester.pump();
    // Make a selection.
    await tester.tap(find.widgetWithText(MenuItemButton, 'Item 0').last);
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Item 0'), findsOneWidget);
  }, variant: TargetPlatformVariant.all());

  testWidgets('If requestFocusOnTap is false, the mouse cursor should be clickable when hovered', (WidgetTester tester) async {
    Widget buildDropdownMenu() => MaterialApp(
      home: Scaffold(
        body: Column(
          children: <Widget>[
            DropdownMenu<TestMenu>(
              requestFocusOnTap: false,
              dropdownMenuEntries: menuChildren,
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(buildDropdownMenu());
    await tester.pumpAndSettle();

    final Finder textFieldFinder = find.byType(TextField);
    final TextField textField = tester.widget<TextField>(textFieldFinder);
    expect(textField.canRequestFocus, false);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.moveTo(tester.getCenter(textFieldFinder));
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.click);
  });

  testWidgets('The menu has the same width as the input field in ListView', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/123631
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: <Widget>[
            DropdownMenu<TestMenu>(
              dropdownMenuEntries: menuChildren,
            ),
          ],
        ),
      ),
    ));

    final Rect textInput = tester.getRect(find.byType(TextField));

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final Finder findMenu = find.byWidgetPredicate((Widget widget) {
      return widget.runtimeType.toString() == '_MenuPanel';
    });
    final Rect menu = tester.getRect(findMenu);
    expect(textInput.width, menu.width);

    await tester.pumpWidget(Container());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: <Widget>[
            DropdownMenu<TestMenu>(
              width: 200,
              dropdownMenuEntries: menuChildren,
            ),
          ],
        ),
      ),
    ));

    final Rect textInput1 = tester.getRect(find.byType(TextField));

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final Finder findMenu1 = find.byWidgetPredicate((Widget widget) {
      return widget.runtimeType.toString() == '_MenuPanel';
    });
    final Rect menu1 = tester.getRect(findMenu1);
    expect(textInput1.width, 200);
    expect(menu1.width, 200);
  });

  testWidgets('Semantics does not include hint when input is not empty', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    const String hintText = 'I am hintText';
    TestMenu? selectedValue;
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => MaterialApp(
          theme: themeData,
          home: Scaffold(
            body: Center(
              child: DropdownMenu<TestMenu>(
                requestFocusOnTap: true,
                dropdownMenuEntries: menuChildren,
                hintText: hintText,
                onSelected: (TestMenu? value) {
                  setState(() {
                    selectedValue = value;
                  });
                },
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );
    final SemanticsNode node = tester.getSemantics(find.text(hintText));

    expect(selectedValue?.label, null);
    expect(node.label, hintText);
    expect(node.value, '');

    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'Item 3').last);
    await tester.pumpAndSettle();
    expect(selectedValue?.label, 'Item 3');
    expect(node.label, '');
    expect(node.value, 'Item 3');
  });

  testWidgets('helperText is not visible when errorText is not null', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    const String helperText = 'I am helperText';
    const String errorText = 'I am errorText';

    Widget buildFrame(bool hasError) {
      return MaterialApp(
        theme: themeData,
        home: Scaffold(
          body: Center(
            child: DropdownMenu<TestMenu>(
              dropdownMenuEntries: menuChildren,
              helperText: helperText,
              errorText: hasError ? errorText : null,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(false));
    expect(find.text(helperText), findsOneWidget);
    expect(find.text(errorText), findsNothing);

    await tester.pumpWidget(buildFrame(true));
    await tester.pumpAndSettle();
    expect(find.text(helperText), findsNothing);
    expect(find.text(errorText), findsOneWidget);
  });

  testWidgets('DropdownMenu can respect helperText when helperText is not null', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    const String helperText = 'I am helperText';

    Widget buildFrame() {
      return MaterialApp(
        theme: themeData,
        home: Scaffold(
          body: Center(
            child: DropdownMenu<TestMenu>(
              dropdownMenuEntries: menuChildren,
              helperText: helperText,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame());
    expect(find.text(helperText), findsOneWidget);
  });

  testWidgets('DropdownMenu can respect errorText when errorText is not null', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    const String errorText = 'I am errorText';

    Widget buildFrame() {
      return MaterialApp(
        theme: themeData,
        home: Scaffold(
          body: Center(
            child: DropdownMenu<TestMenu>(
              dropdownMenuEntries: menuChildren,
              errorText: errorText,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame());
    expect(find.text(errorText), findsOneWidget);
  });

  testWidgets('Can scroll to the highlighted item', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DropdownMenu<TestMenu>(
          requestFocusOnTap: true,
          menuHeight: 100, // Give a small number so the list can only show 2 or 3 items.
          dropdownMenuEntries: menuChildren,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    await tester.pumpAndSettle();

    expect(find.text('Item 5').hitTestable(), findsNothing);
    await tester.enterText(find.byType(TextField), '5');
    await tester.pumpAndSettle();
    // Item 5 should show up.
    expect(find.text('Item 5').hitTestable(), findsOneWidget);
  });

  // This is a regression test for https://github.com/flutter/flutter/issues/131676.
  testWidgets('Material3 - DropdownMenu uses correct text styles', (WidgetTester tester) async {
    const TextStyle inputTextThemeStyle = TextStyle(
      fontSize: 18.5,
      fontStyle: FontStyle.italic,
      wordSpacing: 1.2,
      decoration: TextDecoration.lineThrough,
    );
    const TextStyle menuItemTextThemeStyle = TextStyle(
      fontSize: 20.5,
      fontStyle: FontStyle.italic,
      wordSpacing: 2.1,
      decoration: TextDecoration.underline,
    );
    final ThemeData themeData = ThemeData(
      useMaterial3: true,
      textTheme: const TextTheme(
        bodyLarge: inputTextThemeStyle,
        labelLarge: menuItemTextThemeStyle,
      ),
    );
    await tester.pumpWidget(buildTest(themeData, menuChildren));

    // Test input text style uses the TextTheme.bodyLarge.
    final EditableText editableText = tester.widget(find.byType(EditableText));
    expect(editableText.style.fontSize, inputTextThemeStyle.fontSize);
    expect(editableText.style.fontStyle, inputTextThemeStyle.fontStyle);
    expect(editableText.style.wordSpacing, inputTextThemeStyle.wordSpacing);
    expect(editableText.style.decoration, inputTextThemeStyle.decoration);

    // Open the menu.
    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_drop_down).first);
    await tester.pump();

    final Finder buttonMaterial = find.descendant(
      of: find.byType(TextButton),
      matching: find.byType(Material),
    ).last;

    // Test menu item text style uses the TextTheme.labelLarge.
    final Material material = tester.widget<Material>(buttonMaterial);
    expect(material.textStyle?.fontSize, menuItemTextThemeStyle.fontSize);
    expect(material.textStyle?.fontStyle, menuItemTextThemeStyle.fontStyle);
    expect(material.textStyle?.wordSpacing, menuItemTextThemeStyle.wordSpacing);
    expect(material.textStyle?.decoration, menuItemTextThemeStyle.decoration);
  });

  testWidgets('DropdownMenuEntries do not overflow when width is specified', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/126882
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenu<TestMenu>(
            controller: controller,
            width: 100,
            dropdownMenuEntries: TestMenu.values.map<DropdownMenuEntry<TestMenu>>((TestMenu item) {
              return DropdownMenuEntry<TestMenu>(
                value: item,
                label: '${item.label} $longText',
              );
            }).toList(),
          ),
        ),
      ),
    );

    // Opening the width=100 menu should not crash.
    await tester.tap(find.byType(DropdownMenu<TestMenu>));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();

    Finder findMenuItemText(String label) {
      final String labelText = '$label $longText';
      return find.descendant(
        of: find.widgetWithText(MenuItemButton, labelText),
        matching: find.byType(Text),
      ).last;
    }

    // Actual size varies a little on web platforms.
    final Matcher closeTo300 = closeTo(300, 0.25);
    expect(tester.getSize(findMenuItemText('Item 0')).height, closeTo300);
    expect(tester.getSize(findMenuItemText('Menu 1')).height, closeTo300);
    expect(tester.getSize(findMenuItemText('Item 2')).height, closeTo300);
    expect(tester.getSize(findMenuItemText('Item 3')).height, closeTo300);

    await tester.tap(findMenuItemText('Item 0'));
    await tester.pumpAndSettle();
    expect(controller.text, 'Item 0 $longText');
  });

  testWidgets('DropdownMenuEntry.labelWidget is Text that specifies maxLines 1 or 2', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/126882
    final TextEditingController controller = TextEditingController();

    Widget buildFrame({ required int maxLines }) {
      return MaterialApp(
        home: Scaffold(
          body: DropdownMenu<TestMenu>(
            key: ValueKey<int>(maxLines),
            controller: controller,
            width: 100,
            dropdownMenuEntries: TestMenu.values.map<DropdownMenuEntry<TestMenu>>((TestMenu item) {
              return DropdownMenuEntry<TestMenu>(
                value: item,
                label: '${item.label} $longText',
                labelWidget: Text('${item.label} $longText', maxLines: maxLines),
              );
            }).toList(),
          ),
        )
      );
    }

    Finder findMenuItemText(String label) {
      final String labelText = '$label $longText';
      return find.descendant(
        of: find.widgetWithText(MenuItemButton, labelText),
        matching: find.byType(Text),
      ).last;
    }

    await tester.pumpWidget(buildFrame(maxLines: 1));
    await tester.tap(find.byType(DropdownMenu<TestMenu>));

    // Actual size varies a little on web platforms.
    final Matcher closeTo20 = closeTo(20, 0.05);
    expect(tester.getSize(findMenuItemText('Item 0')).height, closeTo20);
    expect(tester.getSize(findMenuItemText('Menu 1')).height, closeTo20);
    expect(tester.getSize(findMenuItemText('Item 2')).height, closeTo20);
    expect(tester.getSize(findMenuItemText('Item 3')).height, closeTo20);

    // Close the menu
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(controller.text, ''); // nothing selected

    await tester.pumpWidget(buildFrame(maxLines: 2));
    await tester.tap(find.byType(DropdownMenu<TestMenu>));

    // Actual size varies a little on web platforms.
    final Matcher closeTo40 = closeTo(40, 0.05);
    expect(tester.getSize(findMenuItemText('Item 0')).height, closeTo40);
    expect(tester.getSize(findMenuItemText('Menu 1')).height, closeTo40);
    expect(tester.getSize(findMenuItemText('Item 2')).height, closeTo40);
    expect(tester.getSize(findMenuItemText('Item 3')).height, closeTo40);

    // Close the menu
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(controller.text, ''); // nothing selected
  });

  // Regression test for https://github.com/flutter/flutter/issues/131350.
  testWidgets('DropdownMenuEntry.leadingIcon default layout', (WidgetTester tester) async {
    // The DropdownMenu should not get extra padding in DropdownMenuEntry items
    // when both text field and DropdownMenuEntry have leading icons.
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: DropdownMenu<int>(
            leadingIcon: Icon(Icons.search),
            hintText: 'Hint',
            dropdownMenuEntries: <DropdownMenuEntry<int>>[
              DropdownMenuEntry<int>(
                value: 0,
                label: 'Item 0',
                leadingIcon: Icon(Icons.alarm)
              ),
              DropdownMenuEntry<int>(value: 1, label: 'Item 1'),
            ],
          ),
        )
    ));
    await tester.tap(find.byType(DropdownMenu<int>));
    await tester.pumpAndSettle();

    // Check text location in text field.
    expect(tester.getTopLeft(find.text('Hint')).dx, 48.0);

    // By default, the text of item 0 should be aligned with the text of the text field.
    expect(tester.getTopLeft(find.text('Item 0').last).dx, 48.0);

    // By default, the text of item 1 should be aligned with the text of the text field,
    // so there are some extra padding before "Item 1".
    expect(tester.getTopLeft(find.text('Item 1').last).dx, 48.0);
  });
}

enum TestMenu {
  mainMenu0('Item 0'),
  mainMenu1('Menu 1'),
  mainMenu2('Item 2'),
  mainMenu3('Item 3'),
  mainMenu4('Item 4'),
  mainMenu5('Item 5');

  const TestMenu(this.label);
  final String label;
}

enum ShortMenu {
  item0('I0'),
  item1('I1'),
  item2('I2');

  const ShortMenu(this.label);
  final String label;
}
