// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

// TODO(ianh): Figure out actual specced height for status bar
const double kStatusBarHeight = 50.0;

// TODO(eseidel) Toolbar needs to change size based on orientation:
// http://www.google.com/design/spec/layout/structure.html#structure-app-bar
// Mobile Landscape: 48dp
// Mobile Portrait: 56dp
// Tablet/Desktop: 64dp
const double kToolBarHeight = 56.0;
const double kExtendedToolBarHeight = 128.0;

// https://www.google.com/design/spec/layout/metrics-keylines.html#metrics-keylines-keylines-spacing
const double kListTitleHeight = 72.0;
const double kListSubtitleHeight = 48.0;

const double kOneLineListItemHeight = 48.0;
const double kOneLineListItemWithAvatarHeight = 56.0;
const double kTwoLineListItemHeight = 72.0;
const double kThreeLineListItemHeight = 88.0;

const double kMaterialDrawerHeight = 140.0;
const double kScrollbarSize = 10.0;
const Duration kScrollbarFadeDuration = const Duration(milliseconds: 250);
const Duration kScrollbarFadeDelay = const Duration(milliseconds: 300);
const double kFadingEdgeLength = 12.0;
const double kPressedStateDuration = 64.0; // units?
const Duration kThemeChangeDuration = const Duration(milliseconds: 200);

const EdgeDims kDialogHeadingPadding = const EdgeDims.TRBL(24.0, 24.0, 20.0, 24.0);

const double kRadialReactionRadius = 24.0; // Pixels
const Duration kRadialReactionDuration = const Duration(milliseconds: 200);
const int kRadialReactionAlpha = 0x33;
