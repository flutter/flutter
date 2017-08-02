// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart';

import 'i18n/stock_messages_all.dart';

// Wrappers for strings that are shown in the UI.  The strings can be
// translated for different locales using the Dart intl package.
//
// Locale-specific values for the strings live in the i18n/*.arb files.

class StockStrings {
  const StockStrings(this.locale);

  final Locale locale;

  String get _scopedLocaleName => '${locale.languageCode}_STOCKS';

  static Future<StockStrings> load(Locale locale) {
    return initializeMessages('${locale.languageCode}_STOCKS')
      .then((Null _) {
        return new Future<StockStrings>.value(new StockStrings(locale));
      });
  }

  static StockStrings of(BuildContext context) {
    return LocalizedResources.of(context).resourcesFor<StockStrings>(StockStrings);
  }

  String title() {
    return Intl.message(
      '<Stocks>',
      name: 'title',
      desc: 'Title for the Stocks application',
      locale: _scopedLocaleName,
    );
  }

  String market() => Intl.message(
    '<MARKET>',
    name: 'market',
    desc: 'Label for the Market tab',
    locale: _scopedLocaleName,
  );

  String portfolio() => Intl.message(
    '<PORTFOLIO>',
    name: 'portfolio',
    desc: 'Label for the Portfolio tab',
    locale: _scopedLocaleName,
  );
}
