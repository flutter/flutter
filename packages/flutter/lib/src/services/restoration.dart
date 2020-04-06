// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';

/// I am just a test placeholder.
void foo() {
  SchedulerBinding.instance.scheduleTask(() => null, Priority.animation);
}
