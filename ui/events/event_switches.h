// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_EVENTS_SWITCHES_H_
#define UI_EVENTS_EVENTS_SWITCHES_H_

#include "base/compiler_specific.h"
#include "ui/events/events_base_export.h"

namespace switches {

EVENTS_BASE_EXPORT extern const char kEnableScrollPrediction[];
EVENTS_BASE_EXPORT extern const char kTouchEvents[];
EVENTS_BASE_EXPORT extern const char kTouchEventsAuto[];
EVENTS_BASE_EXPORT extern const char kTouchEventsEnabled[];
EVENTS_BASE_EXPORT extern const char kTouchEventsDisabled[];
EVENTS_BASE_EXPORT extern const char kCompensateForUnstablePinchZoom[];

#if defined(OS_LINUX)
EVENTS_BASE_EXPORT extern const char kTouchDevices[];
#endif

#if defined(USE_XI2_MT) || defined(USE_OZONE)
EVENTS_BASE_EXPORT extern const char kTouchCalibration[];
#endif

}  // namespace switches

#endif  // UI_EVENTS_EVENTS_SWITCHES_H_
