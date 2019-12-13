// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:intl/date_symbols.dart' as intl;
import 'package:intl/date_symbol_data_custom.dart' as date_symbol_data_custom;
import '../l10n/generated_date_localizations.dart' as date_localizations;

/// Tracks if date i18n data has been loaded.
bool _dateIntlDataInitialized = false;

/// Loads i18n data for dates if it hasn't be loaded yet.
///
/// Only the first invocation of this function has the effect of loading the
/// data. Subsequent invocations have no effect.
void loadDateIntlDataIfNotLoaded() {
  if (!_dateIntlDataInitialized) {
    // TODO(garyq): Add support for scriptCodes. Do not strip scriptCode from string.

    // Keep track of initialzed locales, or will fail on attempted double init.
    // This can only happen if a locale with a stripped scriptCode has already
    // been initialzed. This should be removed when scriptCode stripping is removed.
    final Set<String> initializedLocales = <String>{};
    date_localizations.dateSymbols
      .cast<String, Map<String, dynamic>>()
      .forEach((String locale, Map<String, dynamic> data) {
        // Strip scriptCode from the locale, as we do not distinguish between scripts
        // for dates.
        final List<String> codes = locale.split('_');
        String countryCode;
        if (codes.length == 2) {
          countryCode = codes[1].length < 4 ? codes[1] : null;
        } else if (codes.length == 3) {
          countryCode = codes[1].length < codes[2].length ? codes[1] : codes[2];
        }
        locale = codes[0] + (countryCode != null ? '_' + countryCode : '');
        if (initializedLocales.contains(locale))
          return;
        initializedLocales.add(locale);
        // Perform initialization.
        assert(date_localizations.datePatterns.containsKey(locale));
        final intl.DateSymbols symbols = intl.DateSymbols.deserializeFromMap(data);
        date_symbol_data_custom.initializeDateFormattingCustom(
          locale: locale,
          symbols: symbols,
          patterns: date_localizations.datePatterns[locale],
        );
      });
    _dateIntlDataInitialized = true;
  }
}
