// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../data/gallery_options.dart';

/// The maximum width taken up by each item on the home screen.
const double maxHomeItemWidth = 1400.0;

/// The minimum width of a medium window in the Material Design breakpoint system.
const double _mediumWindowMinWidth = 1024.0;

/// The minimum width of a large window in the Material Design breakpoint system.
const double _largeWindowMinWidth = 1440.0;

/// Returns a boolean value whether the window is considered medium or large size.
///
/// Widgets using this method might consider the display is
/// large enough for certain layouts, which is not the case on foldable devices,
/// where only part of the display is available to said widgets.
///
/// Used to build adaptive and responsive layouts.
bool isDisplayDesktop(BuildContext context) {
  if (GalleryOptions.maybeOf(context)?.isTestMode ?? false) {
    return false;
  }
  return MediaQuery.sizeOf(context).width >= _mediumWindowMinWidth;
}

/// Returns boolean value whether the window is considered medium size.
///
/// Used to build adaptive and responsive layouts.
bool isDisplaySmallDesktop(BuildContext context) {
  if (GalleryOptions.maybeOf(context)?.isTestMode ?? false) {
    return false;
  }
  final double width = MediaQuery.sizeOf(context).width;
  return width >= _mediumWindowMinWidth && width < _largeWindowMinWidth;
}
