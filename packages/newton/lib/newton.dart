// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Simple one-dimensional physics simulations, such as springs, friction, and
/// gravity, for use in user interface animations.
/// 
/// To use, import `package:newton/newton.dart`.
library newton;

export 'src/clamped_simulation.dart';
export 'src/friction_simulation.dart';
export 'src/gravity_simulation.dart';
export 'src/scroll_simulation.dart';
export 'src/simulation_group.dart';
export 'src/simulation.dart';
export 'src/spring_simulation.dart';
export 'src/tolerance.dart';
export 'src/utils.dart';
