// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Central Kurdish (ckb) localizations', (WidgetTester tester) async {
    const Locale locale = Locale('ckb');

    expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
    expect(GlobalCupertinoLocalizations.delegate.isSupported(locale), isTrue);
    expect(GlobalWidgetsLocalizations.delegate.isSupported(locale), isTrue);

    final MaterialLocalizations material = await GlobalMaterialLocalizations.delegate.load(locale);
    final CupertinoLocalizations cupertino = await GlobalCupertinoLocalizations.delegate.load(
      locale,
    );
    final WidgetsLocalizations widgets = await GlobalWidgetsLocalizations.delegate.load(locale);

    expect(widgets.textDirection, TextDirection.rtl);
    expect(material.scriptCategory, ScriptCategory.tall);
    expect(material.timeOfDayFormat(), TimeOfDayFormat.H_colon_mm);
    expect(material.backButtonTooltip, 'گەڕانەوە');
    expect(material.cancelButtonLabel, 'هەڵوەشاندنەوە');
    expect(material.remainingTextFieldCharacterCount(0), 'هیچ پیتێک نەماوە');
    expect(material.selectedRowCountTitle(0), 'هیچ دانەیەک هەڵنەبژێردراوە');
    expect(cupertino.backButtonLabel, 'گەڕانەوە');
    expect(cupertino.cancelButtonLabel, 'هەڵوەشاندنەوە');
    expect(widgets.copyButtonLabel, 'لەبەرگرتنەوە');
    expect(widgets.pasteButtonLabel, 'لکاندن');
    expect(widgets.noResultsFound, 'هیچ ئەنجامێک نەدۆزرایەوە');
    expect(widgets.searchResultsFound, 'ئەنجامی گەڕان دۆزرایەوە');
  });
}
