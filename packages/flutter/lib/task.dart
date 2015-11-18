// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The Flutter Task library.
///
/// This library provides means to schedule tasks at given priorities.
/// The library will make sure that tasks are only run when appropriate.
/// For example, an idle-task will not run when an animation is running.
library task;

export 'src/scheduler/scheduler.dart';
