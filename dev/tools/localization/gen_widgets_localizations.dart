// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'localizations_utils.dart';

String generateWidgetsHeader(String regenerateInstructions) {
  return '''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use:
// $regenerateInstructions

import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

import '../widgets_localizations.dart';

// The classes defined here encode all of the translations found in the
// `flutter_localizations/lib/src/l10n/*.arb` files.
//
// These classes are constructed by the [getWidgetsTranslation] method at the
// bottom of this file, and used by the [_WidgetsLocalizationsDelegate.load]
// method defined in `flutter_localizations/lib/src/widgets_localizations.dart`.''';
}

/// Returns the source of the constructor for a GlobalWidgetsLocalizations
/// subclass.
String generateWidgetsConstructor(LocaleInfo locale) {
  final String localeName = locale.originalString;
  return '''
  /// Create an instance of the translation bundle for ${describeLocale(localeName)}.
  ///
  /// For details on the meaning of the arguments, see [GlobalWidgetsLocalizations].
  const WidgetsLocalization${locale.camelCase()}({
    required TextDirection textDirection,
  }) : super(
    textDirection: textDirection,
  );''';
}

const String widgetsFactoryName = 'getWidgetsTranslation';

const String widgetsFactoryDeclaration = '''
GlobalWidgetsLocalizations? getWidgetsTranslation(
  Locale locale,
  TextDirection textDirection,
) {''';

const String widgetsFactoryArguments =
    'textDirection: textDirection';

const String widgetsSupportedLanguagesConstant = 'kWidgetsSupportedLanguages';

const String widgetsSupportedLanguagesDocMacro = 'flutter.localizations.widgets.languages';
