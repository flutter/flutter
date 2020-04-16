// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gallery/gallery/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gallery/demo/all.dart';
import 'package:flutter_gallery/gallery/themes.dart';

void main() {
  group('All material demos meet recommended tap target sizes', () {
    testWidgets('backdrop_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: BackdropDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('bottom_app_bar_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: BottomAppBarDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('bottom_navigation_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: BottomNavigationDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('buttons_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ButtonsDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('cards_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: CardsDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('chip_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ChipDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    }, skip: true); // https://github.com/flutter/flutter/issues/42455

    testWidgets('data_table_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DataTableDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('date_and_time_picker_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DateAndTimePickerDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('dialog_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DialogDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('drawer_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DrawerDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('elevation_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ElevationDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('expansion_panels_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ExpansionPanelsDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('grid_list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: GridListDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('icons_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: IconsDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('leave_behind_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: LeaveBehindDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: ListDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('menu_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: MenuDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('modal_bottom_sheet_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ModalBottomSheetDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('overscroll_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: OverscrollDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('page_selector_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: PageSelectorDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('persistent_bottom_sheet_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: PersistentBottomSheetDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('progress_indicator_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ProgressIndicatorDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('reorderable_list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: ReorderableListDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('scrollable_tabs_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ScrollableTabsDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('search_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: SearchDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('selection_controls_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: SelectionControlsDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('slider_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: SliderDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('snack_bar_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: SnackBarDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('tabs_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TabsDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('tabs_fab_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TabsFabDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('text_form_field_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: TextFormFieldDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('tooltip_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TooltipDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('expansion_tile_list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ExpansionTileListDemo()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  group('All material demos have labeled tap targets', () {
    testWidgets('backdrop_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: BackdropDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('bottom_app_bar_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: BottomAppBarDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('bottom_navigation_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: BottomNavigationDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('buttons_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ButtonsDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('cards_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: CardsDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('chip_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ChipDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('data_table_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DataTableDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    }, skip: true); // DataTables are not accessible, https://github.com/flutter/flutter/issues/10830

    testWidgets('date_and_time_picker_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DateAndTimePickerDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('dialog_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DialogDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('drawer_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DrawerDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('elevation_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ElevationDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('expansion_panels_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ExpansionPanelsDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('grid_list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: GridListDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('icons_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: IconsDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('leave_behind_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: LeaveBehindDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: ListDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('menu_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: MenuDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('modal_bottom_sheet_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ModalBottomSheetDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('overscroll_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: OverscrollDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('page_selector_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: PageSelectorDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('persistent_bottom_sheet_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: PersistentBottomSheetDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('progress_indicator_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ProgressIndicatorDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('reorderable_list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: ReorderableListDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('scrollable_tabs_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ScrollableTabsDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('search_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: SearchDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('selection_controls_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: SelectionControlsDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('slider_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: SliderDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('snack_bar_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: SnackBarDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('tabs_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TabsDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('tabs_fab_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TabsFabDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('text_form_field_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: TextFormFieldDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('tooltip_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TooltipDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('expansion_tile_list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ExpansionTileListDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('All material demos meet text contrast guidelines', () {
    final List<ThemeData> themes = <ThemeData>[
      kLightGalleryTheme,
      ThemeData.light(),
      ThemeData.dark(),
    ];

    const List<String> themeNames = <String>[
      'kLightGalleryTheme',
      'ThemeData.light()',
      'ThemeData.dark()',
    ];

    for (int themeIndex = 0; themeIndex < themes.length; themeIndex += 1) {
      final ThemeData theme = themes[themeIndex];
      final String themeName = themeNames[themeIndex];

      testWidgets('backdrop_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: BackdropDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('bottom_app_bar_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: BottomAppBarDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('bottom_navigation_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: BottomNavigationDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('buttons_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: ButtonsDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('cards_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: CardsDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('chip_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: ChipDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('data_table_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: DataTableDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('date_and_time_picker_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: DateAndTimePickerDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('dialog_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: DialogDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      }, skip: theme == ThemeData.dark()); // Raised Button does not follow
      // theme. https://github.com/flutter/flutter/issues/16488,
      // https://github.com/flutter/flutter/issues/19623

      testWidgets('drawer_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: DrawerDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('elevation_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: ElevationDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('expansion_panels_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: ExpansionPanelsDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('grid_list_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: const GridListDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('icons_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: IconsDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('leave_behind_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: const LeaveBehindDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('list_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: const ListDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('menu_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: const MenuDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('modal_bottom_sheet_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(theme: theme, home: ModalBottomSheetDemo())
        );
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      }, skip: theme == ThemeData.dark()); // Raised Button does not follow
      // theme. https://github.com/flutter/flutter/issues/16488,
      // https://github.com/flutter/flutter/issues/19623

      testWidgets('overscroll_demo', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(const MaterialApp(home: OverscrollDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('page_selector_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: PageSelectorDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('persistent_bottom_sheet_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(theme: theme, home: PersistentBottomSheetDemo())
        );
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      }, skip: theme == ThemeData.dark()); // Raised Button does not follow
      // theme. https://github.com/flutter/flutter/issues/16488,
      // https://github.com/flutter/flutter/issues/19623

      testWidgets('progress_indicator_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: ProgressIndicatorDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('reorderable_list_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: const ReorderableListDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('scrollable_tabs_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: ScrollableTabsDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('search_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: SearchDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('selection_controls_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: SelectionControlsDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('slider_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: SliderDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('snack_bar_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(theme: theme, home: const SnackBarDemo())
        );
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      }, skip: theme == ThemeData.dark()); // Raised Button does not follow
      // theme. https://github.com/flutter/flutter/issues/16488,
      // https://github.com/flutter/flutter/issues/19623

      testWidgets('tabs_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: TabsDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('tabs_fab_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: TabsFabDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('text_form_field_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: const TextFormFieldDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('tooltip_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: TooltipDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('expansion_tile_list_demo $themeName', (WidgetTester tester) async {
        tester.binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: ExpansionTileListDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });

  group('Gallery home page meets text contrast guidelines', () {
    testWidgets('options menu', (WidgetTester tester) async {
      await tester.pumpWidget(const GalleryApp(testMode: true));
      await tester.tap(find.byTooltip('Toggle options page'));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('options menu - dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(const GalleryApp(testMode: true));
      await tester.tap(find.byTooltip('Toggle options page'));
      await tester.pumpAndSettle();

      // Toggle dark mode.
      final Finder themeToggleContainer = find.ancestor(
        of: find.text('Theme'),
        matching: find.byType(Container),
      );
      final Finder themeMenuButton = find.descendant(
        of: themeToggleContainer,
        matching: find.byIcon(Icons.arrow_drop_down),
      );
      await tester.tap(themeMenuButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
