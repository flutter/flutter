// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:adaptive_breakpoints/adaptive_breakpoints.dart';
import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/material.dart';

/// The maximum width taken up by each item on the home screen.
const double maxHomeItemWidth = 1400.0;

/// Returns a boolean value whether the window is considered medium or large size.
///
/// When running on a desktop device that is also foldable, the display is not
/// considered desktop. Widgets using this method might consider the display is
/// large enough for certain layouts, which is not the case on foldable devices,
/// where only part of the display is available to said widgets.
///
/// Used to build adaptive and responsive layouts.
bool isDisplayDesktop(BuildContext context) =>
    !isDisplayFoldable(context) &&
    getWindowType(context) >= AdaptiveWindowType.medium;

/// Returns boolean value whether the window is considered medium size.
///
/// Used to build adaptive and responsive layouts.
bool isDisplaySmallDesktop(BuildContext context) {
  return getWindowType(context) == AdaptiveWindowType.medium;
}

/// Returns a boolean value whether the display has a hinge that splits the
/// screen into two, left and right sub-screens. Horizontal splits (top and
/// bottom sub-screens) are ignored for this application.
bool isDisplayFoldable(BuildContext context) {
  final DisplayFeature? hinge = MediaQuery.of(context).hinge;
  if (hinge == null) {
    return false;
  } else {
    // Vertical
    return hinge.bounds.size.aspectRatio < 1;
  }
}
