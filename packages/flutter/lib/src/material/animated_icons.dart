// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter widgets implementing Material Design animated icons.
library material_animated_icons;

import 'dart:math' as math show pi;
import 'dart:ui' as ui show Canvas, Paint, Path, lerpDouble;

import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/widgets.dart';

// This package is split into multiple parts to enable a private API that is
// testable.

// Public API.
part 'animated_icons/animated_icons.dart';

// Provides a public interface for referring to the private icon
// implementations.
part 'animated_icons/animated_icons_data.dart';

// Generated animated icon data files.
part 'animated_icons/data/add_event.g.dart';
part 'animated_icons/data/arrow_menu.g.dart';
part 'animated_icons/data/close_menu.g.dart';
part 'animated_icons/data/ellipsis_search.g.dart';
part 'animated_icons/data/event_add.g.dart';
part 'animated_icons/data/home_menu.g.dart';
part 'animated_icons/data/list_view.g.dart';
part 'animated_icons/data/menu_arrow.g.dart';
part 'animated_icons/data/menu_close.g.dart';
part 'animated_icons/data/menu_home.g.dart';
part 'animated_icons/data/pause_play.g.dart';
part 'animated_icons/data/play_pause.g.dart';
part 'animated_icons/data/search_ellipsis.g.dart';
part 'animated_icons/data/view_list.g.dart';
