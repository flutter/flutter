// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter widgets implementing Material Design animated icons.
library material_animated_icons;

import 'dart:math' as math show pi;
import 'dart:ui' as ui show Paint, Path, Canvas;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// This package is split into multiple parts to enable a private API that is
// testable.

// Public API.
part 'animated_icons/animated_icons.dart';
// Provides a public interface for referring to the private icon
// implementations.
part 'animated_icons/animated_icons_data.dart';

// Animated icons data files.
part 'animated_icons/data/arrow_menu.g.dart';
part 'animated_icons/data/menu_arrow.g.dart';
