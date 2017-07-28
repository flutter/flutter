// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Interface for localized resource values for the material widgets.
///
/// This class provides a default placeholder implementation that returns
/// hard-coded American English values.
class MaterialLocalizations {
  /// Create a placeholder object for the localized resources of material widgets
  /// which only provides American English strings.
  const MaterialLocalizations();

  /// The locale for which the values of this class's localized resources
  /// have been translated.
  Locale get locale => const Locale('en', 'US');

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
