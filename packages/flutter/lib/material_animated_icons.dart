// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter widgets implementing Material Design animated icons.
///
/// To use, import `package:flutter/material_animated_icons.dart`.
library material_animated_icons;

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

// This package is split into multiple parts to enable a private API that is
// testable.

// Public API.
part 'src/material_animated_icons/animated_icons.dart';
// Provides a public interface for referring to the private icon
// implementations.
part 'src/material_animated_icons/animated_icons_data.dart';
// Private API - this is the actual implementation of the drawing logic,
// We keep it private as we do not want to prematurely provide public API for
// vector graphics.
// See: https://github.com/flutter/flutter/issues/1831 for the progress of
// generic vector graphics support in Flutter.
part 'src/material_animated_icons/animated_icons_private.dart';

// Animated icons data files.
part 'src/material_animated_icons/data/menu_arrow.g.dart';
