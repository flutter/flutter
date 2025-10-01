// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/controls.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';

import 'utils/widget_preview_scaffold_test_utils.dart';

// Applies localization theming allowing for direct comparison of `themeData` against the theme
// data retreived from the tree.
ThemeData localizeThemeData(ThemeData themeData) {
  return ThemeData.localize(
    themeData,
    themeData.typography.geometryThemeFor(ScriptCategory.englishLike),
  );
}

// Resolves `themeData` so it can be directly compared against the theme data retreived from the
// tree.
CupertinoThemeData resolveCupertinoThemeData(
  BuildContext context,
  CupertinoThemeData themeData,
) {
  return themeData.resolveFrom(context);
}

void expectTheme({
  required BuildContext context,
  required ThemeData materialTheme,
  required CupertinoThemeData cupertinoTheme,
}) {
  ThemeData actualMaterialTheme = Theme.of(context);
  CupertinoThemeData actualCupertinoTheme = CupertinoTheme.of(context);
  expect(actualMaterialTheme, localizeThemeData(materialTheme));
  expect(
    actualCupertinoTheme,
    resolveCupertinoThemeData(context, cupertinoTheme),
  );
}

WidgetPreviewerWidgetScaffolding previewForBrightness({
  required Key key,
  Brightness? brightness,
  Brightness? platformBrightness,
  PreviewTheme? previewTheme,
}) {
  final controller = FakeWidgetPreviewScaffoldController();
  return WidgetPreviewerWidgetScaffolding(
    platformBrightness: platformBrightness ?? Brightness.light,
    child: WidgetPreviewWidget(
      controller: controller,
      preview: WidgetPreview.test(
        builder: () => Text('Foo', key: key),
        previewData: Preview(theme: previewTheme, brightness: brightness),
      ),
    ),
  );
}

final PreviewThemeData previewThemeData = PreviewThemeData(
  materialLight: ThemeData.light().copyWith(primaryColor: Colors.red),
  materialDark: ThemeData.dark().copyWith(primaryColor: Colors.blue),
  cupertinoLight: CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.yellow,
  ),
  cupertinoDark: CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.green,
  ),
);

