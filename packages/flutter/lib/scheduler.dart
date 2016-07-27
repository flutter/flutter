// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The Flutter Scheduler library.
///
/// To use, import `package:flutter/scheduler.dart`.
///
/// This library is responsible for scheduler frame callbacks, and tasks at
/// given priorities.
///
/// The library makes sure that tasks are only run when appropriate.
/// For example, an idle-task is only executed when no animation is running.
library scheduler;

export 'src/scheduler/binding.dart';
export 'src/scheduler/debug.dart';
export 'src/scheduler/priority.dart';
export 'src/scheduler/ticker.dart';
