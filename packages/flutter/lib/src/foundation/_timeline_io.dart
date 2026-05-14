// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

/// Returns the current timestamp in microseconds from a monotonically
/// increasing clock.
///
/// This is the Dart VM implementation.
double get performanceTimestamp => Timeline.now.toDouble();