void main() {
  testWidgets('Theming is correctly propagated down to the previewed widget', (
    tester,
  ) async {
    final key = GlobalKey();

    // Check that both Material and Cupertino light themes are available to the previewed widget.
    WidgetPreviewerWidgetScaffolding widgetPreview = previewForBrightness(
      key: key,
      brightness: Brightness.light,
      previewTheme: () => previewThemeData,
    );
    await tester.pumpWidget(widgetPreview);

    expectTheme(
      context: key.currentContext!,
      materialTheme: previewThemeData.materialLight!,
      cupertinoTheme: previewThemeData.cupertinoLight!,
    );

    // Check that both Material and Cupertino dark themes are available to the previewed widget.
    widgetPreview = previewForBrightness(
      key: key,
      brightness: Brightness.dark,
      previewTheme: () => previewThemeData,
    );
    await tester.pumpWidget(widgetPreview);

    expectTheme(
      context: key.currentContext!,
      materialTheme: previewThemeData.materialDark!,
      cupertinoTheme: previewThemeData.cupertinoDark!,
    );
  });

  testWidgets('Default theme is used if no preview theme is specified', (
    tester,
  ) async {
    final key = GlobalKey();
    // Check that both Material and Cupertino light themes are available to the previewed widget.
    WidgetPreviewerWidgetScaffolding widgetPreview = previewForBrightness(
      key: key,
      brightness: Brightness.light,
    );
    await tester.pumpWidget(widgetPreview);

    expectTheme(
      context: key.currentContext!,
      materialTheme: ThemeData(),
      cupertinoTheme: CupertinoThemeData(),
    );

    // Check that both Material and Cupertino dark themes are available to the previewed widget.
    widgetPreview = previewForBrightness(key: key, brightness: Brightness.dark);
    await tester.pumpWidget(widgetPreview);

    expectTheme(
      context: key.currentContext!,
      materialTheme: ThemeData(),
      cupertinoTheme: CupertinoThemeData(),
    );
  });

  testWidgets('$BrightnessToggleButton correctly toggles preview brightness', (
    tester,
  ) async {
    final key = GlobalKey();

    // Check that both Material and Cupertino light themes are available to the previewed widget.
    WidgetPreviewerWidgetScaffolding widgetPreview = previewForBrightness(
      key: key,
      brightness: Brightness.light,
      previewTheme: () => previewThemeData,
    );
    await tester.pumpWidget(widgetPreview);

    final Finder brightnessToggle = find.byType(BrightnessToggleButton);
    expect(brightnessToggle, findsOne);
    expect(find.byTooltip('Switch to dark mode'), findsOne);
    final WidgetPreviewWidgetState state = tester
        .state<WidgetPreviewWidgetState>(find.byWidget(widgetPreview.child));
    expect(state.brightnessListenable.value, Brightness.light);

    expectTheme(
      context: key.currentContext!,
      materialTheme: previewThemeData.materialLight!,
      cupertinoTheme: previewThemeData.cupertinoLight!,
    );

    // Toggle to dark mode.
    await tester.tap(brightnessToggle);
    await tester.pumpAndSettle();

    expect(brightnessToggle, findsOne);
    expect(find.byTooltip('Switch to light mode'), findsOne);
    expect(state.brightnessListenable.value, Brightness.dark);

    // Check that both Material and Cupertino dark themes are available to the previewed widget.
    expectTheme(
      context: key.currentContext!,
      materialTheme: previewThemeData.materialDark!,
      cupertinoTheme: previewThemeData.cupertinoDark!,
    );
  });

  testWidgets(
    "Updated brightness property doesn't override state set by $BrightnessToggleButton",
    (tester) async {
      final key = GlobalKey();

      // Start with no explicit brightness set. This should use the system brightness (light).
      WidgetPreviewerWidgetScaffolding widgetPreview = previewForBrightness(
        key: key,
        previewTheme: () => previewThemeData,
      );
      await tester.pumpWidget(widgetPreview);

      final Finder brightnessToggle = find.byType(BrightnessToggleButton);
      final WidgetPreviewWidgetState state = tester
          .state<WidgetPreviewWidgetState>(find.byWidget(widgetPreview.child));

      void expectLightMode() {
        expect(brightnessToggle, findsOne);
        expect(find.byTooltip('Switch to dark mode'), findsOne);

        expect(state.brightnessListenable.value, Brightness.light);

        expectTheme(
          context: key.currentContext!,
          materialTheme: previewThemeData.materialLight!,
          cupertinoTheme: previewThemeData.cupertinoLight!,
        );
      }

      void expectDarkMode() {
        expect(brightnessToggle, findsOne);
        expect(find.byTooltip('Switch to light mode'), findsOne);

        expect(state.brightnessListenable.value, Brightness.dark);

        expectTheme(
          context: key.currentContext!,
          materialTheme: previewThemeData.materialDark!,
          cupertinoTheme: previewThemeData.cupertinoDark!,
        );
      }

      // We start in light mode.
      expectLightMode();

      // Switch to dark mode in the preview.
      await tester.tap(brightnessToggle);
      await tester.pumpAndSettle();
      expectDarkMode();

      // Set an initial brightness for the preview to 'light'.
      widgetPreview = previewForBrightness(
        key: key,
        previewTheme: () => previewThemeData,
        brightness: Brightness.light,
      );
      await tester.pumpWidget(widgetPreview);

      // Confirm that the initial brightness is set to light but that the preview is still using
      // dark mode since the theme was changed manually via the UI.
      expect(state.widget.preview.brightness, Brightness.light);
      expectDarkMode();

      // Manually switch back to light mode.
      await tester.tap(brightnessToggle);
      await tester.pumpAndSettle();
      expectLightMode();

      // The preview brightness is now light, matching the current platform brightness.
      // Change the platform brightness to `dark` and remove the initial brightness, which should
      // cause the preview to use the dark theme.
      widgetPreview = previewForBrightness(
        key: key,
        previewTheme: () => previewThemeData,
        brightness: Brightness.dark,
      );
      await tester.pumpWidget(widgetPreview);
      expectDarkMode();
    },
  );
}
