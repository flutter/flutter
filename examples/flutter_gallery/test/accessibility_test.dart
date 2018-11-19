import 'package:flutter/material.dart';
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
    });

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

    testWidgets('two_level_list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TwoLevelListDemo()));
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
    }, skip: true);

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
    }, skip: true);

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
    }, skip: true);

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
    }, skip: true);

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
    }, skip: true);

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

    testWidgets('two_level_list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TwoLevelListDemo()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('All material demos meet text contrast guidelines', () {
    final List<ThemeData> themes = <ThemeData>[
      kLightGalleryTheme.data,
      ThemeData.light(),
      // TODO(hansmuller): add kDarkGalleryTheme.data, ThemeData.dark(), see #22044
    ];

    const List<String> themeNames = <String>[
      'kLightGalleryTheme',
      'ThemeData.light()',
      // TODO(hansmuller): add 'kDarkGalleryTheme', 'ThemeData.dark()', see 22044
    ];

    for (int themeIndex = 0; themeIndex < themes.length; themeIndex += 1) {
      final ThemeData theme = themes[themeIndex];
      final String themeName = themeNames[themeIndex];

      testWidgets('backdrop_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: BackdropDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('bottom_app_bar_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: BottomAppBarDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('bottom_navigation_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: BottomNavigationDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('buttons_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: ButtonsDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('cards_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: CardsDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('chip_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: ChipDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      }, skip: true); // https://github.com/flutter/flutter/issues/21647

      testWidgets('data_table_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: DataTableDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      }, skip: true); // https://github.com/flutter/flutter/issues/21647

      testWidgets('date_and_time_picker_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: DateAndTimePickerDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      }, skip: true); // https://github.com/flutter/flutter/issues/21647

      testWidgets('dialog_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: DialogDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('drawer_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: DrawerDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('elevation_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: ElevationDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('expansion_panels_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: ExpansionPanelsDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('grid_list_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: const GridListDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('icons_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: IconsDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      }, skip: true); // https://github.com/flutter/flutter/issues/21647

      testWidgets('leave_behind_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: const LeaveBehindDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('list_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: const ListDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('menu_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: const MenuDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('modal_bottom_sheet_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: ModalBottomSheetDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

    testWidgets('overscroll_demo', (WidgetTester tester) async {
      final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
      binding.addTime(const Duration(seconds: 3));
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: OverscrollDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

      testWidgets('page_selector_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: PageSelectorDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('persistent_bottom_sheet_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: PersistentBottomSheetDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('progress_indicator_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: ProgressIndicatorDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('reorderable_list_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: const ReorderableListDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('scrollable_tabs_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: ScrollableTabsDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('search_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: SearchDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      }, skip: true); // https://github.com/flutter/flutter/issues/21651

      testWidgets('selection_controls_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: SelectionControlsDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('slider_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: SliderDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('snack_bar_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: const SnackBarDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('tabs_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: TabsDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('tabs_fab_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: TabsFabDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('text_form_field_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: const TextFormFieldDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('tooltip_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: TooltipDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('two_level_list_demo $themeName', (WidgetTester tester) async {
        final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
        binding.addTime(const Duration(seconds: 3));
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(theme: theme, home: TwoLevelListDemo()));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });
}
