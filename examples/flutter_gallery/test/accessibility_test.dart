import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gallery/demo/all.dart';

void main() {
  group('All material demos meet recommended tap target sizes', () {
    testWidgets('backdrop_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: BackdropDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('bottom_app_bar_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: BottomAppBarDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('bottom_navigation_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: BottomNavigationDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('buttons_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ButtonsDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('cards_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: CardsDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('chip_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ChipDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('data_table_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DataTableDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('date_and_time_picker_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DateAndTimePickerDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('dialog_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DialogDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('drawer_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DrawerDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('elevation_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ElevationDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('expansion_panels_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ExpansionPanelsDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('grid_list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const GridListDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('icons_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: IconsDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('leave_behind_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const LeaveBehindDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('list_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const ListDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('menu_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const MenuDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('modal_bottom_sheet_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ModalBottomSheetDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('overscroll_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const OverscrollDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('page_selector_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: PageSelectorDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('persistent_bottom_sheet_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: PersistentBottomSheetDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('progress_indicator_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ProgressIndicatorDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('reorderable_list_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const ReorderableListDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('scrollable_tabs_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ScrollableTabsDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('search_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: SearchDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('selection_controls_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: SelectionControlsDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('slider_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: SliderDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('snack_bar_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const SnackBarDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('tabs_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TabsDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('tabs_fab_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TabsFabDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('text_form_field_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const TextFormFieldDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('tooltip_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TooltipDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('two_level_list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TwoLevelListDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  group('All material demos meet text contrast guidelines', () {
    testWidgets('backdrop_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: BackdropDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('bottom_app_bar_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: BottomAppBarDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    }, skip: true); // https://github.com/flutter/flutter/issues/21651

    testWidgets('bottom_navigation_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: BottomNavigationDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('buttons_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ButtonsDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    }, skip: true); // https://github.com/flutter/flutter/issues/21647

    testWidgets('cards_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: CardsDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    }, skip: true); // https://github.com/flutter/flutter/issues/21651

    testWidgets('chip_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ChipDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    }, skip: true); // https://github.com/flutter/flutter/issues/21647

    testWidgets('data_table_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DataTableDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    }, skip: true); // https://github.com/flutter/flutter/issues/21647

    testWidgets('date_and_time_picker_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DateAndTimePickerDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    }, skip: true); // https://github.com/flutter/flutter/issues/21647

    testWidgets('dialog_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DialogDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('drawer_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: DrawerDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('elevation_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ElevationDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('expansion_panels_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ExpansionPanelsDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('grid_list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const GridListDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('icons_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: IconsDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    }, skip: true); // https://github.com/flutter/flutter/issues/21647

    testWidgets('leave_behind_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const LeaveBehindDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const ListDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('menu_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const MenuDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('modal_bottom_sheet_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ModalBottomSheetDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('overscroll_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const OverscrollDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('page_selector_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: PageSelectorDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('persistent_bottom_sheet_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: PersistentBottomSheetDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('progress_indicator_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ProgressIndicatorDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('reorderable_list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const ReorderableListDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('scrollable_tabs_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: ScrollableTabsDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('search_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: SearchDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    }, skip: true); // https://github.com/flutter/flutter/issues/21651

    testWidgets('selection_controls_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: SelectionControlsDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('slider_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: SliderDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('snack_bar_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const SnackBarDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('tabs_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TabsDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('tabs_fab_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TabsFabDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('text_form_field_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: const TextFormFieldDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('tooltip_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TooltipDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('two_level_list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: TwoLevelListDemo()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}