// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Default localized resource values for the material widgets.
///
/// This class is just a placeholder, it only provides english values.
class MaterialLocalizations {
  const MaterialLocalizations(this.locale) : assert(locale != null);

  final Locale locale;

  static Future<MaterialLocalizations> load(Locale locale) {
    return new SynchronousFuture<MaterialLocalizations>(new MaterialLocalizations(locale));
  }

  static MaterialLocalizations of(BuildContext context) {
    return Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
  }

  String get openAppDrawerTooltip => 'Open navigation menu';

  String get backButtonTooltip => 'Back';

  String get closeButtonTooltip => 'Close';

  String get nextMonthTooltip => 'Next month';

  String get previousMonthTooltip => 'Previous month';
}
