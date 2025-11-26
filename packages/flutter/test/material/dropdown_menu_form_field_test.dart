// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/src/services/text_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

enum MenuItem {
  menuItem0('Item 0'),
  menuItem1('Item 1'),
  menuItem2('Item 2'),
  menuItem3('Item 3');

  const MenuItem(this.label);
  final String label;
}

void main() {
  final menuEntries = <DropdownMenuEntry<MenuItem>>[];

  for (final MenuItem value in MenuItem.values) {
    final entry = DropdownMenuEntry<MenuItem>(value: value, label: value.label);
    menuEntries.add(entry);
  }

  Finder findMenuItem(MenuItem menuItem) {
    // For each menu item there are two MenuItemButton widgets.
    // The last one is the real button item in the menu.
    // The first one is not visible, it is part of _DropdownMenuBody
    // which is used to compute the dropdown width.
    return find.widgetWithText(MenuItemButton, menuItem.label).last;
  }

  testWidgets('Creates an underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    expect(find.byType(DropdownMenu<MenuItem>), findsOne);
  });

  testWidgets('Passes dropdownMenuEntries to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    final DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.dropdownMenuEntries, menuEntries);
  });

  testWidgets('Dropdown menu can be opened and contains all the items', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    await tester.tap(find.byType(DropdownMenu<MenuItem>));
    await tester.pump();

    for (final MenuItem item in MenuItem.values) {
      expect(findMenuItem(item), findsOne);
    }
  });

  testWidgets('Passes enabled to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.enabled, true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(enabled: false, dropdownMenuEntries: menuEntries),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.enabled, false);
  });

  testWidgets('Passes width to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.width, null);

    const width = 100.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(width: width, dropdownMenuEntries: menuEntries),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.width, width);
  });

  testWidgets('Passes menuHeight to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.menuHeight, null);

    const menuHeight = 100.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            menuHeight: menuHeight,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.menuHeight, menuHeight);
  });

  testWidgets('Passes leadingIcon to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.leadingIcon, null);

    const leadingIcon = Icon(Icons.abc);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            leadingIcon: leadingIcon,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.leadingIcon, leadingIcon);
  });

  testWidgets('Passes trailingIcon to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.trailingIcon, null);

    const trailingIcon = Icon(Icons.abc);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            trailingIcon: trailingIcon,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.trailingIcon, trailingIcon);
  });

  testWidgets('Passes label to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.label, null);

    const Widget label = Text('Label');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(label: label, dropdownMenuEntries: menuEntries),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.label, label);
  });

  testWidgets('Passes hintText to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.hintText, null);

    const hintText = 'Hint';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            hintText: hintText,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.hintText, hintText);
  });

  testWidgets('Passes helperText to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.helperText, null);

    const helperText = 'Hint';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            helperText: helperText,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.helperText, helperText);
  });

  testWidgets('Passes selectedTrailingIcon to underlying DropdownMenu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.selectedTrailingIcon, null);

    const selectedTrailingIcon = Icon(Icons.abc);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            selectedTrailingIcon: selectedTrailingIcon,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.selectedTrailingIcon, selectedTrailingIcon);
  });

  testWidgets('Passes enableFilter to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.enableFilter, false);

    const enableFilter = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            enableFilter: enableFilter,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.enableFilter, enableFilter);
  });

  testWidgets('Passes enableSearch to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.enableSearch, true);

    const enableSearch = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            enableSearch: enableSearch,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.enableSearch, enableSearch);
  });

  testWidgets('Passes keyboardType to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.keyboardType, null);

    const TextInputType keyboardType = TextInputType.datetime;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            keyboardType: keyboardType,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.keyboardType, keyboardType);
  });

  testWidgets('Passes textStyle to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.textStyle, null);

    const textStyle = TextStyle(fontWeight: FontWeight.bold);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            textStyle: textStyle,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.textStyle, textStyle);
  });

  testWidgets('Passes textAlign to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.textAlign, TextAlign.start);

    const TextAlign textAlign = TextAlign.center;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            textAlign: textAlign,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.textAlign, textAlign);
  });

  testWidgets('Passes inputDecorationTheme to underlying DropdownMenu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.inputDecorationTheme, null);

    const inputDecorationTheme = InputDecorationThemeData();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            inputDecorationTheme: inputDecorationTheme,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.inputDecorationTheme, inputDecorationTheme);
  });

  testWidgets('Passes decorationBuilder to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.decorationBuilder, null);

    InputDecoration buildDecoration(BuildContext context, MenuController controller) {
      return const InputDecoration(labelText: 'labelText');
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            decorationBuilder: buildDecoration,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.decorationBuilder, buildDecoration);
  });

  testWidgets('Passes menuStyle to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.menuStyle, null);

    const menuStyle = MenuStyle();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            menuStyle: menuStyle,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.menuStyle, menuStyle);
  });

  testWidgets('Passes controller to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    final controller = TextEditingController();
    addTearDown(controller.dispose);

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.controller, isNotNull); // A default controller is created.
    expect(dropdownMenu.controller, isNot(controller));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            controller: controller,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.controller, controller);
  });

  testWidgets('Passes focusNode to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.focusNode, null);

    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            focusNode: focusNode,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.focusNode, focusNode);
  });

  testWidgets('Passes requestFocusOnTap to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.requestFocusOnTap, null);

    const requestFocusOnTap = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            requestFocusOnTap: requestFocusOnTap,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.requestFocusOnTap, requestFocusOnTap);
  });

  testWidgets('Passes expandedInsets to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.expandedInsets, null);

    const EdgeInsetsGeometry expandedInsets = EdgeInsets.zero;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            expandedInsets: expandedInsets,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.expandedInsets, expandedInsets);
  });

  testWidgets('Passes alignmentOffset to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.alignmentOffset, null);

    const Offset alignmentOffset = Offset.zero;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            alignmentOffset: alignmentOffset,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.alignmentOffset, alignmentOffset);
  });

  testWidgets('Passes filterCallback to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            enableFilter: true,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.filterCallback, null);

    List<DropdownMenuEntry<MenuItem>> filterCallback(
      List<DropdownMenuEntry<MenuItem>> entries,
      String filter,
    ) {
      return entries;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            enableFilter: true,
            filterCallback: filterCallback,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.filterCallback, filterCallback);
  });

  testWidgets('Passes searchCallback to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.searchCallback, null);

    int searchCallback(List<DropdownMenuEntry<MenuItem>> entries, String filter) {
      return 0;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            searchCallback: searchCallback,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.searchCallback, searchCallback);
  });

  testWidgets('Passes inputFormatters to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.inputFormatters, null);

    final inputFormatters = <TextInputFormatter>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            inputFormatters: inputFormatters,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.inputFormatters, inputFormatters);
  });

  testWidgets('Passes closeBehavior to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.closeBehavior, DropdownMenuCloseBehavior.all);

    const DropdownMenuCloseBehavior closeBehavior = DropdownMenuCloseBehavior.self;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            closeBehavior: closeBehavior,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.closeBehavior, closeBehavior);
  });

  testWidgets('Passes maxLines to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.maxLines, 1);

    const maxLines = 3;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            maxLines: maxLines,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.maxLines, maxLines);
  });

  testWidgets('Passes textInputAction to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.textInputAction, null);

    const TextInputAction textInputAction = TextInputAction.emergencyCall;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            textInputAction: textInputAction,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.textInputAction, textInputAction);
  });

  testWidgets('Passes restorationId to underlying DropdownMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries)),
      ),
    );

    // Check default value.
    DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.restorationId, null);

    const restorationId = 'dropdown_menu';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            restorationId: restorationId,
            dropdownMenuEntries: menuEntries,
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsOne);

    dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.restorationId, restorationId);
  });

  testWidgets('Field state is correcly updated', (WidgetTester tester) async {
    final fieldKey = GlobalKey<FormFieldState<MenuItem>>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            key: fieldKey,
            dropdownMenuEntries: menuEntries,
            initialSelection: MenuItem.menuItem0,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownMenu<MenuItem>));
    await tester.pump();

    await tester.tap(findMenuItem(MenuItem.menuItem1));
    await tester.pump();

    expect(fieldKey.currentState!.value, MenuItem.menuItem1);
  });

  testWidgets('onSaved callback is called when the field is outside a Form', (
    WidgetTester tester,
  ) async {
    final fieldKey = GlobalKey<FormFieldState<MenuItem>>();

    MenuItem? savedValue = MenuItem.menuItem0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            key: fieldKey,
            dropdownMenuEntries: menuEntries,
            initialSelection: savedValue,
            onSaved: (MenuItem? newValue) => savedValue = newValue,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownMenu<MenuItem>));
    await tester.pump();

    await tester.tap(findMenuItem(MenuItem.menuItem1));
    await tester.pump();

    expect(savedValue, MenuItem.menuItem0);

    fieldKey.currentState!.save();
    await tester.pump();

    expect(savedValue, MenuItem.menuItem1);
  });

  testWidgets('onSaved callback is called when the field is inside a Form', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();

    MenuItem? savedValue = MenuItem.menuItem0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: DropdownMenuFormField<MenuItem>(
              dropdownMenuEntries: menuEntries,
              initialSelection: savedValue,
              onSaved: (MenuItem? newValue) => savedValue = newValue,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownMenu<MenuItem>));
    await tester.pump();

    await tester.tap(findMenuItem(MenuItem.menuItem1));
    await tester.pump();

    expect(savedValue, MenuItem.menuItem0);

    formKey.currentState!.save();
    await tester.pump();

    expect(savedValue, MenuItem.menuItem1);
  });

  testWidgets('Field can be reset', (WidgetTester tester) async {
    final fieldKey = GlobalKey<FormFieldState<MenuItem>>();

    MenuItem? savedValue = MenuItem.menuItem0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            key: fieldKey,
            dropdownMenuEntries: menuEntries,
            initialSelection: savedValue,
            onSaved: (MenuItem? newValue) => savedValue = newValue,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownMenu<MenuItem>));
    await tester.pump();

    await tester.tap(findMenuItem(MenuItem.menuItem1));
    await tester.pump();

    expect(fieldKey.currentState!.value, MenuItem.menuItem1);

    fieldKey.currentState!.reset();
    await tester.pump();

    expect(fieldKey.currentState!.value, MenuItem.menuItem0);
  });

  // Regression test for https://github.com/flutter/flutter/issues/174578.
  testWidgets(
    'Inner text field is cleared on reset when initialSelection is null - Default controller',
    (WidgetTester tester) async {
      final fieldKey = GlobalKey<FormFieldState<MenuItem>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownMenuFormField<MenuItem>(key: fieldKey, dropdownMenuEntries: menuEntries),
          ),
        ),
      );

      final TextField textField = tester.widget(find.byType(TextField));

      // Select menuItem1.
      await tester.tap(find.byType(DropdownMenu<MenuItem>));
      await tester.pump();
      await tester.tap(findMenuItem(MenuItem.menuItem1));
      await tester.pump();
      expect(fieldKey.currentState!.value, MenuItem.menuItem1);
      expect(
        textField.controller?.value,
        const TextEditingValue(text: 'Item 1', selection: TextSelection.collapsed(offset: 6)),
      );

      // After reset the text field content is cleared.
      fieldKey.currentState!.reset();
      await tester.pump();

      expect(fieldKey.currentState!.value, null);
      expect(
        textField.controller?.value,
        const TextEditingValue(selection: TextSelection.collapsed(offset: 0)),
      );
    },
  );

  // Regression test for https://github.com/flutter/flutter/issues/174578.
  testWidgets(
    'Inner text field is cleared on reset when initialSelection is null - Custom controller',
    (WidgetTester tester) async {
      final fieldKey = GlobalKey<FormFieldState<MenuItem>>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownMenuFormField<MenuItem>(
              key: fieldKey,
              controller: controller,
              dropdownMenuEntries: menuEntries,
            ),
          ),
        ),
      );

      // Custom controller is correctly passed to the inner TextField.
      final TextField textField = tester.widget(find.byType(TextField));
      expect(textField.controller, controller);

      // Select menuItem1.
      await tester.tap(find.byType(DropdownMenu<MenuItem>));
      await tester.pump();
      await tester.tap(findMenuItem(MenuItem.menuItem1));
      await tester.pump();
      expect(fieldKey.currentState!.value, MenuItem.menuItem1);
      expect(
        textField.controller?.value,
        const TextEditingValue(text: 'Item 1', selection: TextSelection.collapsed(offset: 6)),
      );

      // After reset the text field content is cleared.
      fieldKey.currentState!.reset();
      await tester.pump();

      expect(fieldKey.currentState!.value, null);
      expect(
        controller.value,
        const TextEditingValue(selection: TextSelection.collapsed(offset: 0)),
      );
    },
  );

  testWidgets('isValid and hasError results are correct', (WidgetTester tester) async {
    final fieldKey = GlobalKey<FormFieldState<MenuItem>>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            key: fieldKey,
            dropdownMenuEntries: menuEntries,
            autovalidateMode: AutovalidateMode.always,
          ),
        ),
      ),
    );

    // No validation error.
    expect(fieldKey.currentState!.isValid, true);
    expect(fieldKey.currentState!.hasError, false);

    const validationError = 'Required';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            key: fieldKey,
            dropdownMenuEntries: menuEntries,
            autovalidateMode: AutovalidateMode.always,
            validator: (MenuItem? item) => validationError,
          ),
        ),
      ),
    );

    // Validation error.
    expect(fieldKey.currentState!.isValid, false);
    expect(fieldKey.currentState!.hasError, true);
  });

  testWidgets('Validation result is shown as error text', (WidgetTester tester) async {
    final fieldKey = GlobalKey<FormFieldState<MenuItem>>();

    const validationError = 'Required';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            key: fieldKey,
            dropdownMenuEntries: menuEntries,
            autovalidateMode: AutovalidateMode.always,
            validator: (MenuItem? item) => validationError,
          ),
        ),
      ),
    );

    fieldKey.currentState!.validate();
    await tester.pump();

    expect(find.text('Required'), findsOneWidget);

    final DropdownMenu<MenuItem> dropdownMenu = tester.widget(find.byType(DropdownMenu<MenuItem>));
    expect(dropdownMenu.errorText, validationError);
  });

  testWidgets('Initial selection is applied', (WidgetTester tester) async {
    final fieldKey = GlobalKey<FormFieldState<MenuItem>>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            key: fieldKey,
            dropdownMenuEntries: menuEntries,
            initialSelection: MenuItem.menuItem0,
          ),
        ),
      ),
    );

    expect(fieldKey.currentState!.value, MenuItem.menuItem0);
  });

  testWidgets(
    'Initial selection is applied when updated and the field has not been updated in-between',
    (WidgetTester tester) async {
      final fieldKey = GlobalKey<FormFieldState<MenuItem>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownMenuFormField<MenuItem>(
              key: fieldKey,
              dropdownMenuEntries: menuEntries,
              initialSelection: MenuItem.menuItem0,
            ),
          ),
        ),
      );

      expect(fieldKey.currentState!.value, MenuItem.menuItem0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownMenuFormField<MenuItem>(
              key: fieldKey,
              dropdownMenuEntries: menuEntries,
              initialSelection: MenuItem.menuItem1,
            ),
          ),
        ),
      );

      expect(fieldKey.currentState!.value, MenuItem.menuItem1);
    },
  );

  testWidgets(
    'Initial selection is not applied when updated and the field has been updated in-between',
    (WidgetTester tester) async {
      final fieldKey = GlobalKey<FormFieldState<MenuItem>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownMenuFormField<MenuItem>(
              key: fieldKey,
              dropdownMenuEntries: menuEntries,
              initialSelection: MenuItem.menuItem0,
            ),
          ),
        ),
      );

      expect(fieldKey.currentState!.value, MenuItem.menuItem0);

      // Select a different item than the initial one.
      await tester.tap(find.byType(DropdownMenu<MenuItem>));
      await tester.pump();

      await tester.tap(findMenuItem(MenuItem.menuItem2));
      await tester.pump();

      expect(fieldKey.currentState!.value, MenuItem.menuItem2);

      // Update initial selection.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownMenuFormField<MenuItem>(
              key: fieldKey,
              dropdownMenuEntries: menuEntries,
              initialSelection: MenuItem.menuItem1,
            ),
          ),
        ),
      );

      // The value selected by the user is preserved.
      expect(fieldKey.currentState!.value, MenuItem.menuItem2);
    },
  );

  testWidgets('Selected value is restorable', (WidgetTester tester) async {
    final formFieldState = GlobalKey<FormFieldState<MenuItem>>();
    const restorationId = 'dropdown_menu_form_field';

    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: 'app',
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            key: formFieldState,
            dropdownMenuEntries: menuEntries,
            initialSelection: MenuItem.menuItem0,
            restorationId: restorationId,
          ),
        ),
      ),
    );

    expect(formFieldState.currentState!.value, MenuItem.menuItem0);

    // Select a different item than the initial one.
    await tester.tap(find.byType(DropdownMenu<MenuItem>));
    await tester.pump();

    await tester.tap(findMenuItem(MenuItem.menuItem2));
    await tester.pump();

    expect(formFieldState.currentState!.value, MenuItem.menuItem2);

    // Needed for restoration data to be updated.
    await tester.pump();

    final TestRestorationData data = await tester.getRestorationData();
    await tester.restartAndRestore();

    expect(formFieldState.currentState!.value, MenuItem.menuItem2);

    formFieldState.currentState!.reset();
    expect(formFieldState.currentState!.value, MenuItem.menuItem0);

    await tester.restoreFrom(data);
    await tester.pump();

    expect(formFieldState.currentState!.value, MenuItem.menuItem2);
  });

  testWidgets('onSelect is called exactly once when a selection is made.', (
    WidgetTester tester,
  ) async {
    var onSelectedCallCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            dropdownMenuEntries: menuEntries,
            initialSelection: MenuItem.menuItem0,
            onSelected: (MenuItem? value) {
              onSelectedCallCount++;
            },
          ),
        ),
      ),
    );
    // Select a different item than the initial one.
    await tester.tap(find.byType(DropdownMenu<MenuItem>));
    await tester.pump();
    await tester.tap(findMenuItem(MenuItem.menuItem2));
    await tester.pump();

    expect(onSelectedCallCount, 1);
  });

  testWidgets('onSelect is called exactly once when reseted', (WidgetTester tester) async {
    var onSelectedCallCount = 0;
    final fieldKey = GlobalKey<FormFieldState<MenuItem>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownMenuFormField<MenuItem>(
            key: fieldKey,
            dropdownMenuEntries: menuEntries,
            onSelected: (MenuItem? value) {
              onSelectedCallCount++;
            },
          ),
        ),
      ),
    );

    fieldKey.currentState!.reset();
    await tester.pump();
    expect(onSelectedCallCount, 1);
  });

  testWidgets('DropdownMenuFormField does not crash at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.shrink(
              child: DropdownMenuFormField<MenuItem>(dropdownMenuEntries: menuEntries),
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(DropdownMenuFormField<MenuItem>)), Size.zero);
  });
}
