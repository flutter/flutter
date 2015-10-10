// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

/// Causes each RenderBox to paint a box around its bounds.
bool debugPaintSizeEnabled = false;

/// The color to use when painting RenderObject bounds.
ui.Color debugPaintSizeColor = const ui.Color(0xFF00FFFF);

/// Causes each RenderBox to paint a line at each of its baselines.
bool debugPaintBaselinesEnabled = false;

/// The color to use when painting alphabetic baselines.
ui.Color debugPaintAlphabeticBaselineColor = const ui.Color(0xFF00FF00);

/// The color ot use when painting ideographic baselines.
ui.Color debugPaintIdeographicBaselineColor = const ui.Color(0xFFFFD000);

/// Causes each Layer to paint a box around its bounds.
bool debugPaintLayerBordersEnabled = false;

/// The color to use when painting Layer borders.
ui.Color debugPaintLayerBordersColor = const ui.Color(0xFFFF9800);

/// Causes RenderObjects to paint warnings when painting outside their bounds.
bool debugPaintBoundsEnabled = false;

/// The color to use when painting RenderError boxes in checked mode.
ui.Color debugErrorBoxColor = const ui.Color(0xFFFF0000);
