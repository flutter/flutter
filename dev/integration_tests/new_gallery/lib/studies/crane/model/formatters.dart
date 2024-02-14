// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

// Duration of time (e.g. 16h 12m)
String formattedDuration(BuildContext context, Duration duration,
    {bool? abbreviated}) {
  final localizations = GalleryLocalizations.of(context)!;

  final hoursShortForm = localizations.craneHours(duration.inHours.toInt());
  final minutesShortForm = localizations.craneMinutes(duration.inMinutes % 60);
  return localizations.craneFlightDuration(hoursShortForm, minutesShortForm);
}
