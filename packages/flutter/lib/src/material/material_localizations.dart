// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Default localized resource values for the material widgets.
///
/// This class is just a placeholder, it only provides English values.
class MaterialLocalizations {
  const MaterialLocalizations._(this.locale) : assert(locale != null);

  /// The locale for which the values of this class's localized resources
  /// have been translated.
  final Locale locale;

  /// Creates an object that provides default localized resource values for the
  /// for the widgets of the material library.
  ///
  /// This method is typically used to create a [DefaultLocalizationsDelegate].
  /// The [MaterialApp] does so by default.
  static Future<MaterialLocalizations> load(Locale locale) {
    return new SynchronousFuture<MaterialLocalizations>(new MaterialLocalizations._(locale));
  }

  /// The `MaterialLocalizations` from the closest [Localizations] instance
  /// that encloses the given context.
  ///
  /// This method is just a convenient shorthand for:
  /// `Localizations.of<MaterialLocalizations>(context, MaterialLocalizations)`.
  ///
  /// References to the localized resources defined by this class are typically
  /// written in terms of this method. For example:
  /// ```dart
  /// tooltip: MaterialLocalizations.of(context).backButtonTooltip,
  /// ```
  static MaterialLocalizations of(BuildContext context) {
    return Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
  }

  /// The tooltip for the leading [AppBar] menu (aka 'hamburger') button
  String get openAppDrawerTooltip => 'Open navigation menu';

  /// The [BackButton]'s tooltip.
  String get backButtonTooltip => 'Back';

  /// The [CloseButton]'s tooltip.
  String get closeButtonTooltip => 'Close';

  /// The tooltip for the [MonthPicker]'s "next month" button.
  String get nextMonthTooltip => 'Next month';

  /// The tooltip for the [MonthPicker]'s "previous month" button.
  String get previousMonthTooltip => 'Previous month';
}
