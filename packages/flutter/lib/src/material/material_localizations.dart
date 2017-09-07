// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'i18n/localizations.dart';

/// Defines the localized resource values used by the Material widgts.
///
/// See also:
///
///  * [DefaultMaterialLocalizations], which implements this interface
///    and supports a variety of locales.
abstract class MaterialLocalizations {
  /// The tooltip for the leading [AppBar] menu (aka 'hamburger') button
  String get openAppDrawerTooltip;

  /// The [BackButton]'s tooltip.
  String get backButtonTooltip;

  /// The [CloseButton]'s tooltip.
  String get closeButtonTooltip;

  /// The tooltip for the [MonthPicker]'s "next month" button.
  String get nextMonthTooltip;

  /// The tooltip for the [MonthPicker]'s "previous month" button.
  String get previousMonthTooltip;

  /// Title for the [LicensePage] widget.
  String get licensesPageTitle;

  /// Label for "cancel" buttons and menu items.
  String get cancelButtonLabel;

  /// Label for "close" buttons and menu items.
  String get closeButtonLabel;

  /// Label for "continue" buttons and menu items.
  String get continueButtonLabel;

  /// Label for "copy" edit buttons and menu items.
  String get copyButtonLabel;

  /// Label for "cut" edit buttons and menu items.
  String get cutButtonLabel;

  /// Label for OK buttons and menu items.
  String get okButtonLabel;

  /// Label for "paste" edit buttons and menu items.
  String get pasteButtonLabel;

  /// Label for "select all" edit buttons and menu items.
  String get selectAllButtonLabel;

  /// Label for the [AboutBox] button that shows the [LicensePage].
  String get viewLicensesButtonLabel;

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

/// Localized strings for the material widgets.
class DefaultMaterialLocalizations implements MaterialLocalizations {
  /// Construct an object that defines the material widgets' localized strings
  /// for the given `locale`.
  ///
  /// [LocalizationsDelegate] implementations typically call the static [load]
  /// function, rather than constructing this class directly.
  DefaultMaterialLocalizations(this.locale) {
    assert(locale != null);
    _nameToValue = localizations[locale.toString()]
      ?? localizations[locale.languageCode]
      ?? localizations['en']
      ?? <String, String>{};
  }

  Map<String, String> _nameToValue;

  /// The locale for which the values of this class's localized resources
  /// have been translated.
  final Locale locale;

  @override
  String get openAppDrawerTooltip => _nameToValue["openAppDrawerTooltip"];

  @override
  String get backButtonTooltip => _nameToValue["backButtonTooltip"];

  @override
  String get closeButtonTooltip => _nameToValue["closeButtonTooltip"];

  @override
  String get nextMonthTooltip => _nameToValue["nextMonthTooltip"];

  @override
  String get previousMonthTooltip => _nameToValue["previousMonthTooltip"];

  @override
  String get licensesPageTitle => _nameToValue["licensesPageTitle"];

  @override
  String get cancelButtonLabel => _nameToValue["cancelButtonLabel"];

  @override
  String get closeButtonLabel => _nameToValue["closeButtonLabel"];

  @override
  String get continueButtonLabel => _nameToValue["continueButtonLabel"];

  @override
  String get copyButtonLabel => _nameToValue["copyButtonLabel"];

  @override
  String get cutButtonLabel => _nameToValue["cutButtonLabel"];

  @override
  String get okButtonLabel => _nameToValue["okButtonLabel"];

  @override
  String get pasteButtonLabel => _nameToValue["pasteButtonLabel"];

  @override
  String get selectAllButtonLabel => _nameToValue["selectAllButtonLabel"];

  @override
  String get viewLicensesButtonLabel => _nameToValue["viewLicensesButtonLabel"];

  /// Creates an object that provides localized resource values for the
  /// for the widgets of the material library.
  ///
  /// This method is typically used to create a [LocalizationsDelegate].
  /// The [MaterialApp] does so by default.
  static Future<MaterialLocalizations> load(Locale locale) {
    return new SynchronousFuture<MaterialLocalizations>(new DefaultMaterialLocalizations(locale));
  }
}
