// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class LocalizedMaterialResources {
  const LocalizedMaterialResources(this.locale) : assert(locale != null);

  final Locale locale;

  static Future<LocalizedMaterialResources> load(Locale locale) {
    return new SynchronousFuture<LocalizedMaterialResources>(new LocalizedMaterialResources(locale));
  }

  static LocalizedMaterialResources of(BuildContext context) {
    return LocalizedResources.of(context)
      .resourcesFor<LocalizedMaterialResources>(LocalizedMaterialResources);
  }

  String get openAppDrawerTooltip => 'Open navigation menu';

  String get backButtonTooltip => 'Back';

  String get closeButtonTooltip => 'Close';

  String get nextMonthTooltip => 'Next month';

  String get previousMonthTooltip => 'Previous month';
}
