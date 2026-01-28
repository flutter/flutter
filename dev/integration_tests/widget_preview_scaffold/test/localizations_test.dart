// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart'
    hide PreviewWidget;

import 'utils/localizations_utils.dart';
import 'utils/widget_preview_scaffold_test_utils.dart';

void expectLocalization<T extends AppLocalizations?>({
  required BuildContext context,
  required PreviewLocalizationsData? expected,
}) {
  final AppLocalizations? actual = AppLocalizations.of(context);
  expect(actual, isA<T>());
  if (expected == null) {
    expect(actual, isNull);
  }
  expect(actual!.localeName, expected!.locale?.languageCode);
  expect(
    AppLocalizations.localizationsDelegates,
    expected.localizationsDelegates,
  );
}

WidgetPreviewerWidgetScaffolding previewForLocalizations({
  required Key key,
  PreviewLocalizations? previewLocalizationsData,
}) {
  final controller = FakeWidgetPreviewScaffoldController();
  return WidgetPreviewerWidgetScaffolding(
    child: WidgetPreviewWidget(
      controller: controller,
      preview: WidgetPreview.test(
        builder: () => Text('Foo', key: key),
        previewData: Preview(localizations: previewLocalizationsData),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Localization data is correctly propagated down to the previewed widget',
    (tester) async {
      final key = GlobalKey();
      PreviewLocalizationsData previewLocalizationsData = forLocale('en');

      // Check that both en and es localizations are available to the previewed widget.
      WidgetPreviewerWidgetScaffolding widgetPreview = previewForLocalizations(
        key: key,
        previewLocalizationsData: () => previewLocalizationsData,
      );
      await tester.pumpWidget(widgetPreview);

      expectLocalization<AppLocalizationsEn>(
        context: key.currentContext!,
        expected: previewLocalizationsData,
      );

      previewLocalizationsData = forLocale('es');
      widgetPreview = previewForLocalizations(
        key: key,
        previewLocalizationsData: () => previewLocalizationsData,
      );
      await tester.pumpWidget(widgetPreview);

      expectLocalization<AppLocalizationsEs>(
        context: key.currentContext!,
        expected: previewLocalizationsData,
      );
    },
  );
}
