import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gallery/demo/all.dart';

void main() {
  group('All material demos meet recommended tap target sizes', () {
    testWidgets('backdrop_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new BackdropDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('bottom_app_bar_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new BottomAppBarDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('bottom_navigation_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new BottomNavigationDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('buttons_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new ButtonsDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('cards_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new CardsDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('chip_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new ChipDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('data_table_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new DataTableDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('date_and_time_picker_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new DateAndTimePickerDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    }, skip: true); // https://github.com/flutter/flutter/issues/21578

    testWidgets('dialog_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new DialogDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('drawer_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new DrawerDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('elevation_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new ElevationDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('expansion_panels_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new ExpansionPanelsDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('grid_list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: const GridListDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('icons_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new IconsDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('leave_behind_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: const LeaveBehindDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('list_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: const ListDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('menu_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: const MenuDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('modal_bottom_sheet_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new ModalBottomSheetDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('overscroll_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: const OverscrollDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('page_selector_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new PageSelectorDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('persistent_bottom_sheet_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new PersistentBottomSheetDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('progress_indicator_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new ProgressIndicatorDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('reorderable_list_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: const ReorderableListDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('scrollable_tabs_demo', (WidgetTester tester) async {
     final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new ScrollableTabsDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('search_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new SearchDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('selection_controls_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new SelectionControlsDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('slider_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new SliderDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('snack_bar_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: const SnackBarDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('tabs_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new TabsDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('tabs_fab_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new TabsFabDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('text_form_field_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: const TextFormFieldDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('tooltip_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new TooltipDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('two_level_list_demo', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(new MaterialApp(home: new TwoLevelListDemo()));
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });
}