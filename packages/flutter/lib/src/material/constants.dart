// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

/// The height of the toolbar component of the [AppBar].
const double kToolbarHeight = 56.0;

/// The height of the bottom navigation bar.
const double kBottomNavigationBarHeight = 56.0;

/// The height of a tab bar containing text.
const double kTextTabBarHeight = 48.0;

/// The amount of time theme change animations should last.
const Duration kThemeChangeDuration = Duration(milliseconds: 200);

/// The radius of a circular material ink response in logical pixels.
const double kRadialReactionRadius = 20.0;

/// The amount of time a circular material ink response should take to expand to its full size.
const Duration kRadialReactionDuration = Duration(milliseconds: 100);

/// The value of the alpha channel to use when drawing a circular material ink response.
const int kRadialReactionAlpha = 0x1F;

/// The duration of the horizontal scroll animation that occurs when a tab is tapped.
const Duration kTabScrollDuration = Duration(milliseconds: 300);

/// The horizontal padding included by [Tab]s.
const EdgeInsets kTabLabelPadding = EdgeInsets.symmetric(horizontal: 16.0);

/// The padding added around material list items.
const EdgeInsets kMaterialListPadding = EdgeInsets.symmetric(vertical: 8.0);
