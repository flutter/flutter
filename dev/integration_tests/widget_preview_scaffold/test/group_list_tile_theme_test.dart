// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widget_previews.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widget_preview_scaffold/src/theme/ide_theme.dart';
import 'package:widget_preview_scaffold/src/theme/theme.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';

import 'utils/widget_preview_scaffold_test_utils.dart';

void main() {
  testWidgets(
    'WidgetPreviewGroupWidget does not leak the previewer ListTileTheme into previews',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/194660.
      //
      // The previewer styles its own ListTiles (e.g. the ExpansionTile header
      // of each preview group) with a tile color. A previewed widget that
      // provides its own MaterialApp and ThemeData must not inherit that color.
      WidgetsBinding.instance.debugExcludeRootWidgetInspector = true;
      final controller = FakeWidgetPreviewScaffoldController();
      late BuildContext previewContext;
      final group = WidgetPreviewGroup(
        name: 'group',
        previews: [
          WidgetPreview.test(
            previewData: const Preview(),
            builder: () => MaterialApp(
              home: Builder(
                builder: (BuildContext context) {
                  previewContext = context;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: themeFor(
            isDarkTheme: true,
            ideTheme: const IdeTheme(),
            theme: ThemeData.dark(),
          ),
          home: Material(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return WidgetPreviewerWindowConstraints(
                  constraints: constraints,
                  child: WidgetPreviewGroupWidget(
                    controller: controller,
                    group: group,
                  ),
                );
              },
            ),
          ),
        ),
      );

      // The previewer's ThemeData does set a tile color.
      final BuildContext groupContext = tester.element(
        find.byType(WidgetPreviewGroupWidget),
      );
      expect(Theme.of(groupContext).listTileTheme.tileColor, isNotNull);

      // The previewed MaterialApp's ThemeData does not, and nothing from the
      // previewer should override it.
      final ListTileThemeData previewListTileTheme = ListTileTheme.of(
        previewContext,
      );
      expect(previewListTileTheme.tileColor, isNull);
      expect(previewListTileTheme, Theme.of(previewContext).listTileTheme);

      // The previewer's own ExpansionTile header keeps the group styling.
      final BuildContext headerContext = tester.element(
        find.descendant(
          of: find.byType(ExpansionTile),
          matching: find.byType(ListTile),
        ),
      );
      expect(ListTileTheme.of(headerContext).dense, isTrue);
      expect(ListTileTheme.of(headerContext).tileColor, isNotNull);
    },
  );
}
