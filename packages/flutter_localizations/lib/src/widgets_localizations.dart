// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'l10n/generated_widgets_localizations.dart';

/// Localized values for widgets.
///
/// Currently this class just maps [locale] to [textDirection]. All locales
/// are [TextDirection.ltr] except for locales with the following
/// [Locale.languageCode] values, which are [TextDirection.rtl]:
///
///   * ar - Arabic
///   * fa - Farsi
///   * he - Hebrew
///   * ps - Pashto
///   * sd - Sindhi
///   * ur - Urdu
abstract class GlobalWidgetsLocalizations implements WidgetsLocalizations {
  /// Construct an object that defines the localized values for the widgets
  /// library for the given `locale`.
  ///
  /// [LocalizationsDelegate] implementations typically call the static [load]
  /// function, rather than constructing this class directly.
  const GlobalWidgetsLocalizations({
    required this.textDirection,
  });

  @override
  final TextDirection textDirection;

  /// A [LocalizationsDelegate] that uses [GlobalWidgetsLocalizations.load]
  /// to create an instance of this class.
  ///
  /// [WidgetsApp] automatically adds this value to [WidgetsApp.localizationsDelegates].
  static const LocalizationsDelegate<WidgetsLocalizations> delegate = _WidgetsLocalizationsDelegate();
}

class _WidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const _WidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => kWidgetsSupportedLanguages.contains(locale.languageCode);

  // See http://en.wikipedia.org/wiki/Right-to-left
  static const List<String> _rtlLanguages = <String>[
    'ar', // Arabic
    'fa', // Farsi
    'he', // Hebrew
    'ps', // Pashto
    'ur', // Urdu
  ];

  static final Map<Locale, Future<WidgetsLocalizations>> _loadedTranslations = <Locale, Future<WidgetsLocalizations>>{};

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    assert(isSupported(locale));
    return _loadedTranslations.putIfAbsent(locale, () {
      return SynchronousFuture<WidgetsLocalizations>(getWidgetsTranslation(
        locale,
        _rtlLanguages.contains(locale.languageCode.toLowerCase()) ? TextDirection.rtl : TextDirection.ltr,
      )!);
    });
  }

  @override
  bool shouldReload(_WidgetsLocalizationsDelegate old) => false;

  @override
  String toString() => 'GlobalWidgetsLocalizations.delegate(${kWidgetsSupportedLanguages.length} locales)';
}
