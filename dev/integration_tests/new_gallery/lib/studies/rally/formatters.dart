// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:gallery/data/gallery_options.dart';
import 'package:intl/intl.dart';

/// Get the locale string for the context.
String locale(BuildContext context) =>
    GalleryOptions.of(context).locale.toString();

/// Currency formatter for USD.
NumberFormat usdWithSignFormat(BuildContext context, {int decimalDigits = 2}) {
  return NumberFormat.currency(
    locale: locale(context),
    name: '\$',
    decimalDigits: decimalDigits,
  );
}

/// Percent formatter with two decimal points.
NumberFormat percentFormat(BuildContext context, {int decimalDigits = 2}) {
  return NumberFormat.decimalPercentPattern(
    locale: locale(context),
    decimalDigits: decimalDigits,
  );
}

/// Date formatter with year / number month / day.
DateFormat shortDateFormat(BuildContext context) =>
    DateFormat.yMd(locale(context));

/// Date formatter with year / month / day.
DateFormat longDateFormat(BuildContext context) =>
    DateFormat.yMMMMd(locale(context));

/// Date formatter with abbreviated month and day.
DateFormat dateFormatAbbreviatedMonthDay(BuildContext context) =>
    DateFormat.MMMd(locale(context));

/// Date formatter with year and abbreviated month.
DateFormat dateFormatMonthYear(BuildContext context) =>
    DateFormat.yMMM(locale(context));
