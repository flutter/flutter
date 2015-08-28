// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Modeled after Android's ViewConfiguration:
// https://github.com/android/platform_frameworks_base/blob/master/core/java/android/view/ViewConfiguration.java

const Duration kLongPressTimeout = const Duration(milliseconds: 500);
const Duration kTapTimeout = const Duration(milliseconds: 100);
const Duration kJumpTapTimeout = const Duration(milliseconds: 500);
const Duration kDoubleTapTimeout = const Duration(milliseconds: 300);
const Duration kDoubleTapMinTime = const Duration(milliseconds: 40);
const Duration kHoverTapTimeout = const Duration(milliseconds: 150);
const Duration kZoomControlsTimeout = const Duration(milliseconds: 3000);
const double kHoverTapSlop = 20.0;  // Logical pixels
const double kEdgeSlop = 12.0;  // Logical pixels
const double kTouchSlop = 8.0;  // Logical pixels
const double kDoubleTapTouchSlop = kTouchSlop;  // Logical pixels
const double kPagingTouchSlop = kTouchSlop * 2.0;  // Logical pixels
const double kDoubleTapSlop = 100.0;  // Logical pixels
const double kWindowTouchSlop = 16.0;  // Logical pixels
const double kMinFlingVelocity = 50.0;  // TODO(abarth): Which units is this in?
const double kMaxFlingVelocity = 8000.0;  // TODO(abarth): Which units is this in?
