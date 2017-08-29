// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'i18n/localizations.dart';

/// Localized strings for the material widgets.
class MaterialLocalizations {
  /// Construct an object that defines the material widgets' localized strings
  /// for the given `locale`.
  const MaterialLocalizations(this.locale) : assert(locale != null);

  /// The locale for which the values of this class's localized resources
  /// have been translated.
  final Locale locale;

  String _lookup(String name) {
    final Map<String, String> nameToValue = localizations[locale.toString()]
      ?? localizations[locale.languageCode]
      ?? localizations['en'];
    return nameToValue != null ? nameToValue[name] : null;
  }

  /// The tooltip for the leading [AppBar] menu (aka 'hamburger') button
  String get openAppDrawerTooltip => _lookup("openAppDrawerTooltip");

  /// The [BackButton]'s tooltip.
  String get backButtonTooltip => _lookup("backButtonTooltip");

  /// The [CloseButton]'s tooltip.
  String get closeButtonTooltip => _lookup("closeButtonTooltip");

  /// The tooltip for the [MonthPicker]'s "next month" button.
  String get nextMonthTooltip => _lookup("nextMonthTooltip");

  /// The tooltip for the [MonthPicker]'s "previous month" button.
  String get previousMonthTooltip => _lookup("previousMonthTooltip");

  /// Creates an object that provides localized resource values for the
  /// for the widgets of the material library.
  ///
  /// This method is typically used to create a [DefaultLocalizationsDelegate].
  /// The [MaterialApp] does so by default.
  static Future<MaterialLocalizations> load(Locale locale) {
    return new SynchronousFuture<MaterialLocalizations>(new MaterialLocalizations(locale));
  }

  /// The `MaterialLocalizations` from the closest [Localizations] instance
  /// that encloses the given context.
  ///
  /// This method is just a convenient shorthand for:
  /// `Localizations.of<MaterialLocalizations>(context, MaterialLocalizations)`.
  ///
  /// References to the localized resources defined by this class are typically
  /// written in terms of this method. For example:
  ///
  /// ```dart
  /// tooltip: MaterialLocalizations.of(context).backButtonTooltip,
  /// ```
  static MaterialLocalizations of(BuildContext context) {
    return Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
  }
}
